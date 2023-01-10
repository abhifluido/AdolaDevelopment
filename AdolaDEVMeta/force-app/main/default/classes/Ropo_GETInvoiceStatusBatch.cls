/*
    ***********************************************************************
    Name        : Ropo_GETInvoiceStatusBatch
    Author      : Ashish Kumar Singh, Fluido AB
    CreatedDate : December 27, 2022
    Description : Batch to get invoice status from Ropo
    ***********************************************************************
*/
Public Class Ropo_GETInvoiceStatusBatch implements Database.Batchable<SObject>,Database.AllowsCallouts,Database.Stateful, Schedulable {
    public static String invDate = '2022-12-20';
    //public static String invDate = String.valueOf(Date.Today());
    public static map<string, Ropo_GETInvoiceStatusHandler.cls_status> statusMap = Ropo_GETInvoiceStatusHandler.doHttpGetCall(invDate, UTIL_Constants.CALLING_FROM_BATCH);
    
    //Collect the batches of records or objects to be passed to execute
    public Database.QueryLocator start(Database.BatchableContext bc) {
        set<String> inDocsSet = statusMap.KeySet();
        String query = 'Select id,DocumentNumber From Invoice Where DocumentNumber IN:inDocsSet';
        return Database.getQueryLocator(query);
    }
    //Process each batch of records
    public void execute(Database.BatchableContext bc, List<Invoice> scope) {
        map<string, Ropo_GETInvoiceStatusHandler.cls_status> invStatusMap = new map<string, Ropo_GETInvoiceStatusHandler.cls_status>();
        for(Invoice inv : scope){
            if(statusMap.containsKey(inv.DocumentNumber)){
                invStatusMap.put(inv.DocumentNumber,statusMap.get(inv.DocumentNumber));
            }
            system.debug('=====invbatch===='+inv);
            Ropo_GETInvoiceStatusHandler.updateInvoiceStatus(invStatusMap);
        }
        
    }
    //Execute any post-processing operations
    public void finish(Database.BatchableContext bc) {}
    
    public void execute(SchedulableContext SC) {
        Ropo_GETInvoiceStatusBatch scheduleBatch = new Ropo_GETInvoiceStatusBatch(); 
    }
}