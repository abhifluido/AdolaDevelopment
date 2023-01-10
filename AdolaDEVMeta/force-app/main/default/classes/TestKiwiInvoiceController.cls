/**
 * Created by bartubazna on 9.1.2023.
 */

@IsTest
private class TestKiwiInvoiceController {

    @TestSetup
    static void testSetup() {
        Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Datetime initialTime = Datetime.now().addMinutes(-30);
        Account account = new Account();
        account.LastName = 'TestKiwiInvoiceController';
        account.SSN__c = 'test';
        account.RecordTypeId = personAccountRecordTypeId;
        account.PersonEmail = 'test@testorg.com';
        account.Credit_Class__c = 3;
        account.Credit_Class_Updated_At__c = initialTime;
        insert account;
        Contact contact = [SELECT FIELDS(STANDARD) FROM Contact WHERE AccountId = :account.Id LIMIT 1];
        Case caseObj = new Case(Subject='TestKiwiInvoiceController');
        insert caseObj;
        ContentVersion contentVersion = new ContentVersion(
                Title = 'TestKiwiInvoiceController',
                PathOnClient = 'TestKiwiInvoiceController.pdf',
                VersionData = Blob.valueOf('TestKiwiInvoiceController Content'),
                IsMajorVersion = true
        );
        insert contentVersion;

        Id cd = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
        ContentDocumentLink cdl = new ContentDocumentLink(
                LinkedEntityId = caseObj.Id,
                ContentDocumentId = cd,
                ShareType = 'V'
        );
        insert cdl;
    }

    @IsTest
    static void testGetInvoices() {
        Account account = [SELECT Id FROM Account WHERE LastName = 'TestKiwiInvoiceController' LIMIT 1];
        Map<String, Object> res = KiwiInvoiceController.getInvoices(account.Id);
        System.debug(res);
    }

    @IsTest
    static void testFindcontentVersionId() {
        List<ContentVersion> contentVersions = [SELECT FIELDS(STANDARD) FROM ContentVersion WHERE Title = 'TestKiwiInvoiceController'];
        System.debug(contentVersions);
        Id res = KiwiInvoiceController.findContentVersionId(contentVersions, contentVersions[0].ContentDocumentId);
        System.assertNotEquals(null, res);
    }

    @IsTest
    static void testFindInvoice() {
        List<Invoice> invoices = new List<Invoice>{new Invoice(Id='3tt000000000001'), new Invoice(Id='3tt000000000002')};
        Invoice res = KiwiInvoiceController.findInvoice(invoices, '3tt000000000001');
        System.assertNotEquals(null, res);
        System.assertEquals(invoices[0], res);
    }
}