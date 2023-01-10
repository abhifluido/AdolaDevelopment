import { LightningElement, api } from 'lwc';

export default class Kiwi_purchaseFlowStep extends LightningElement {
  @api step;
  @api currentStep;

  get active() {
    return this.step.number === this.currentStep;
  }

  get classes() {
    return this.active ? `kiwi-step-center kiwi--active` : `kiwi-step-center`
  }

  get first () {
    return this.step.number === 1;
  }

  get last () {
    return this.step.number === 3;
  }

  get done() {
    return this.currentStep > this.step.number;
  }

  handleClick() {
    if (this.done) {
      this.dispatchEvent(new CustomEvent('select', {
        detail: this.step.number,
        bubbles: true,
        composed: true,
      }))
    }
  }
}