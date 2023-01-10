/**
 * Created by bartubazna on 25.11.2022.
 */

import {LightningElement, api, wire} from 'lwc';
import {getRecord} from 'lightning/uiRecordApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import PersonContactId from '@salesforce/schema/Account.PersonContactId';
import FullName from '@salesforce/schema/Account.Name';
import {getCheckmarkIcon, getErrorIcon, getSpeechbubbleIcon, showErrorToast} from 'c/kiwi_utils'
import StandardPriceBookId from '@salesforce/label/c.StandardPricebook';
import PaymentMethodId from '@salesforce/label/c.DefaultPaymentMethod';
import TaxTreatmentId from '@salesforce/label/c.TaxTreatmentId';
import createOrderWithBuyNow from '@salesforce/apex/KiwiOrderController.createOrderWithBuyNow';
import getSecurityDepositQueue from '@salesforce/apex/KiwiSupportController.getSecurityDepositQueue';
import createCase from '@salesforce/apex/KiwiSupportController.createCase';
import CASE_OBJECT from '@salesforce/schema/Case';
import getSecurityDepositProduct from '@salesforce/apex/KiwiOrderController.getSecurityDepositProduct';
import createDraftOrder from '@salesforce/apex/KiwiOrderController.createDraftOrder';

export default class KiwiCreateOrderAfterAuth extends LightningElement {
    @api accountId;
    contactId;
    email;
    phone;
    addons = [];
    subscription;
    creditClass;
    isLSSet = false;
    percentage = 0;
    isCreateOrderFailed = false;
    isOrderCreated = false;
    isAddressConnected = false;
    redirectUrl;
    orderId;
    securityDepositOrderId;
    accountName;
    groupId;
    salesRepUserId;
    salesDirection;

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    wiredCaseObjectInfo({ error, data }) {
        if (error) {
            this.handleError('Errcode: GET_OBJECTINFO_FAILED')
        } else if (data) {
            this.caseObjectInfo = data;
        }
    }

    get recordTypeId() {
        if (this.caseObjectInfo == null) return;
        const rtis = this.caseObjectInfo.recordTypeInfos;
        return Object.keys(rtis).find(rti => rtis[rti].name === 'Security Deposit');
    }

    @wire(getRecord, { recordId: '$accountId', fields: [PersonContactId, FullName] })
    wiredAccountRecord({ error, data }) {
        if (error) {
            this.handleError(error)
        } else if (data) {
            this.contactId = data.fields.PersonContactId.value;
            this.accountName = data.fields.Name.value;
        }
        if (this.contactId) {
            this.createOrder();
        }
    }

    get checkMarkIcon() {
        return getCheckmarkIcon();
    }

    get errorIcon() {
        return getErrorIcon();
    }

    get speechBubbleIcon() {
        return getSpeechbubbleIcon();
    }

    get isInProgress() {
        return !this.isOrderCreated && !this.isCreateOrderFailed;
    }

    get isBadCreditScore() {
        return this.isOrderCreated && this.creditClass >= 1;
    }

    renderedCallback() {
        this.getQueueId();
        this.getLocalStorageItems();
    }

    handleNavigate() {
        window.location.assign(this.redirectUrl);
    }

    async createOrder() {
        this.percentage = 50;
        if (
            this.accountId == null ||
            this.subscription == null ||
            this.contactId == null
        ) {
            return this.handleError('Missing account or subscription');
        }
        if (this.creditClass != null && this.creditClass === 4) {
            this.percentage = 100;
            this.isOrderCreated = true;
            this.createSecurityDepositCase();
            return;
        }
        let res;
        let req = this.createOrderBody();
        if (this.creditClass != null && this.creditClass < 1 && this.isAddressConnected) {
            createOrderWithBuyNow({
                kiwiOrderRequestMap: req.order,
                kiwiOrderItemRequestList: req.orderItems,
                paymentMethodId: PaymentMethodId
            }).then((res) => {
                this.percentage = 100;
                if (res && res.success) {
                    this.isOrderCreated = true;
                    this.redirectUrl = res.message.url;
                } else {
                    this.handleError(res.message.message);
                }

            }).catch((e) => {
                this.handleError(e);
            })
        } else {
            createDraftOrder({
                kiwiOrderRequestMap: req.order,
                kiwiOrderItemRequestList: req.orderItems,
                salesRepId: this.salesRepUserId
            }).then((res) => {
                this.percentage = 100;
                if (res && res.success) {
                    this.isOrderCreated = true;
                    this.redirectUrl = res.message.url;
                    this.orderId = res.message.orderId;
                } else {
                    this.handleError(res.message.message);
                }

            }).catch((e) => {
                this.handleError(e);
            });
            await this.createSecurityDepositOrder();
        }
    }

