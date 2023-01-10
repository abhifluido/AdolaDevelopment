/**
 * Created by bartubazna on 28.12.2022.
 */

import {api, LightningElement} from 'lwc';
import {showErrorToast} from "c/kiwi_utils";
import {CloseActionScreenEvent} from "lightning/actions";
import getRemarksApex from "@salesforce/apex/KiwiBisnodeController.getCreditRemarksForRegisteredUser";

export default class KiwiShowRemarks extends LightningElement {
    @api recordId;
    isFetched = false;
    isLoadingVal = true;
    remarks = [];
    sortedBy;
    sortedDirection;
    totalRemarks = 0;
    columns = [
        { label: 'Amount', fieldName: 'amount', type: 'currency', sortable: true, hideDefaultActions: true, typeAttributes:
                {
                    currencyDisplayAs: 'symbol',
                    currencyCode: 'EUR'
                } },
        { label: 'Remark Date', fieldName: 'remarkDate', sortable: true, hideDefaultActions: true, type:"date", typeAttributes:
                {
                    year: "numeric",
                    month: "2-digit",
                    day: "2-digit"
                }
        },
        { label: 'Remark Source', fieldName: 'remarkSource', sortable: true, hideDefaultActions: true, },
        { label: 'Remark Type', fieldName: 'remarkType', sortable: true, hideDefaultActions: true, },
        { label: 'Creditor', fieldName: 'creditor', sortable: true, hideDefaultActions: true, },
    ];

    renderedCallback() {
        if (this.recordId && !this.isFetched) {
            this.isFetched = true;
            getRemarksApex({accountId: this.recordId}).then(res => {
                this.remarks = res?.message?.creditRemarks;
                if (this.remarks != null) {
                    this.sortData('amount', 'desc');
                    this.totalRemarks = this.remarks.reduce((partialSum, remark) => partialSum + remark.amount, 0);
                    console.log(this.totalRemarks);
                }
                this.isLoadingVal = false;
            }).catch(e => {
                this.handleError(e);
            })
        }
    }

    get tableData() {
        return this.remarks;
    }

    get isLoading() {
        return this.isLoadingVal;
    }

    get isRenderRemarks() {
        return this.isFetched && this.remarks != null && this.remarks.length > 0;
    }

    doSorting(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this.sortData(this.sortedBy, this.sortedDirection);
    }

    sortData(fieldname, direction) {
        let parseData = this.remarks;
        let keyValue = (a) => {
            return a[fieldname];
        };
        let isReverse = direction === 'asc' ? 1: -1;
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((x > y) - (y > x));
        });
        console.log(parseData);
        this.remarks = [...parseData];
    }

    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleError(err) {
        showErrorToast('Could not update order/case.');
        this.isLoadingVal = false;
        console.error(err);
    }
}