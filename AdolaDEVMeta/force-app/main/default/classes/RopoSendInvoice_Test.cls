@IsTest
private class RopoSendInvoice_Test{
    
    @TestSetup
    static void testSetup(){
        Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Datetime initialTime = Datetime.now().addMinutes(-30);
        Account account = new Account();
        account.LastName = 'TestInvoiceAcc';
        account.SSN__c = 'test';
        account.RecordTypeId = personAccountRecordTypeId;
        account.PersonEmail = 'test@testorg.com';
        account.Credit_Class__c = 3;
        account.Credit_Class_Updated_At__c = initialTime;
        account.BillingStreet = 'Test street 1';
        account.BillingCity = 'Helsinki';
        account.BillingCountry = 'FINLAND';
        account.BillingPostalCode = '0001';
        account.ShippingStreet = 'Test street 1';
        account.ShippingCity = 'Helsinki';
        account.ShippingCountry = 'FINLAND';
        account.ShippingPostalCode = '0001';
        insert account;
        Schema.Location newLocation = new Schema.Location();
        newLocation.Name = 'TestInvoiceAcc';
        insert newLocation;
        Address__c address = new Address__c();
        address.Name = 'TestInvoiceAcc';
        address.Address__Street__s = 'Test street 1';
        address.Address__City__s = 'Helsinki';
        address.Address__PostalCode__s = '00001';
        address.Address__CountryCode__s = 'FI';
        address.Location__c = newLocation.Id;
        insert address;
        
        Contact contact = [SELECT Id, AccountId FROM Contact WHERE LastName = 'TestInvoiceAcc' LIMIT 1];
        
        User user = TestKiwiCommonMethods.createTestUser('System Administrator', null, 'ordtest');
        
            List<PermissionSet> permissionSets = [SELECT Id, Name FROM PermissionSet WHERE Name IN ('CommerceUser', 'Kiwi', 'SDocs_Administrator','SDocs_User','SDocs_Jobs_Guest_Users')];
            List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
        System.runAs(user) {    
            for (PermissionSet permissionSet : permissionSets) {
                PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = permissionSet.Id);
                permissionSetAssignments.add(psa);
            }
            insert permissionSetAssignments;
        }
        insertPSMs();
        ProductSellingModel psmTD = [SELECT Id, SellingModelType FROM ProductSellingModel WHERE Name LIKE 'TestInvoiceAcc%' AND SellingModelType = 'TermDefined' LIMIT 1];
        ProductSellingModel psmEG = [SELECT Id, SellingModelType FROM ProductSellingModel WHERE Name LIKE 'TestInvoiceAcc%' AND SellingModelType = 'Evergreen' LIMIT 1];
        ProductSellingModel psmOT = [SELECT Id, SellingModelType FROM ProductSellingModel WHERE Name LIKE 'TestInvoiceAcc%' AND SellingModelType = 'Onetime' LIMIT 1];
        insertProduct2s(2, psmTD);
        insertProduct2s(2, psmEG);
        insertProduct2s(2, psmOT);
        
