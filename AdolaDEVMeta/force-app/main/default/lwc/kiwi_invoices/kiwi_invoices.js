/**
 * Created by bartubazna on 5.1.2023.
 */

import {api, LightningElement, wire} from 'lwc';
import {getRelatedListInfo, getRelatedListRecords, getRelatedListRecordsBatch} from 'lightning/uiRelatedListApi';
import {getRecord} from "lightning/uiRecordApi";
import {showErrorToast} from "c/kiwi_utils";
import ACCOBJ from "@salesforce/schema/Account";

export default class KiwiInvoices extends LightningElement {
    @api accountId = null;
    isFetched = false;
    isLoadingVal = true;
    remarks = [];
    sortedBy;
    sortedDirection;
    totalRemarks = 0;
    columns = [
        { label: 'Pvm', fieldName: 'InvoiceDate', sortable: true, hideDefaultActions: true, type:"date", typeAttributes:
                {
                    year: "numeric",
                    month: "2-digit",
                    day: "2-digit"
                }
        },
        { label: 'Lasku (PDF)', fieldName: 'DownloadLink', type: 'button', sortable: true, typeAttributes: {
                value: { fieldName: 'Id' },
                variant: 'base',
                label: { fieldName: 'Subject' },
                alternativeText: 'Lataa',
                name: 'download',
            }
        },
        { label: 'Sopimus', fieldName: 'Agreement', sortable: true, hideDefaultActions: true, },
        { label: 'Käyttöpaikka', fieldName: 'PlaceOfUse', sortable: true, hideDefaultActions: true, },
        { label: 'Tila', fieldName: 'Status', sortable: true, hideDefaultActions: true, },
        { label: 'Summa', fieldName: 'Amount', type: 'currency', sortable: true, hideDefaultActions: true, typeAttributes:
                {
                    currencyDisplayAs: 'symbol',
                    currencyCode: 'EUR'
                } },
    ];

    @wire(getRelatedListInfo, {
        parentObjectApiName: ACCOBJ.objectApiName,
        relatedListId: 'Invoices',
        recordTypeId: '012000000000000AAA'// optional
    })listInfo({ error, data }) {
        if (data) {
            console.log(JSON.parse(JSON.stringify(data)));
            this.displayColumns = data.displayColumns;
        } else if (error) {
            this.handleError(error);
        }
    }

    // @wire(getRelatedListRecords, {
    //     parentRecordId: '$accountId',
    //     relatedListId: 'Orders'
    // })wiredOrders({ error, data }) {
    //     if (error) {
    //         this.handleError(error)
    //     } else if (data) {
    //         console.log('here');
    //         console.log(JSON.parse(JSON.stringify(data)));
    //         console.log(data);
    //     }
    // }

    @wire(getRelatedListRecordsBatch, {
        parentRecordId: '$accountId',
        relatedListParameters: [
            {
                relatedListId: 'Orders',
                fields: ['Order.Id','Order.CreatedDate']
            }
        ]
    })listInfo2({ error, data }) {
        if (data) {
            console.log('here2');
            console.log(JSON.parse(JSON.stringify(data)));
            this.results = data.results;
            this.error = undefined;
        } else if (error) {
            console.log(error);
            this.error = error;
            this.results = undefined;
        }
    }

    // @wire(getRecords, { recordId: '$accountId', fields: [PersonContactId, FullName] })
    // wiredAccountRecord({ error, data }) {
    //     if (error) {
    //         this.handleError(error)
    //     } else if (data) {
    //         this.contactId = data.fields.PersonContactId.value;
    //         this.accountName = data.fields.Name.value;
    //     }
    //     if (this.contactId) {
    //         this.createOrder();
    //     }
    // }

    get isLoading() {
        return this.isLoadingVal;
    }

    renderedCallback() {
        console.log(this.accountId);
    }

    handleError(err) {
        showErrorToast('Could not fetch invoices.');
        this.isLoadingVal = false;
        console.error(err);
    }

}