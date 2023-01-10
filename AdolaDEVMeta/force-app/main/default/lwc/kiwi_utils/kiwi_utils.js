/**
 * Created by bartubazna on 14.11.2022.
 */

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ASSETS from '@salesforce/resourceUrl/kiwiAssets';

    function showSuccessToast(input) {
        const evt = new ShowToastEvent({
            title: 'Onnistui',
            message: input,
            variant: 'success',
        });
        dispatchEvent(evt)
    }

    function showErrorToast(input) {
        const evt = new ShowToastEvent({
            title: 'Virhe',
            message: input,
            variant: 'error',
        });
        dispatchEvent(evt)
    }

    function showWarningToast(input) {
        const evt = new ShowToastEvent({
            title: 'Varoitus',
            message: input,
            variant: 'warning',
        });
        dispatchEvent(evt)
    }

    function showInfoToast(input) {
        const evt = new ShowToastEvent({
            title: 'Info',
            message: input,
            variant: 'info',
        });
        dispatchEvent(evt)
    }

    function getCheckmarkIcon() {
        return `${ASSETS}/images/OK_White.svg`;
    }

    function getSpeechbubbleIcon() {
        return `${ASSETS}/images/speech_bubble.svg`;
    }

    function getErrorIcon() {
        return `${ASSETS}/images/error.svg`;
    }

export { showInfoToast, showWarningToast, showErrorToast, showSuccessToast, getCheckmarkIcon, getSpeechbubbleIcon, getErrorIcon }

/**
 * Generates the purchase flow URL with the order payload.
 * @param {Object} state - the required location-related query parameters
 * @param {Object} data - the order payload
 */
 export const generatePurchaseFlowUrl = (state, data) => {
  const dataJSON = JSON.stringify(data)
  const order = btoa(unescape(encodeURIComponent(dataJSON)))
  return `${generatePurchaseFlowBaseUrl(state)}&order=${escape(order.replaceAll('+', '_').replaceAll('/', '-'))}`
}

export const generatePurchaseFlowBaseUrl = state => `https://${window.location.hostname}/omavaloo/s/tilaus-ennakko?address=${state?.address}&postinro=${state?.postinro}&city=${state?.city}`