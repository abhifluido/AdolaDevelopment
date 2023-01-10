import { LightningElement, wire } from 'lwc';
import getMyOrderItems from '@salesforce/apex/KiwiController.getMyOrderItems';
import getMyOrders from '@salesforce/apex/KiwiController.getMyOrders';

export default class Kiwi_orderItems extends LightningElement {
  @wire(getMyOrderItems)
  orderItemsWire;

  @wire(getMyOrders)
  ordersWire;

  get address() {
    if (Array.isArray(this.ordersWire.data) && this.ordersWire.data.length) {
      const shippingAddress = this.ordersWire.data[0];
      return `${shippingAddress.ShippingStreet}, ${shippingAddress.ShippingPostalCode}, ${shippingAddress.ShippingCity}`;
    }
  }

  handleCancel(e) {
    console.log('TODO: Cancel order ', JSON.stringify(e.detail.Id))
  }

  get mainProducts() {
    return this.orderItemsWire.data?.filter(
      item => item.Product2.Family === 'Subscription'
    );
  }

  get secondaryProducts() {
    return this.orderItemsWire.data?.filter(
      item => item.Product2.Family !== 'Subscription'
    )
  }
}