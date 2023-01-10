import { LightningElement, api } from 'lwc';
import ASSETS from '@salesforce/resourceUrl/kiwiAssets';

const NONE = 'None';

export default class Kiwi_addonNone extends LightningElement {
  @api selected;

  get checked() {
    return this.selected === NONE;
  }

  get classes() {
    return `kiwi-no-product${this.checked ? ' active' : ''}`
  }

  get imgSrc() {
    return `${ASSETS}/images/${this.checked ? 'checked' : 'unchecked'}.svg`;
  }

  handleSelect() {
    this.dispatchEvent(new CustomEvent('select'));
  }
}