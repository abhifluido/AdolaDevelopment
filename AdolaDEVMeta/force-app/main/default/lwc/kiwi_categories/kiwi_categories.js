import { LightningElement, wire, api } from 'lwc';
import getProductCategories from '@salesforce/apex/KiwiController.getProductCategories';

export default class Kiwi_categories extends LightningElement {
  @wire(getProductCategories) categories;

  handleNext() {
    console.log(JSON.parse(JSON.stringify(this.form)))

    this.dispatchEvent(new CustomEvent('next', {
      detail: this.form
    }))
  }

  @api form = {};
  
  /**
   * TODO
   * Can select no products or one product
   * the form is disabled unless there is at least something selected per category
   * 
   * Each category should have at least some value
   */
  // get disabled() {
  //   const values = Object.values(this.form);

  //   if (values.length < this.categories?.data?.length) {
  //     return true;
  //   }
    
  //   return values.some(value => !value);
  // }
  handleSetState(e) {
    this.dispatchEvent(new CustomEvent('select', {
      detail: e.detail
    }))
  }

  handleSelect(e) {
    const { key, value } = e.detail
    const detail = {
      ...this.form,
      [key]: value
    }
    this.dispatchEvent(new CustomEvent('select', {
      detail
    }))
  }
}