        List<Product2> product2s = [SELECT FIELDS(STANDARD) FROM Product2 WHERE Name = 'TestInvoiceAcc Product'];
        insertPricebookEntries(product2s);
        List<Id> product2Ids = new List<Id>();
        for (Product2 product2 : product2s) {
            product2Ids.add(product2.Id);
        }
        List<PricebookEntry> pbes = [SELECT FIELDS(STANDARD), ProductSellingModel.SellingModelType FROM PricebookEntry WHERE Product2Id IN :product2Ids];
        System.debug('===pbes==='+pbes);
        
        
    }
    @IsTest
    static void test_sendInvFutrue() {
        List<Product2> product2s = [SELECT FIELDS(STANDARD) FROM Product2 WHERE Name = 'TestInvoiceAcc Product'];
        List<PricebookEntry> pricebookEntries = [SELECT Id, Product2Id, ProductSellingModelId, ProductSellingModel.Name, ProductSellingModel.SellingModelType, Product2.Name, UnitPrice FROM PricebookEntry WHERE Product2.Name = 'TestInvoiceAcc Product'];
        Contact contact = [SELECT Id, AccountId FROM Contact WHERE LastName = 'TestInvoiceAcc' LIMIT 1];
        user usr = [Select id,name,Email From User Where Email = 'testuser@testorg.com'];
        //System.runAs(usr) { 
        list<PackageLicense> pck = [SELECT Id, NameSpacePrefix FROM PackageLicense];
        SDOC__SDTemplate__c sd = new SDOC__SDTemplate__c(Name = 'SDOC', SDOC__Template_Format__c = 'PDF', SDOC__Create_File__c = true,SDOC__Base_Object__c = 'Order', SDOC__Active__c= true);
        
        insert sd;
        system.debug(sd);
        system.debug(pck);
        system.debug(pck.size());
        Order o = new Order(
          AccountId = contact.AccountId,
          Status = 'Draft',
          EffectiveDate = System.today(),
          EndDate = System.today() + 4,
          Pricebook2Id = Test.getStandardPricebookId()
        );
        insert o;
        AppUsageAssignment aua = new AppUsageAssignment(AppUsageType = 'SubscriptionManagement', RecordId = o.id);
        insert aua;
        OrderAction oa = new OrderAction(OrderId = o.id, Type = 'New Sale');
        insert oa;
        SDOC__SDJob__c  sj = new SDOC__SDJob__c(SDOC__Doclist__c = sd.id,SDOC__ObjApiName__c = 'Order',SDOC__Oid__c = o.id,SDOC__Status__c = 'Selected',SDOC__Type__c = 'Bulk Job - List View');
        insert sj;
        OrderItem oi = new OrderItem(
          PricebookEntryId = pricebookEntries[0].Id,
          Product2Id = product2s[0].Id,
          Quantity = 1,
          UnitPrice = 240,
          OrderId = o.Id
        );
        insert oi;
        OrderItemTaxLineItem oit = new OrderItemTaxLineItem(OrderItemId = oi.id,Name='Sales Tax',Amount=3.63,Type='Estimated',TaxEffectiveDate=Date.valueof('2022-01-01'));
        insert oit;
        o.Status = 'Activated';
        update o;
        SDOC__SDJob__c  sj1 = new SDOC__SDJob__c(SDOC__Doclist__c = sd.id,SDOC__ObjApiName__c = 'Order',SDOC__Oid__c = o.id,SDOC__Status__c = 'Selected',SDOC__Type__c = 'Bulk Job - List View');
        insert sj1;
        list<BillingSchedule> bs = [Select id from BillingSchedule];
        //}
    } 
    
    private static List<PricebookEntry> insertPricebookEntries(List<Product2> prd2) {
        List<Id> product2Ids = new List<Id>();
        for (Product2 product2 : prd2) {
            product2Ids.add(product2.Id);
        }
        List<ProductSellingModelOption> productSellingModelOptions = [SELECT FIELDS(STANDARD) FROM ProductSellingModelOption WHERE Product2Id IN :product2Ids];
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        for (Product2 p2 : prd2) {
            Id psmId;
            for (ProductSellingModelOption psmo : productSellingModelOptions) {
                if (psmo.Product2Id == p2.Id) psmId = psmo.ProductSellingModelId;
            }
            PricebookEntry pbe = new PricebookEntry();
            pbe.UnitPrice = 35;
            pbe.IsActive = true;
            pbe.Product2Id = p2.Id;
            pbe.Pricebook2Id = Test.getStandardPricebookId();
            pbe.ProductSellingModelId = psmId;
            pricebookEntries.add(pbe);
        }
        insert pricebookEntries;
        return pricebookEntries;
    }
    private static void insertProduct2s(Integer iteration, ProductSellingModel psm) {
        if (iteration == null) {
            iteration = 1;
        }
        Integer i = 0;
        List<ProductSellingModelOption> psmos = new List<ProductSellingModelOption>();
        while (i < iteration) {
            Product2 p2 = new Product2();
            p2.Name = 'TestInvoiceAcc Product';
            p2.IsActive = true;
            insert p2;
            ProductSellingModelOption psmo = new ProductSellingModelOption();
            psmo.Product2Id = p2.Id;
            psmo.ProductSellingModelId = psm.Id;
            psmos.add(psmo);
            i++;
        }
        insert psmos;
    }
    
    private static List<ProductSellingModel> insertPSMs() {
        List<ProductSellingModel> psms = new List<ProductSellingModel>();
        ProductSellingModel psm1 = new ProductSellingModel();
        psm1.SellingModelType = 'Evergreen';
        psm1.Name = 'TestInvoiceAcc Subscription';
        psm1.PricingTerm = 1;
        psm1.Status = 'Active';
        psm1.PricingTermUnit = 'Months';
        psms.add(psm1);
        ProductSellingModel psm2 = new ProductSellingModel();
        psm2.SellingModelType = 'TermDefined';
        psm2.Name = 'TestInvoiceAcc TermDefined';
        psm2.PricingTerm = 1;
        psm2.Status = 'Active';
        psm2.PricingTermUnit = 'Months';
        psms.add(psm2);
        ProductSellingModel psm3 = new ProductSellingModel();
        psm3.SellingModelType = 'OneTime';
        psm3.Name = 'TestInvoiceAcc Onetime';
        psm3.Status = 'Active';
        psms.add(psm3);
        insert psms;
        return psms;
    }
}