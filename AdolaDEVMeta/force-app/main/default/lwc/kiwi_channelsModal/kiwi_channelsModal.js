import { LightningElement } from 'lwc';
import ASSETS from '@salesforce/resourceUrl/kiwiAssets';

export default class Kiwi_channelsModal extends LightningElement {
  channels = [
    'Yle TV1',
    'Yle TV2',
    'TLC',
    'MTV3',
    'Disney Channel',
    'Sub',
    'AVA',
    'Nelonen',
    'Jim',
    'Liv',
    'Hero',
    'AlfaTV',
  ];

  get imgSrc() {
    return `${ASSETS}/images/mtv3.png`;
  }

  handleClose() {
    this.dispatchEvent(new CustomEvent('close', {}));
  }
}