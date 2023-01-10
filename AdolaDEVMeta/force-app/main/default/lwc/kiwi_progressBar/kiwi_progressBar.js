/**
 * Created by bartubazna on 21.11.2022.
 */

import {LightningElement, api} from 'lwc';

export default class KiwiProgressBar extends LightningElement {
    percentageVal = 0;
    progressGradientElem;
    progressBarElem;
    @api set percentage(input) {
        this.percentageVal = input;
    }

    get percentage() {
        return this.percentageVal;
    }

    renderedCallback() {
        this.progressGradientElem = this.template.querySelector(`[data-id='progress-gradient']`);
        this.progressBarElem = this.template.querySelector(`[data-id='progress-bar']`);
        const interval = setInterval(() => {
            this.adjustPercentage();
            if (this.percentage === 100) {
                clearInterval(interval);
                this.progressBarElem.style = "display: none;";
            }
        }, 1000);
    }

    adjustPercentage() {
        console.log(this.percentage);
        this.progressGradientElem.style = "width: "+this.percentage+"%";
    }

}