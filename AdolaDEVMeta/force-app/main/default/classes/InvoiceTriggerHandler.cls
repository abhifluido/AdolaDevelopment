/*
    ***********************************************************************
    Name        : InvoiceTriggerHandler
    Author      : Ashish Kumar Singh, Fluido AB
    CreatedDate : December 01, 2022
    Description : Handler class for InvoiceTrigger to call various helper class methods
    ***********************************************************************
*/
public class InvoiceTriggerHandler {
    
    //Helper initialization
    InvoiceTriggerHelper helper = new InvoiceTriggerHelper();
    public void onBeforeInsert(list<Invoice> newInvoiceList, Map<id,Invoice> newAddressMap){
        
    }
    public void onBeforeUpdate(list<Invoice> newInvoiceList, list<Invoice> oldInvoiceList,Map<id,Invoice> newInvoiceMap,Map<id,Invoice> oldInvoiceMap){
        
    }
    public void onAfterInsert(list<Invoice> newInvoiceList,Map<id,Invoice> newInvoiceMap){
        
    }
    public void onAfterUpdate(list<Invoice> newInvoiceList, list<Invoice> oldInvoiceList,Map<id,Invoice> newInvoiceMap,Map<id,Invoice> oldInvoiceMap){
        if(!System.isFuture() && !System.isBatch() && !System.isQueueable() && !System.isScheduled()){
            helper.sendInvoice(newInvoiceList,newInvoiceMap,oldInvoiceMap);
        }
    }
}