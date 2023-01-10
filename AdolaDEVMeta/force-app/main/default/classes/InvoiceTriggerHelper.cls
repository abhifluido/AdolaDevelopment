/*
    ***********************************************************************
    Name        : InvoiceTriggerHelper
    Author      : Ashish Kumar Singh, Fluido AB
    CreatedDate : December 01, 2022
    Description : Helper class for InvoiceTrigger which have various functions/methods for different functionalities
    ***********************************************************************
*/
public class InvoiceTriggerHelper {
    
    /*
        Description : Sending invoice data to Ropo System
        Author      : Ashish Kumar Singh, Fluido AB
        Param       : list of new records, map of new records
        returntype  : N/A
    */
    public void sendInvoice(list<Invoice> newInvoiceList, Map<id,Invoice> newInvoiceMap, Map<id,Invoice> oldInvoiceMap){
        set<String> invoiceIds = new set<String>();
        for(Invoice inv: newInvoiceList){
            if(inv.SendInvoice__c && !oldInvoiceMap.get(inv.id).SendInvoice__c){
                invoiceIds.add(inv.id);
            }
        }
        if(!invoiceIds.isEmpty()){
                Ropo_SendInvoices.sendInvFutrue(invoiceIds);
        } 
    }
}