    async createSecurityDepositOrder() {
        if (this.creditClass !== 2 && this.creditClass !== 3) return;
        const securityDepositProduct = await getSecurityDepositProduct({creditClass: this.creditClass}).then((res) => {
            if (res.success && res.message.productInfo) {
                return res.message.productInfo;
            } else {
                this.handleError('Security deposit product could not be found');
            }
        }).catch((e) => {
            this.handleError(e);
        })

        let req = {
            order: {
                accountId: this.accountId,
                billToContactId: this.contactId,
                pricebook2Id: StandardPriceBookId,
                requiresDeposit: this.creditClass != null && this.creditClass >= 1,
                inboundOutbound: this.salesDirection,
                isDepositOrder: true
            },
            orderItems: [
                JSON.stringify({
                    pricebookEntryId: securityDepositProduct.Id,
                    product2Id: securityDepositProduct.Product2Id,
                    taxTreatmentId: TaxTreatmentId
                })
            ]
        }

        createDraftOrder({
            kiwiOrderRequestMap: req.order,
            kiwiOrderItemRequestList: req.orderItems,
            salesRepId: this.salesRepUserId
        }).then((res) => {
            if (res && res.success) {
                this.percentage = 100;
                this.redirectUrl = res.message.url;
                this.securityDepositOrderId = res.message.orderId;
                this.createSecurityDepositCase();
            } else {
                this.handleError(res.message.message);
            }

        }).catch((e) => {
            this.handleError(e);
        })
    }

    createOrderBody() {
        let requestBody = {
            order: {
                accountId: this.accountId,
                billToContactId: this.contactId,
                pricebook2Id: StandardPriceBookId,
                requiresDeposit: this.creditClass != null && this.creditClass >= 1,
                inboundOutbound: this.salesDirection,
                isDepositOrder: false
            },
            orderItems: [
                JSON.stringify({
                    discountPercentage: 20, // TODO: remove hardcoded discount
                    pricebookEntryId: this.subscription.Id,
                    product2Id: this.subscription.Product2Id,
                    taxTreatmentId: TaxTreatmentId
                })
            ]
        }
        this.addons.forEach((addon) => {
            const orderItem = this.createOrderItemObj(addon);
            if (addon.addons != null && addon.addons.length > 0) {
                addon.addons.forEach((item) => {
                    requestBody.orderItems.push(this.createOrderItemObj(item));
                })
            }
            requestBody.orderItems.push(orderItem);
        })
        return requestBody;
    }

    createOrderItemObj(addon) {
        let orderItem = {
            discountPercentage: 20, // TODO: remove hardcoded discount
            pricebookEntryId: addon.Id,
            product2Id: addon.Product2Id,
            taxTreatmentId: TaxTreatmentId
        }
        return JSON.stringify(orderItem);
    }

    getLocalStorageItems() {
        if (this.isLSSet) return;
        this.isLSSet = true;
        const lsInformationString = localStorage.getItem('valoo_purchase_flow');
        if (lsInformationString == null || Object.keys(JSON.parse(lsInformationString)).length === 0) return;
        const lsInformation = JSON.parse(lsInformationString);
        this.subscription = lsInformation.subscription;
        this.isAddressConnected = lsInformation.isAddressConnected;
        this.salesRepUserId = lsInformation.salesRepUserId;
        this.salesDirection = lsInformation.salesDirection;
        let details = lsInformation.details;
        if (details != null) {
            this.email = details.email;
            this.phone = details.phone;
            this.creditClass = details.creditClass;
        }
        let lsAddons = lsInformation.addons;
        if (lsAddons != null && Object.keys(lsAddons).length > 0) {
            let addonKeys = Object.keys(lsAddons);
            addonKeys.forEach((key) => {
                this.addons.push(lsAddons[key]);
            })
        }
    }

    createSecurityDepositCase() {
        if (!this.isBadCreditScore) return;
        const caseObj = {
            ContactId: this.contactId,
            AccountId: this.accountId,
            RecordTypeId: this.recordTypeId,
            OwnerId: this.groupId,
            Order__c: this.orderId,
            Security_Deposit_Order__c: this.securityDepositOrderId
        }
        if (this.creditClass > 1 && this.creditClass !== 4) {
            caseObj.Subject = `Security deposit required for: ${this.accountName} (CREDIT CLASS: ${this.creditClass})`;
        }
        if (this.creditClass === 4) {
            caseObj.Subject = `Order rejected for: ${this.accountName} (CREDIT CLASS: ${this.creditClass})`;
        }
        if (this.creditClass === 1) {
            caseObj.Subject = `Investigation required: ${this.accountName} (CREDIT CLASS: ${this.creditClass})`
        }
        createCase({
            caseObj
        }).then((res) => {
            console.log(res);
        }).catch((e) => {
            this.handleError(e);
        })
    }

    getQueueId() {
        if (this.groupId) return;
        getSecurityDepositQueue({}).then((res) => {
            if (res && res.success && res.message && res.message.groupId) {
                this.groupId = res.message.groupId;
            } else {
                this.handleError(res.message.message);
            }
        }).catch((e) => {
           this.handleError(e)
        });
    }

    getFormattedDate(dateObj) {
        let year = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(dateObj);
        let month = new Intl.DateTimeFormat('en', { month: '2-digit' }).format(dateObj);
        let day = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(dateObj);
        return `${year}-${month}-${day}`;
    }

    handleError(err) {
        this.redirectUrl = 'https://www.valoo.fi/info/';
        showErrorToast('Jokin meni pieleen, emme voineet luoda tilaustasi.');
        this.isCreateOrderFailed = true;
        console.error(err);
        this.percentage = 100;
    }

}