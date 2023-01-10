import { LightningElement, api } from 'lwc';

const ROW = 'row'
const COLUMN = 'column'

export default class Kiwi_subscription extends LightningElement {
  @api subscription;
  @api selectedSubscription;
  @api variant = COLUMN;
  @api cancel = false;

  get checked() {
    return this.subscription.Id === this.selectedSubscription?.Id;
  }

  get classes() {
    return `kiwi-product-card${this.checked ? ' active' : ''}`
  }

  get isColumn() {
    return this.variant === COLUMN;
  }
  get isRow() {
    return this.variant === ROW;
  }

  get isSubscription() {
    return this.subscription?.Product2?.Family === 'Subscription';
  }
  
  get isEvergreen() {
    return this.subscription?.ProductSellingModel?.SellingModelType === 'Evergreen';
  }

  handleChange() {
    this.dispatchEvent(new CustomEvent('select', {
      detail: this.subscription
    }))
  }
}