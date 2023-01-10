/**
 * Created by bartubazna on 14.12.2022.
 */

import {LightningElement} from 'lwc';

export default class KiwiAddressSearch extends LightningElement {
    handleChange(e) {
        const addressObj = this.template.querySelector('lightning-input-address');
        let fixedAddress = addressObj.street;
        if (e.detail.street) {
            const streetParts = e.detail.street.split(' ');
            if (/\d/.test(streetParts[0]) && streetParts.length > 1 && streetParts[1] != '') {
                fixedAddress = "";
                const streetNumber = streetParts[0];
                for(let i=1; i<streetParts.length; i++) {
                    fixedAddress += streetParts[i] + " "
                }
                fixedAddress+= `${streetNumber}`
            }
        }
        addressObj.street = fixedAddress;
        const addressData = {
            street: addressObj.street,
            city: addressObj.city,
            postalCode: addressObj.postalCode
        }

        const selectedEvent = new CustomEvent("addresschange", {
            detail: addressData
        });
        this.dispatchEvent(selectedEvent);
    }
}