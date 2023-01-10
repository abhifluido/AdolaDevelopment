/**
 * Created by bartubazna on 27.12.2022.
 */

import {api, LightningElement, wire} from 'lwc';
import {getRecord, updateRecord} from "lightning/uiRecordApi";
import CASE_ID from '@salesforce/schema/Case.Id'
import ORDER__c from '@salesforce/schema/Case.Order__c'
import STATUS from '@salesforce/schema/Case.Status'
import ORDER_ID from '@salesforce/schema/Order.Id'
import DEPOSIT_FLAG from '@salesforce/schema/Order.Requires_Deposit__c'
import {CloseActionScreenEvent} from "lightning/actions";
import {refreshApex} from "@salesforce/apex";
import {showErrorToast, showSuccessToast} from 'c/kiwi_utils';

const FIELDS = [ORDER__c, STATUS]
const ORDER_FIELDS = [DEPOSIT_FLAG]

export default class KiwiCloseDepositCase extends LightningElement {
    @api recordId;
    isRemoveFlag = true;
    isLoadingVal = true;
    caseData;
    orderId;
    orderData;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: FIELDS
    })
    wiredRecord({error, data}) {
        if(data) {
            this.caseData = data;
            this.orderId = data.fields.Order__c.value;
        }
        if(error) {
            this.handleError(error);
        }
        this.isLoadingVal = false;
    }

    @wire(getRecord, {
        recordId: '$orderId',
        fields: ORDER_FIELDS
    })
    wiredOrder({error, data}) {
        if(data) {
            this.orderData = data;
        }
        if(error) {
            this.handleError(error);
        }
        this.isLoadingVal = false;
    }

    get isLoading() {
        return this.isLoadingVal;
    }

    async updateRecords() {
        this.isLoadingVal = true;
        const caseFields = {};
        caseFields[STATUS.fieldApiName] = 'Closed';
        caseFields[CASE_ID.fieldApiName] = this.recordId;
        const caseRecord = { fields: caseFields };

        const updatedCase = await updateRecord(caseRecord)
            .then((res) => {
                return true;
            })
            .catch(error => {
                this.handleError(error);
                return false;
            });
        if (!updatedCase) {
            this.handleError('Failed to update case/order')
            return;
        }
        const orderFields = {};
        orderFields[DEPOSIT_FLAG.fieldApiName] = !this.isRemoveFlag;
        orderFields[ORDER_ID.fieldApiName] = this.orderId;

        const orderRecord = { fields: orderFields };
        if (!this.isRemoveFlag) {
            showSuccessToast('Case has been closed');
            this.dispatchEvent(new CloseActionScreenEvent());
            await refreshApex(this.caseData);
            this.isLoadingVal = false;
            return;
        } else {
            await updateRecord(orderRecord)
                .then((res) => {
                    showSuccessToast('Case & Order have been updated');
                    this.dispatchEvent(new CloseActionScreenEvent());
                    refreshApex(this.caseData);
                    this.isLoadingVal = false;
                })
                .catch(error => {
                    this.handleError(error);
                });
        }
    }

    handleCheckbox = (event) => {
        this.isRemoveFlag = event.detail.checked;
    }

    handleError(err) {
        showErrorToast('Could not update order/case.');
        this.isLoadingVal = false;
        console.error(err);
    }
}