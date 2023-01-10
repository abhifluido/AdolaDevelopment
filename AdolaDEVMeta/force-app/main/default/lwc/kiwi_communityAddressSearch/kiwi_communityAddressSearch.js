/**
 * Created by bartubazna on 14.12.2022.
 */

import {LightningElement, wire} from 'lwc';
import portalURL from '@salesforce/label/c.Portal_URL'
import {getPicklistValues} from "lightning/uiObjectInfoApi";
import INBOUND_OUTBOUND_FIELD from '@salesforce/schema/Order.Inbound_Outbound__c';

export default class KiwiCommunityAddressSearch extends LightningElement {
    address;
    picklistVals = [];
    salesDirection;

    handleChange(e) {
        this.address = JSON.parse(JSON.stringify(e.detail));
    }

    handleDirectionChange(e) {
        this.salesDirection = e.detail.value;
    }

    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: INBOUND_OUTBOUND_FIELD })
    wiredPicklistVals({error, data}) {
        if (data) {
            this.picklistVals = data.values.map((obj) => {
                return obj;
            })
        } else if (error) {
            console.log(error);
        }
    };

    buildURL() {
        const street = encodeURIComponent(this.address.street);
        const city = encodeURIComponent(this.address.city);
        const postcode = encodeURIComponent(this.address.postalCode);
        return `${portalURL}tilaus-ennakko?address=${street}&postinro=${postcode}&city=${city}&salesDirection=${this.salesDirection}`
    }

    handleNavigate(e) {
        localStorage.setItem('valoo_purchase_flow', '');
        window.open(this.buildURL(), '_blank');
    }
}