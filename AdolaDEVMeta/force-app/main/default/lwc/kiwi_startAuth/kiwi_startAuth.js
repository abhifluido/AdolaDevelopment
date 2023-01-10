/**
 * Created by bartubazna on 1.11.2022.
 */

import {LightningElement} from 'lwc';
import startUserSession from '@salesforce/apex/KiwiSignicatController.startUserSession';
import {showErrorToast} from "c/kiwi_utils";

export default class KiwiStartAuth extends LightningElement {

    startAuthSession() {
        startUserSession({}).then((res) => {
            console.log(res);
            if (res != null && res.success) {
                console.log(res);
                this.navigateToSignicat(res.message);
            } else {
                showErrorToast('Something went wrong while initiating authentication session.');
            }
        }).catch((e) => {
            console.error(e);
        })
    }

    navigateToSignicat(url) {
        window.location.assign(url);
    }

}