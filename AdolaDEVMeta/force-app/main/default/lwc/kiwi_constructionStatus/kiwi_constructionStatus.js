import { LightningElement, wire } from 'lwc';
import getMyOrders from '@salesforce/apex/KiwiController.getMyOrders';

export default class Kiwi_constructionStatus extends LightningElement {
  /**
   * TODO: Remove mock data and fetch status from the Salesforce
   */
  steps = [{
    name: 'Tilauksesi on vahvistettu',
    status: 'done'
  }, {
    name: 'Ennakkomyynti käynnissä',
    description: `
      Alueellasi on ennakkomyynti käynnissä. Kun alueella tulee tarpeeksi kiinnostusta, voidaan tehdä päätös rakentamisesta.

      Haluatko auttaa kiihdyttämään myyntiä alueellasi? 
      <a href="/">Tilaa tästä esite jaettavaksi</a>
    `,
    status: 'active'
  }, {
    name: 'Rakennuspäätös tehty!',
    status: 'notStarted'
  }, {
    name: 'Rakentaminen alueellasi on käynnistynyt',
    status: 'notStarted'
  }, {
    name: 'Liittymä on valmis aktivoitavaksi',
    status: 'notStarted'
  }, ]

  @wire(getMyOrders)
  ordersWire;

  get address() {
    if (Array.isArray(this.ordersWire.data) && this.ordersWire.data.length) {
      const shippingAddress = this.ordersWire.data[0];
      return `${shippingAddress.ShippingStreet}, ${shippingAddress.ShippingPostalCode}, ${shippingAddress.ShippingCity}`;
    }
  }
}