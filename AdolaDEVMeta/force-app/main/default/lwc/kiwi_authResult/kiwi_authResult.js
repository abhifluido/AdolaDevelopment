/**
 * Created by bartubazna on 2.11.2022.
 */

import {LightningElement, wire} from 'lwc';
import {CurrentPageReference, NavigationMixin} from "lightning/navigation";
import getSessionData from '@salesforce/apex/KiwiSignicatController.getSessionData';
import getCreditRemarksApex from '@salesforce/apex/KiwiBisnodeController.getCreditRemarks';
import {
    showSuccessToast,
    showErrorToast,
    showWarningToast,
    getCheckmarkIcon,
    getErrorIcon,
    getSpeechbubbleIcon
} from 'c/kiwi_utils'
import createPortalContactAndAccount from '@salesforce/apex/KiwiOnboardingController.createPortalContactAndAccount'
import createPortalUser from '@salesforce/apex/KiwiOnboardingController.createPortalUser'

export default class KiwiAuthResult extends NavigationMixin(LightningElement) {
    state;
    isIdentificationSuccess = false;
    fullName = '';
    isBisnodeCalled = false;
    isSignicatCalled = false;
    isIdentificationAborted = false;
    isIdentificationError = false;
    isUserCreated = false;
    isUserExists = false;
    isUserCreateFailed = false;
    // testEmail = this.generateTestEmail()
    percentage = 0;
    creditClass;
    email;
    phone;
    street;
    postCode;
    city;
    marketingPermission = false;
    smsPermission = false;

    @wire(CurrentPageReference)
    getStateParams(currentPageReference) {
        this.state = currentPageReference.state;
        switch (this?.state?.status) {
            case 'success': this.isIdentificationSuccess = true;
                break;
            case 'abort': this.isIdentificationAborted = true;
                break;
            case 'error': this.isIdentificationError = true;
                break;
            default: this.isIdentificationSuccess = false;
                this.isIdentificationError = true;
                break;
        }
    }

    get isProcessFinished() {
        return this.isUserCreateFailed || this.isUserCreated || this.isUserExists;
    }

    get checkMarkIcon() {
        return getCheckmarkIcon();
    }

    get errorIcon() {
        return getErrorIcon();
    }

    get speechBubble() {
        return getSpeechbubbleIcon();
    }

    renderedCallback() {
        if (this.state != null && this.state.sessionId != null && !this.isSignicatCalled) {
            this.isSignicatCalled = true;
            this.percentage = 20;
            this.getLocalStorageItems();
            getSessionData({sessionId: this.state.sessionId}).then((res) => {
                this.percentage = 40;
                if (res.message && res.message.fullName != null) {
                    this.fullName = res.message.fullName;
                    this.getCreditRemarks(res.message);
                }
                if (res.message != null && (Object.keys(res.message).length === 0)) {
                    this.handleError('Could not get decrypted information');
                }
            }).catch((e) => {
                this.handleError(e);
            })
        }
    }

    getCreditRemarks(input) {
        if (input != null != null && input.nin != null && !this.isBisnodeCalled) {
            this.isBisnodeCalled = true;
            getCreditRemarksApex({hetu: input.nin}).then((res) => {
                this.percentage = 60;
                // Check if the API call was successful and creditClass is below 4
                // If credit score is 4, don't create user account and stop process
                if (res.success && res.message != null && res.message.creditClass != null) {
                    this.creditClass = res.message.creditClass;
                    // TODO: Delete the following lines, it's for testing purposes only
                    if (input.nin == '010170-999R') {
                        this.creditClass = 2;
                    }
                    this.createAccount(input);
                } else {
                    this.handleError('Errcode: MISSING_OR_BAD_CC'); // Bad credit class
                }
                if (!res.success) {
                    this.handleError('Could not get remarks');
                }
            }).catch((e) => {
                this.handleError(e);
            })
        } else {
            this.handleError('Input for remarks was insufficient')
        }
    }

    createAccount(input) {
        createPortalContactAndAccount({
            firstName: input.firstName,
            lastName: input.lastName,
            email: this.email,
            phone: this.phone,
            street: this.street,
            postCode: this.postCode,
            city: this.city,
            creditClass: this.creditClass,
            SSN: input.nin,
            marketingPermissions: this.marketingPermission,
            smsPermissions: this.smsPermission,
            differentBillingAddress: this.differentBillingAddress
        }).then((res) => {
            this.percentage = 80;
            if (res.success && res.message != null && res.message.contact != null) {
                this.accountId = res.message.contact.AccountId;
                this.contactId = res.message.contact.Id;
                this.createUser(res.message.contact);
            } else {
                this.handleError('Contact was null');
            }
        }).catch((e) => {
            this.handleError(e);
        })
    }

    createUser(contact) {
        createPortalUser({contactObj: contact, email: this.email}).then((res) => {
            if (res?.success) {
                if (res.message?.redirectUrl != null) {
                    this.isUserCreated = true;
                    showSuccessToast('Kaikki on valmiina!');
                    this.setLocalStorageItems();
                    window.location.assign(res?.message?.redirectUrl);
                } else {
                    this.isUserExists = true;
                    showWarningToast('Tili on jo olemassa');
                }
            } else {
                this.handleError(res.message);
            }
            this.percentage = 100;
        }).catch((e) => {
            this.handleError(e);
        });
    }

    getLocalStorageItems() {
        const lsInformationString = localStorage.getItem('valoo_purchase_flow');
        if (lsInformationString == null || Object.keys(JSON.parse(lsInformationString)).length === 0) return;
        const lsInformation = JSON.parse(lsInformationString);
        let details = lsInformation.details;
        this.street = lsInformation.address;
        this.postCode = lsInformation.postinro;
        this.city = lsInformation.city;
        this.differentBillingAddress = lsInformation.differentBillingAddress ? JSON.stringify(lsInformation.differentBillingAddress) : "";
        if (details != null) {
            this.email = details.email;
            this.phone = details.phone;
            this.smsPermission = details.smsPermission;
            this.marketingPermission = details.marketingPermission;
        }
    }

    setLocalStorageItems() {
        const lsInformationString = localStorage.getItem('valoo_purchase_flow');
        if (lsInformationString == null || Object.keys(JSON.parse(lsInformationString)).length === 0) return;
        const lsInformation = JSON.parse(lsInformationString);
        lsInformation.details = {...lsInformation.details, creditClass: this.creditClass};
        localStorage.setItem('valoo_purchase_flow', JSON.stringify(lsInformation));
    }

    handleNavigate(e) {
        let pageRef;
        if (e.target.dataset.type === 'login') {
            pageRef = {
                type: 'comm__loginPage',
                attributes: {
                    actionName: 'login'
                }
            }
        } else if(e.target.dataset.type === 'back') {
            // TODO: Use address to build the url
            pageRef = {
                type: 'comm__namedPage',
                attributes: {
                    name: 'Tilaus_Ennakko__c'
                }
            }
        }
        console.log(pageRef);
        this[NavigationMixin.Navigate](pageRef);
    }

    handleError(err) {
        showErrorToast('Jokin meni pieleen, emme voineet luoda OmaValoo-tiliäsi.');
        this.isUserCreateFailed = true;
        console.error(err);
        this.percentage = 100;
    }
}