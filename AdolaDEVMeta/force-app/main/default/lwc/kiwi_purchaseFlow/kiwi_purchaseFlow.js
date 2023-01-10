import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import getArea from '@salesforce/apex/KiwiController.getArea';
import getAvailability from '@salesforce/apex/KiwiController.getAvailability';
import getPriceBookEntries from '@salesforce/apex/KiwiController.getPriceBookEntries';
import saveAbandonedCartLead from '@salesforce/apex/KiwiController.saveAbandonedCartLead';
import startUserSession from '@salesforce/apex/KiwiSignicatController.startUserSession';
import sendEmailWithLink from '@salesforce/apex/KiwiSupportController.sendEmailWithLink';
import userId from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { generatePurchaseFlowUrl } from 'c/kiwi_utils';
import { flatten } from 'c/lodash';

const NONE = 'None'
/**
 * The sample response from the area search endpoint
 * https://portaali.netplaza.fi/hubspot/saatavuuskysely/haeosoitteentuotteet_keycom_url.php
 * Origin: https://www.valoo.fi
 * {"valid_captcha":true,"location":"Saatavuusalue:HelsinkiX4","url":"https:\/\/valonnopea.tayskuitu.fi\/tilaus\/ennakko-0-0-1?alue=HelsinkiX4"}
 * ?alue=HelsinkiX4&kayttopaikan_postinumero=00940&kayttopaikan_katuosoite=Rintinpolku%205&kayttopaikan_postitoimipaikka=Helsinki
 * The response is missing the address information. Consider including that during the redirect.
 */
export default class Kiwi_purchaseFlow extends NavigationMixin(LightningElement) {
  @track currentStep = 1;
  @track loading = false;

  userId = userId;
  @track salesRepUserId = userId;
  @track salesDirection;

  @track state = {};
  @track form = {
    email: '',
    phone: '',
    termsAccepted: false,
  }

  get isFirstStep() {
    return this.currentStep === 1;
  }
  get isSecondStep() {
    return this.currentStep === 2;
  }
  get isThirdStep() {
    return this.currentStep === 3;
  }
  get isFourthStep() {
    return this.currentStep === 4;
  }

  get address() {
    return `${this.state.address}, ${this.state.postinro}${this.state.city ? ', ' + this.state.city : ''}`;
  }

  get hasValidArea() {
    return this.state.address && this.state.postinro && this.availability;
  }

  get disabled() {
    return Object.values(this.form).every(value => !!value);
  }

  get isAvailable() {
    return this.availability?.Status__c === 'Available';
  }

  @track availability;

  @wire(CurrentPageReference)
  getStateParams(currentPageReference) {
    this.state = currentPageReference.state;
    // First, get the selected products from the flow
    if (currentPageReference.state.order) {
      try {
        console.log(currentPageReference.state.order);
        console.log(unescape(currentPageReference.state.order));
        const parsed = JSON.parse(atob(unescape(currentPageReference.state.order).replaceAll('_', '+').replaceAll('-', '/')))
        this.selectedAddonsMap = parsed.addons;
        this.selectedSubscription = parsed.subscription;
        this.form = parsed.details;
        this.salesRepUserId = parsed.salesRepUserId;
        this.salesDirection = parsed.salesDirection;
        console.log('parsed', JSON.stringify(parsed));
        // TODO: What step to show when user comes back?
        if (this.selectedAddons.length) {
          this.currentStep = 3;
        } else {
          this.currentStep = 2;
        }
      } catch (e) {
        console.log('Error: Cannot read the unfinished order.');
        console.log(e);
      }
    } else {
      // Read session storage
      const data = localStorage.getItem('valoo_purchase_flow');
      if (data) {
        const parsed = JSON.parse(data);
        this.selectedAddonsMap = parsed.addons;
        this.selectedSubscription = parsed.subscription;
        this.form = parsed.details;
      }
    }
    // address, postnro
    const payload = currentPageReference.state;
    console.log('payload', JSON.stringify(payload));
    console.log(payload.postinro)
    console.log(payload.address)
    this.loading = true;
    getArea({
      postinro: payload.postinro,
      address: payload.address
    }).then(response => {
      console.log(response)
      console.log('Keycom Area:', JSON.stringify(response))
      this.availability = response;
    }).catch(e => {
      console.log('Error', JSON.stringify(e));
    }).finally(() => {
      this.loading = false;
    });
  }

  get disablePrev() {
    return this.currentStep < 2;
  }

  get disableNext() {
    return this.currentStep > 3;
  }

  handlePrev() {
    if (this.disablePrev) {
      return;
    }
    this.currentStep = this.currentStep - 1;
  }

  handleNext() {
    this.handleSaveSession();
    if (this.disableNext) {
      return;
    }
    this.currentStep = this.currentStep + 1;
  }

  handleStepSelect(e) {
    const step = e.detail;
    if (step) {
      this.currentStep = step;
    }
  }

  handleNavigate() {
    console.log('handle navigate')
    this[NavigationMixin.Navigate]({
      type: 'comm__namedPage',
      attributes: {
        name: 'Ei_Saatavilla__c'
      }
    });
  }

