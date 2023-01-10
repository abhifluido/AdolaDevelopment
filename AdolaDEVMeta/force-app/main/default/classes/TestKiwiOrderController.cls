/**
 * Created by bartubazna on 3.1.2023.
 */

@IsTest
private class TestKiwiOrderController {
    @TestSetup
    static void testSetup() {
        Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Datetime initialTime = Datetime.now().addMinutes(-30);
        Account account = new Account();
        account.LastName = 'TestKiwiOrderController';
        account.SSN__c = 'test';
        account.RecordTypeId = personAccountRecordTypeId;
        account.PersonEmail = 'test@testorg.com';
        account.Credit_Class__c = 3;
        account.Credit_Class_Updated_At__c = initialTime;
        insert account;
        Schema.Location newLocation = new Schema.Location();
        newLocation.Name = 'TestKiwiOrderController';
        insert newLocation;
        Address__c address = new Address__c();
        address.Name = 'TestKiwiOrderController';
        address.Address__Street__s = 'Test street 1';
        address.Address__City__s = 'Helsinki';
        address.Address__PostalCode__s = '00001';
        address.Address__CountryCode__s = 'FI';
        address.Location__c = newLocation.Id;
        insert address;

        Contact contact = [SELECT Id, AccountId FROM Contact WHERE LastName = 'TestKiwiOrderController' LIMIT 1];
        User user = TestKiwiCommonMethods.createTestUser('System Administrator', null, 'ordtest');
        System.runAs(user) {
            List<PermissionSet> permissionSets = [SELECT Id, Name FROM PermissionSet WHERE Name IN ('CommerceUser', 'Kiwi', 'SDocs_Administrator')];
            List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
            User portalUser = TestKiwiCommonMethods.createPortalUser(contact.Id, 'TESTKIWI');
            for (PermissionSet permissionSet : permissionSets) {
                PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = portalUser.Id, PermissionSetId = permissionSet.Id);
                permissionSetAssignments.add(psa);
            }
            insert permissionSetAssignments;
        }
        insertPSMs();
        ProductSellingModel psmTD = [SELECT Id, SellingModelType FROM ProductSellingModel WHERE Name LIKE 'TestKiwiOrderController%' AND SellingModelType = 'TermDefined' LIMIT 1];
        ProductSellingModel psmEG = [SELECT Id, SellingModelType FROM ProductSellingModel WHERE Name LIKE 'TestKiwiOrderController%' AND SellingModelType = 'Evergreen' LIMIT 1];
        ProductSellingModel psmOT = [SELECT Id, SellingModelType FROM ProductSellingModel WHERE Name LIKE 'TestKiwiOrderController%' AND SellingModelType = 'Onetime' LIMIT 1];
        insertProduct2s(2, psmTD);
        insertProduct2s(2, psmEG);
        insertProduct2s(2, psmOT);

