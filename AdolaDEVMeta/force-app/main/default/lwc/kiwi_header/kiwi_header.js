import { api, LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import ASSETS from '@salesforce/resourceUrl/kiwiAssets';
import isGuest from '@salesforce/user/isGuest';

export default class Kiwi_header extends NavigationMixin(LightningElement) {
  @api hideNav = false;

  get logoSrc() {
    return `${ASSETS}/images/logo.png`;
  }

  showNav = !isGuest && !this.hideNav;

  handleNavigate(e) {
    const { name } = e.currentTarget.dataset;
    this[NavigationMixin.Navigate]({
      type: 'comm__namedPage',
      attributes: {
        name
      }
    });
  }
}