  get orderPayload() {
    return {
      addons: this.selectedAddonsMap,
      subscription: this.selectedSubscription,
      details: this.form,
      isAddressConnected: this.availability?.Status__c === 'Available',
      salesRepUserId: this.salesRepUserId,
      ...this.state,
    }
  }
  generatedLink;
  async handleGenerateLink() {
    this.loading = true;
    this.generatedLink = generatePurchaseFlowUrl(this.state, this.orderPayload);
    // TODO: Figure out server error
    try {
      const result = await sendEmailWithLink({
        link: this.generatedLink,
        email: this.form.email
      });
      console.log('emailResult', JSON.stringify(result));
    } catch (e) {
      console.log(JSON.stringify(e));
    }
    this.dispatchEvent(new ShowToastEvent({
      title: 'Success!',
      message: 'The link has been sent.',
      variant: 'success'
    }));
    this.loading = false;
  }
  async handleSaveLead(event) {
    this.handleClose();
    this.loading = true;
    this.generatedLink = generatePurchaseFlowUrl(this.state, this.orderPayload);
    try {
      const { email, emailAccepted } = event.detail;
      await saveAbandonedCartLead({
        email, emailOptOut: !emailAccepted, link: this.generatedLink
      });
      console.log('lead saved');
    } catch(e) {
      console.log(JSON.stringify(e));
    }
    this.dispatchEvent(new ShowToastEvent({
      title: 'Success!',
      message: 'Please, check your email.',
      variant: 'success'
    }));
    this.loading = false;
  }
  /**
   * Subscriptions
   * TODO: Remove mock and retrieve data from the price book.
   */
  @wire(getPriceBookEntries)
  priceBookEntries;

  @track selectedSubscription;

  get firstStepDisabled() {
    return !this.selectedSubscription;
  }

  get selectedSubscriptionRecord() {
    const record = this.priceBookEntries?.data?.find(item => item.Id === this.selectedSubscription?.Id);
    return record;
  }

  handleSubscriptionSelect(event) {
    this.selectedSubscription = event.detail;
    this.handleNext();
  }
  /**
   * Add-ons
   */
  @track selectedAddonsMap = {};
  handleSelectAddon({ detail }) {
    this.selectedAddonsMap = {...detail};
  }
  get selectedAddons() {
    return flatten(Object.values(this.selectedAddonsMap)
      .filter(value => value && value !== NONE)
      .map(item => {
        const addons = item.addons || [];
        return [item, ...addons];
      }));
  };
  get selectedAddonsTotalPrice() {
    return this.selectedAddons.reduce((acc, cur) => acc + cur?.UnitPrice || 0, 0)
  }

  /**
   * T Price Monthly
   * The subscription and all add-ons that do not have a one-time payment selling model
   */
  get totalPriceAfterDiscountMonthly() {
    return this.selectedAddons
      .filter(item => item.ProductSellingModel?.SellingModelType !== 'OneTime')
      .reduce((acc, cur) => acc + cur.UnitPrice, this.selectedSubscriptionRecord.UnitPrice);
  }

  get totalPriceMonthly() {
    return this.selectedAddons
      .filter(item => item.ProductSellingModel?.SellingModelType !== 'OneTime')
      .reduce((acc, cur) => acc + cur.UnitPrice, this.selectedSubscriptionRecord.Discounted_Price__c);
  }
  /**
   * T Price OneTime
   */
   get totalPriceOneTime() {
    return this.selectedAddons
      .filter(item => item.ProductSellingModel?.SellingModelType === 'OneTime')
      .reduce((acc, cur) => acc + cur.UnitPrice, 0);
  }
  /**
   * Signicat
   */
  startAuthSession(e) {
    e.preventDefault();
    e.stopPropagation();
    this.handleSaveSession();
    startUserSession({}).then((res) => {
        if (res != null) this.navigateToSignicat(res.message);
    }).catch((e) => {
        console.error(e);
    })
  }

  navigateToSignicat(url) {
    window.location.assign(url);
  }

  handleChangeInput(e) {
    const { name, value } = e.currentTarget;
    this.form[name] = value;
  }

  handleChangeCheckbox(e) {
    const { name, checked } = e.currentTarget;
    this.form[name] = checked;
    if (!checked && name !== "termsAccepted") delete this.form[name];
  }

  handleSaveSession() {
    const data = {
      addons: this.selectedAddonsMap,
      subscription: this.selectedSubscription,
      details: this.form,
      isAddressConnected: this.availability?.Status__c === 'Available',
      salesRepUserId: this.salesRepUserId,
      salesDirection: this.salesDirection,
      differentBillingAddress: this.differentBillingAddress,
      ...this.state,
    } 
    const dataJSON = JSON.stringify(data)
    console.log('saved data', dataJSON)
    localStorage.setItem('valoo_purchase_flow', dataJSON);
  }
  /**
   * Capture abandoned cart leads
   */
  showDocumentLeaveModal = false;

  handleClose() {
    this.showDocumentLeaveModal = false;
  }

  handleDocumentLeave() {
    // Prevent the popup if it is either logged-in user or the address was not found
    if (!userId && this.hasValidArea) {
      this.showDocumentLeaveModal = true;
    }
    document.body.removeEventListener('mouseleave', this._handleDocumentLeave);
  }
  _handleDocumentLeave;

  handleAddressChange(e) {
    this.differentBillingAddress = JSON.parse(JSON.stringify(e.detail));
  }

  connectedCallback() {
    // Save a reference to the bound function since it has a different identity
    this._handleDocumentLeave = this.handleDocumentLeave.bind(this);
    document.body.addEventListener('mouseleave', this._handleDocumentLeave);
  }
  disconnectedCallback() {
    document.body.removeEventListener('mouseleave', this._handleDocumentLeave);
  }
}