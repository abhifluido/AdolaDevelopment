import { LightningElement, api } from 'lwc';
import ASSETS from '@salesforce/resourceUrl/kiwiAssets';

export default class Kiwi_subAddon extends LightningElement {
  @api item;
  @api selected = [];

  get checked() {
    return !!this.selected?.find(item => item.Id === this.item.Id);
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

  handleSelect(e) {
    e.preventDefault();
    e.stopPropagation();
    this.dispatchEvent(new CustomEvent('select', {
      detail: this.item
    }))
  }
}