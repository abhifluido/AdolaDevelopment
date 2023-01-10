/**
 * Created by bartubazna on 16.12.2022.
 */

import {LightningElement} from 'lwc';
import convertLeadToPersonAccount from '@salesforce/apex/KiwiOnboardingController.convertLeadToPersonAccount'

export default class KiwiLeadToAccTest extends LightningElement {
    renderedCallback() {
        convertLeadToPersonAccount({
            leadId: '00Q0D0000074Bf7UAE',
            contactObj: {
                AccountId: '0010D00000nyY64QAE',
                Id: '0030D00000ZC8WyQAL'
            }
        }).then((res) => {
            console.log(res);
        }).catch((e) => {
            console.error(e);
        })
    }
}