        List<Product2> product2s = [SELECT FIELDS(STANDARD) FROM Product2 WHERE Name = 'TestKiwiOrderController Product'];
        System.debug(product2s);
        insertPricebookEntries(product2s);
        insertSecurityDepositProducts(psmOT);
        List<Id> product2Ids = new List<Id>();
        for (Product2 product2 : product2s) {
            product2Ids.add(product2.Id);
        }
        List<PricebookEntry> pbes = [SELECT FIELDS(STANDARD), ProductSellingModel.SellingModelType FROM PricebookEntry WHERE Product2Id IN :product2Ids];
        System.debug(pbes);
    }
    @IsTest
    static void testConvertMapToKiwiOrderRequest() {
        Contact contact = [SELECT Id, AccountId FROM Contact WHERE LastName = 'TestKiwiOrderController' LIMIT 1];
        Map<String, Object> kiwiOrderRequestMap = new Map<String, Object>{
                'inboundOutbound' => 'Inbound',
                'requiresDeposit' => false,
                'pricebook2Id' => Test.getStandardPricebookId(),
                'billToContactId' => contact.Id,
                'accountId' => contact.AccountId,
                'isDepositOrder' => false
        };

        KiwiOrderController.KiwiOrderRequest kiwiOrderRequest = KiwiOrderController.convertMapToKiwiOrderRequest(kiwiOrderRequestMap);
        System.assertEquals(false, kiwiOrderRequest.isDepositOrder);
        System.assertEquals('Inbound', kiwiOrderRequest.inboundOutbound);
        System.assertEquals(Test.getStandardPricebookId(), kiwiOrderRequest.pricebook2Id);
    }

    @IsTest
    static void testConvertMapToKiwiOrderItemRequest() {
        Map<String, Object> kiwiOrderItemRequestMap = new Map<String, Object>{
                'taxTreatmentId' => '012000000000000AAA',
                'product2Id' => '012000000000000AAB',
                'pricebookEntryId' => '012000000000000AAC',
                'discountPercentage' => 10
        };

        KiwiOrderController.KiwiOrderItemRequest kiwiOrderItemRequest = KiwiOrderController.convertMapToKiwiOrderItemRequest(kiwiOrderItemRequestMap);
        System.assertEquals(10, kiwiOrderItemRequest.discountPercentage);
        System.assertEquals('012000000000000AAB', kiwiOrderItemRequest.product2Id);
        System.assertEquals('012000000000000AAC', kiwiOrderItemRequest.pricebookEntryId);
    }

    @IsTest
    static void testCreateOrderObject() {
        Contact contact = [SELECT Id, AccountId FROM Contact WHERE LastName = 'TestKiwiOrderController' LIMIT 1];
        Map<String, Object> kiwiOrderRequestMap = new Map<String, Object>{
                'inboundOutbound' => 'Inbound',
                'requiresDeposit' => false,
                'pricebook2Id' => Test.getStandardPricebookId(),
                'billToContactId' => contact.Id,
                'accountId' => contact.AccountId,
                'isDepositOrder' => false
        };

        KiwiOrderController.KiwiOrderRequest kiwiOrderRequest = KiwiOrderController.convertMapToKiwiOrderRequest(kiwiOrderRequestMap);
        Order order = KiwiOrderController.createOrderObject(kiwiOrderRequest);
        System.assertEquals(contact.AccountId, order.AccountId);
        System.assertEquals('Inbound', order.Inbound_Outbound__c);
        System.assertEquals(false, order.Deposit_Order__c);
    }

    @IsTest
    static void testCreateOrderItemObject() {
        List<PricebookEntry> pricebookEntries = [SELECT Id, Product2Id, ProductSellingModelId, ProductSellingModel.Name, ProductSellingModel.SellingModelType, Product2.Name, UnitPrice FROM PricebookEntry WHERE Product2.Name = 'TestKiwiOrderController Product'];
        for (PricebookEntry pbe : pricebookEntries) {
            Map<String, Object> kiwiOrderItemRequestMap = new Map<String, Object>{
                    'taxTreatmentId' => '012000000000000AAA',
                    'product2Id' => pbe.Product2Id,
                    'pricebookEntryId' => pbe.Id,
                    'discountPercentage' => 10
            };
            KiwiOrderController.KiwiOrderItemRequest kiwiOrderItemRequest = KiwiOrderController.convertMapToKiwiOrderItemRequest(kiwiOrderItemRequestMap);
            OrderItem orderItem = KiwiOrderController.createOrderItemObject(pbe, kiwiOrderItemRequest);
            System.assertEquals(pbe.UnitPrice, orderItem.UnitPrice);
            System.assertEquals(orderItem.UnitPrice * 0.9, orderItem.NetUnitPrice);
        }
    }

    @IsTest
    private static void testCreateOrderItems() {
        List<PricebookEntry> pricebookEntries = [SELECT Id, Product2Id, ProductSellingModelId, ProductSellingModel.Name, ProductSellingModel.SellingModelType, Product2.Name, UnitPrice FROM PricebookEntry WHERE Product2.Name = 'TestKiwiOrderController Product'];
        List<String> orderItemRequests = new List<String>();
        for (PricebookEntry pbe : pricebookEntries) {
            Map<String, Object> kiwiOrderItemRequestMap = new Map<String, Object>{
                    'taxTreatmentId' => '012000000000000AAA',
                    'product2Id' => pbe.Product2Id,
                    'pricebookEntryId' => pbe.Id,
                    'discountPercentage' => 10
            };

            orderItemRequests.add(JSON.serialize(kiwiOrderItemRequestMap));
        }

        List<OrderItem> orderItems = KiwiOrderController.createOrderItems(orderItemRequests);
        System.debug(orderItems);
        System.assertEquals(6, orderItems.size());
    }

    @IsTest
    private static void testGetSecurityDepositProduct() {
        Test.startTest();
        Map<String, Object> res1 = KiwiOrderController.getSecurityDepositProduct(2);
        Map<String, Object> message1 = (Map<String, Object>) res1.get('message');
        Map<String, Object> res2 = KiwiOrderController.getSecurityDepositProduct(3);
        Map<String, Object> message2 = (Map<String, Object>) res2.get('message');
        Test.stopTest();
        System.assertEquals(true, res1.get('success'));
        PricebookEntry pbe1 = (PricebookEntry) message1.get('productInfo');
        PricebookEntry pbe2 = (PricebookEntry) message2.get('productInfo');
        System.assertEquals('Deposit 200', pbe1.Product2.Name);
        System.assertEquals(200, pbe1.UnitPrice);
        System.assertEquals('Deposit 400', pbe2.Product2.Name);
        System.assertEquals(400, pbe2.UnitPrice);
    }

    @IsTest
    private static void testCreateDraftOrder() {
        List<PricebookEntry> pricebookEntries = [SELECT Id, Product2Id, ProductSellingModelId, ProductSellingModel.Name, ProductSellingModel.SellingModelType, Product2.Name, UnitPrice FROM PricebookEntry WHERE Product2.Name = 'TestKiwiOrderController Product'];
        Contact contact = [SELECT Id, AccountId FROM Contact WHERE LastName = 'TestKiwiOrderController' LIMIT 1];
        Map<String, Object> kiwiOrderRequestMap = new Map<String, Object>{
                'inboundOutbound' => 'Inbound',
                'requiresDeposit' => false,
                'pricebook2Id' => Test.getStandardPricebookId(),
                'billToContactId' => contact.Id,
                'accountId' => contact.AccountId,
                'isDepositOrder' => false
        };
        List<String> orderItemRequests = new List<String>();
        for (PricebookEntry pbe : pricebookEntries) {
            Map<String, Object> kiwiOrderItemRequestMap = new Map<String, Object>{
                    'taxTreatmentId' => null,
                    'product2Id' => pbe.Product2Id,
                    'pricebookEntryId' => pbe.Id,
                    'discountPercentage' => 10
            };

            orderItemRequests.add(JSON.serialize(kiwiOrderItemRequestMap));
        }

        KiwiOrderController.KiwiOrderRequest kiwiOrderRequest = KiwiOrderController.convertMapToKiwiOrderRequest(kiwiOrderRequestMap);
        User user = [SELECT FIELDS(STANDARD) FROM User WHERE alias = 'TESTKIWI' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            Map<String, Object> res = KiwiOrderController.createDraftOrder(kiwiOrderRequestMap, orderItemRequests, null);
            Test.stopTest();
            System.assertEquals(true, res.get('success'));
        }
    }

    private static List<PricebookEntry> insertPricebookEntries(List<Product2> p2s) {
        List<Id> product2Ids = new List<Id>();
        for (Product2 product2 : p2s) {
            product2Ids.add(product2.Id);
        }
        List<ProductSellingModelOption> productSellingModelOptions = [SELECT FIELDS(STANDARD) FROM ProductSellingModelOption WHERE Product2Id IN :product2Ids];
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        for (Product2 p2 : p2s) {
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

    private static List<PricebookEntry> insertSecurityDepositProducts(ProductSellingModel psm) {
        Product2 deposit200 = new Product2();
        deposit200.IsActive = true;
        deposit200.Name = 'Deposit 200';
        Product2 deposit400 = new Product2();
        deposit400.IsActive = true;
        deposit400.Name = 'Deposit 400';
        List<Product2> product2s = new List<Product2>{deposit200, deposit400};
        insert product2s;
        List<Id> product2Ids = new List<Id>();
        List<ProductSellingModelOption> psmos = new List<ProductSellingModelOption>();
        for (Product2 p2: product2s) {
            product2Ids.add(p2.Id);
            ProductSellingModelOption psmo = new ProductSellingModelOption();
            psmo.Product2Id = p2.Id;
            psmo.ProductSellingModelId = psm.Id;
            psmos.add(psmo);
        }
        insert psmos;
        System.debug('###########################################');
        System.debug(psmos);
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        for (Product2 p2 : product2s) {
            Id psmId;
            for (ProductSellingModelOption psmo : psmos) {
                if (psmo.Product2Id == p2.Id) psmId = psmo.ProductSellingModelId;
            }
            PricebookEntry pbe = new PricebookEntry();
            pbe.UnitPrice = p2.Name == 'Deposit 200' ? 200 : 400;
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
            p2.Name = 'TestKiwiOrderController Product';
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
        psm1.Name = 'TestKiwiOrderController Subscription';
        psm1.PricingTerm = 1;
        psm1.Status = 'Active';
        psm1.PricingTermUnit = 'Months';
        psms.add(psm1);
        ProductSellingModel psm2 = new ProductSellingModel();
        psm2.SellingModelType = 'TermDefined';
        psm2.Name = 'TestKiwiOrderController TermDefined';
        psm2.PricingTerm = 1;
        psm2.Status = 'Active';
        psm2.PricingTermUnit = 'Months';
        psms.add(psm2);
        ProductSellingModel psm3 = new ProductSellingModel();
        psm3.SellingModelType = 'OneTime';
        psm3.Name = 'TestKiwiOrderController Onetime';
        psm3.Status = 'Active';
        psms.add(psm3);
        insert psms;
        return psms;
    }
}