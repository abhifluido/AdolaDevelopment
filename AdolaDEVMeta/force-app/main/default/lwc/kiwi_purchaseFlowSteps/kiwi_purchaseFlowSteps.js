import { LightningElement, api } from 'lwc';

export default class Kiwi_purchaseFlowSteps extends LightningElement {
  @api currentStep = 1;

  steps = [{
    title: 'Liittymä',
    number: 1,
  }, {
    title: 'Lisäpalvelut',
    number: 2,
  }, {
    title: 'Yhteenveto',
    number: 3,
  },]
}