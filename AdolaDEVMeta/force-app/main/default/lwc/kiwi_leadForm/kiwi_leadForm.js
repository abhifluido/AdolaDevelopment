import { LightningElement, api } from 'lwc';

export default class Kiwi_leadForm extends LightningElement {
  @api title = 'Jätä meille vinkki alla olevalla lomakkeella.';
  @api content = 'Näin saat tietää ensimmäisten joukossa, kun alamme suunnitella valokuituhanketta asuinalueellasi. Seuraamme aktiivisesti aluevinkkejä ja otamme ne huomioon, kun päätämme seuraavia hankealueitamme.';
  @api returnUrl = 'https://www.valoo.fi/';
  @api debugEmail;
}