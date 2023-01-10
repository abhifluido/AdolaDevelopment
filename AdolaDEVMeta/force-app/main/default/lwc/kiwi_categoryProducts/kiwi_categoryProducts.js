import { LightningElement, api, wire } from 'lwc';
import getPriceBookEntriesByCategory from '@salesforce/apex/KiwiController.getPriceBookEntriesByCategory';

const NONE = 'None';

export default class Kiwi_categoryProducts extends LightningElement {
  @api form = {};
  @api categoryId;
  // Expose selected to parent component
  @api selected;

  get currentCategoryItem() {
    return this.form[this.categoryId];
  }

  @wire(getPriceBookEntriesByCategory, {
    categoryId: '$categoryId'
  }) products;
  /**
   * Preselect the addons if exists in a form
   */
  connectedCallback() {
    console.log(JSON.stringify(this.categoryId))
    console.log(JSON.stringify(this.form))
    const addon = this.form[this.categoryId];
    this.selected = addon?.Id;
    console.log(JSON.stringify(addon));
  }

  pushState(value) {
    this.dispatchEvent(new CustomEvent('select', {
      detail: {
        key: this.categoryId,
        value,
      }
    }))
  }

  handleSelectAddon(e) {
    console.log('Save addon')
    console.log(JSON.stringify(e.detail))
    this.dispatchEvent(new CustomEvent('select', {
      detail: e.detail
    }));
  }

  handleSelect(e) {
    this.selected = e.detail?.Id;
    this.pushState(e.detail);
  }
  
  handleSelectNone() {
    this.selected = NONE;
    this.pushState(NONE);
  }
}