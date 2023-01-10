/**
 * Created by bartubazna on 13.12.2022.
 */

import {LightningElement} from 'lwc';
import portalURL from '@salesforce/label/c.Portal_URL'
import {NavigationMixin} from "lightning/navigation";

export default class KiwiSalesRepAddressSearch extends NavigationMixin(LightningElement) {

    handleNavigate(e) {
        window.open(`${portalURL}internal-availability-search`, '_blank')
    }
}