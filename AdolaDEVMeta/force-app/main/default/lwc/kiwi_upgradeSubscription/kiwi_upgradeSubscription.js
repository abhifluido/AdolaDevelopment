import { LightningElement, api, wire } from 'lwc';
import getUpgradePriceBookEntry from '@salesforce/apex/KiwiController.getUpgradePriceBookEntry';

export default class Kiwi_upgradeSubscription extends LightningElement {
  @api title = 'Vaihda nopeampaan nettiin'
  /**
   * How to get next suggested product?
   * Fetch product with the bigger price compared to the current price?
   */
  @wire(getUpgradePriceBookEntry)
  upgrade;

  handleSelect(e) {
    console.log('TODO: Upgrade subscription to ', JSON.stringify(e.detail.Id));
  }
}