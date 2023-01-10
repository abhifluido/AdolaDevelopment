import { LightningElement, api } from 'lwc';

export default class Kiwi_constructionStatusItem extends LightningElement {
  @api step;
  @api last = false;

  get classes() {
    return `kiwi-step-container ${this.step.status}${this.last ? ' last' : ''}`
  }
}