@isTest(SeeAllData = true)
public class Ropo_GETInvoiceStatusController_TEST{
    
    @isTest static void  testCalloutForInvoicePDF(){
        
        list<string> InvoiceId = new list<string>();
        for(Invoice invId : [SELECT ID,DocumentNumber FROM INVOICE LIMIT 1]){
            InvoiceId.add(invId.id);
        }
        MyRopoApp__c myRopo = MyRopoApp__c.getInstance();
        Test.startTest();
        Test.setMock(HttpCalloutMock.Class, new MockHttpResponseGenerator());
        UTIL_GenerateToken.generateTokenRopo(myRopo);
        Ropo_GETInvoicePDFHandler.doGET(InvoiceId);
        //HttpResponse response = MockHttpResponseGenerator.respond();
        test.stopTest();
    }
    @isTest static void  testCalloutForInvoiceStatus(){
        
        list<string> InvoiceId = new list<string>();
        for(Invoice invId : [SELECT ID,DocumentNumber FROM INVOICE LIMIT 1]){
            InvoiceId.add(invId.id);
        }
        MyRopoApp__c myRopo = MyRopoApp__c.getInstance();
        Test.startTest();
        Test.setMock(HttpCalloutMock.Class, new MockHttpResponseGenerator());
        UTIL_GenerateToken.generateTokenRopo(myRopo);
        Ropo_GETInvoiceStatusHandler.getInvoiceStatusAction(InvoiceId);
        //HttpResponse response = MockHttpResponseGenerator.respond();
        test.stopTest();
    }
    @isTest static void  testCalloutForInvoiceStatusBatch(){
        
        list<string> InvoiceId = new list<string>();
        for(Invoice invId : [SELECT ID,DocumentNumber FROM INVOICE LIMIT 1]){
            InvoiceId.add(invId.id);
        }
        MyRopoApp__c myRopo = MyRopoApp__c.getInstance();
        Test.startTest();
        Test.setMock(HttpCalloutMock.Class, new MockHttpResponseGenerator());
        UTIL_GenerateToken.generateTokenRopo(myRopo);
        String invDate = '2022-12-20';
        Ropo_GETInvoiceStatusHandler.doHttpGetCall(invDate,'batch');
        Ropo_GETInvoiceStatusBatch uca = new Ropo_GETInvoiceStatusBatch();
        Id batchId = Database.executeBatch(uca);
        test.stopTest();
    }
}