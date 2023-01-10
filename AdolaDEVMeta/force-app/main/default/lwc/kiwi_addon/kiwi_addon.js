import { LightningElement, api, wire } from 'lwc';
import ASSETS from '@salesforce/resourceUrl/kiwiAssets';
import getRelatedAddons from '@salesforce/apex/KiwiController.getRelatedAddons';

export default class Kiwi_addon extends LightningElement {
  @api item;
  @api currentCategoryItem;
  @api selected;

  showChannels = false;

  handleClose() {
    this.showChannels = false;
  }

  handleOpen(e) {
    e.stopPropagation();
    this.showChannels = true;
  }

  get productId() {
    return this.item?.Product2.Id;
  }
  
  get formItemAddons() {
    return this.currentCategoryItem?.addons || [];
  }

  handleSelectSubAddon(event) {
    const { detail } = event;
    const isFound = !!this.formItemAddons.find(item => item.Id === detail.Id);
    const addons = isFound
      ? this.formItemAddons.filter(item => item.Id !== detail.Id) || []
      : [...this.formItemAddons, detail]
    this.dispatchEvent(new CustomEvent('select', {
      detail: {
        ...this.item,
        addons
      }
    }));
  }

  // @wire(getRelatedAddons, {
  //   productId: '$productId',
  //   type: 'Mandatory'
  // }) mandatoryAddons;

  @wire(getRelatedAddons, {
    productId: '$productId',
    type: 'Add On'
  }) relatedAddons;
  /**
   * One item selected per category
   */
  get checked() {
    return this.item.Id === this.selected;
  }

  get classes() {
    return `kiwi-product-card-container${this.checked ? ' active' : ''}`
  }

  get imgSrc() {
    return `${ASSETS}/images/${this.checked ? 'checked' : 'unchecked'}.svg`;
  }

  get isOneTime() {
    return this.item?.ProductSellingModel?.SellingModelType === 'OneTime';
  }

  /**
   * TODO: Update this from hard-coded id to TV product family
   */
  get hasChannels() {
    console.log(JSON.stringify(this.item?.Product2.Product_Category__c));
    return this.item?.Product2.Product_Category__c === 'a040D0000054NxbQAE';
  }

  handleSelect() {
    if (this.checked) {
      this.dispatchEvent(new CustomEvent('select', {
        detail: null
      }));
      return;
    }
    this.dispatchEvent(new CustomEvent('select', {
      detail: {
        ...this.item,
        addons: []
      }
    }));
  }
}