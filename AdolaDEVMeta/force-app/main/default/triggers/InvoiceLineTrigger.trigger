//This trigger is only for test purpose, will move logic somewhere else later
trigger InvoiceLineTrigger on InvoiceLine (after insert) {
    list<InvoiceLine> invoiceLnList = new list<InvoiceLine>();
    Map<string,string> invoiceMap = new Map<string,string>();
    Map<string,string> invoiceMap2 = new Map<string,string>();
    for(InvoiceLine line : [SELECT id,InvoiceId,BillingScheduleId, BillingSchedule.ReferenceEntityId,BillingSchedule.BillingScheduleGroupId,BillingSchedule.BillingScheduleGroup.ReferenceEntityId from InvoiceLine where id IN: trigger.newMap.keyset()]){
        system.debug('===222==='+line.BillingSchedule.ReferenceEntityId);
        system.debug('===333==='+line);
        system.debug('===444==='+line.BillingSchedule.BillingScheduleGroup.ReferenceEntityId);
        invoiceMap.put(line.InvoiceId,line.BillingSchedule.ReferenceEntityId);
        invoiceMap2.put(line.InvoiceId,line.BillingSchedule.BillingScheduleGroup.ReferenceEntityId);
    }
    list<Invoice> invoiceList = new list<Invoice>();
    for(Invoice inv: [select id from Invoice where id IN: invoiceMap.KeySet()]){
        if(invoiceMap.containskey(inv.id)){
            inv.ReferenceEntityId = invoiceMap.get(inv.id);
            inv.AssetId__c = invoiceMap2.get(inv.id);
          invoiceList.add(inv);  
        }
    }
    if(invoiceList != null && invoiceList.size() > 0)
        update invoiceList;
}