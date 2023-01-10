import { LightningElement, api } from 'lwc';
import ASSETS from '@salesforce/resourceUrl/kiwiAssets';

export default class Kiwi_promoBox extends LightningElement {
  @api isAvailable = false;

  get imgSrc() {
    return `${ASSETS}/images/promo.png`;
  }
}