/**
 * Created by bartubazna on 29.12.2022.
 */

@IsTest
private class TestKiwiBisnodeController {
    public class BisnodeAuthMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            System.assertEquals('callout:BisnodeNC/permission/v1/ticket', req.getEndpoint());
            System.assertEquals('GET', req.getMethod());
            HttpResponse res = new HttpResponse();
            String mockToken = TestKiwiCommonMethods.getRandString(255);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"ticket":"'+mockToken+'", "expires_in": 3600}');
            res.setStatusCode(200);
            return res;
        }
    }

    public class BisnodeGetCreditRemarksMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            System.assertEquals('callout:BisnodeNC/people/info/v2/remarks?user=test&id=test&purposeCode=1', req.getEndpoint());
            System.assertEquals('GET', req.getMethod());
            req.setHeader('Accept','application/json');
            HttpResponse res = new HttpResponse();

            res.setHeader('Content-Type', 'application/json; charset=utf-8');
            res.setBody('{"creditClass": 4, "remarks": [{"remarkId": 1, "remarkSource": "Test", "amount": 1250}]}');
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    static void testAuthenticateBisnodeAndGetTicket() {
        Test.setMock(HttpCalloutMock.class, new BisnodeAuthMock());
        Test.startTest();
        KiwiBisnodeController controller = new KiwiBisnodeController();
        controller.authenticateBisnodeAndGetTicket();
        controller.saveTicket();
        Test.stopTest();
    }

    @IsTest
    static void testInitBisnodeWithValidToken() {
        Test.setMock(HttpCalloutMock.class, new BisnodeAuthMock());
        BisnodeConfig__c bisnodeConfig = insertAuthToken(true);
        Test.startTest();
        KiwiBisnodeController controller = new KiwiBisnodeController();
        Map<String, Object> params = new Map<String, Object>();
        params.put('user', bisnodeConfig.End_Username__c);
        params.put('id', 'test');
        params.put('purposeCode', 1);
        controller.initBisnode('GET', KiwiBisnodeController.buildQueryParams('/people/info/v2/remarks', params));
        System.assertEquals(true, controller.isTokenValid());
        System.assertNotEquals(true, controller.updateTicket);
        System.assertNotEquals(null, controller.bisnodeConfig.Expires_At__c);
        System.assertEquals('test', controller.bisnodeConfig.End_Username__c);
        Test.stopTest();
    }

    @IsTest
    static void testInitBisnodeWithoutValidToken() {
        Test.setMock(HttpCalloutMock.class, new BisnodeAuthMock());
        BisnodeConfig__c bisnodeConfig = insertAuthToken(false);
        String initialTicket = bisnodeConfig.Ticket__c;
        Test.startTest();
        KiwiBisnodeController controller = new KiwiBisnodeController();
        Map<String, Object> params = new Map<String, Object>();
        params.put('user', bisnodeConfig.End_Username__c);
        params.put('id', 'test');
        params.put('purposeCode', 1);
        controller.initBisnode('GET', KiwiBisnodeController.buildQueryParams('/people/info/v2/remarks', params));
        System.assertEquals(false, controller.isTokenValid());
        System.assertEquals(true, controller.updateTicket);
        System.assertNotEquals(null, controller.bisnodeConfig.Expires_At__c);
        System.assertEquals('test', controller.bisnodeConfig.End_Username__c);
        System.assertNotEquals(initialTicket, controller.ticket);
        Test.stopTest();
    }

    @IsTest
    static void testUpdateTicket() {
        Test.setMock(HttpCalloutMock.class, new BisnodeAuthMock());
        insertAuthToken(false);
        Test.startTest();
        KiwiBisnodeController controller = new KiwiBisnodeController();
        Map<String, Object> params = new Map<String, Object>();
        params.put('user', 'test');
        params.put('id', 'test');
        params.put('purposeCode', 1);
        controller.initBisnode('GET', KiwiBisnodeController.buildQueryParams('/people/info/v2/remarks', params));
        controller.saveTicket();
        System.assertNotEquals(null, controller.ticket);
        System.assertNotEquals(null, controller.bisnodeConfig);
        System.assertEquals(true, controller.updateTicket);
        Test.stopTest();
    }

    @IsTest
    static void testRetrieveCreditRemarksFromBisnode() {
        Test.setMock(HttpCalloutMock.class, new BisnodeGetCreditRemarksMock());
        insertAuthToken(true);
        Test.startTest();
        KiwiBisnodeController controller = new KiwiBisnodeController();
        String res = controller.retrieveCreditRemarksFromBisnode('test');
        Integer creditClass = KiwiBisnodeController.getCreditClass(res);
        List<Map<String, Object>> creditRemarks =  KiwiBisnodeController.getCreditRemarksList(res);

        System.assertEquals(4, creditClass);
        System.assert(creditRemarks.size() > 0);
        System.assertEquals(1250, creditRemarks[0].get('amount'));
        Test.stopTest();
    }

    @IsTest
    static void testUpdateUserCreditClass() {
        Account account = insertAccount();
        Datetime initialTime = Datetime.now().addMinutes(-30);
        Test.startTest();
        KiwiBisnodeController.updateUserCreditClass(account, 4);
        Test.stopTest();
        Account updatedAccount = [SELECT Credit_Class_Updated_At__c, Credit_Class__c FROM Account WHERE Id = :account.Id LIMIT 1];
        System.assertEquals(4, updatedAccount.Credit_Class__c);
        System.assertNotEquals(initialTime, updatedAccount.Credit_Class_Updated_At__c);
    }

    @IsTest
    static void testGetCreditRemarks() {
        Test.setMock(HttpCalloutMock.class, new BisnodeGetCreditRemarksMock());
        insertAuthToken(true);
        Test.startTest();
        Map<String, Object> res = KiwiBisnodeController.getCreditRemarks('test');
        Test.stopTest();
        System.debug(res);
        System.assertEquals(true, res.get('success'));
        Map<String, Object> message = (Map<String, Object>)res.get('message');
        System.assertEquals(4, message.get('creditClass'));
    }

    @IsTest
    static void testGetCreditRemarksForRegisteredUser() {
        Test.setMock(HttpCalloutMock.class, new BisnodeGetCreditRemarksMock());
        insertAuthToken(true);
        Account account = insertAccount();
        Test.startTest();
        Map<String, Object> res = KiwiBisnodeController.getCreditRemarksForRegisteredUser(account.Id);
        Test.stopTest();
        System.debug(res);
        System.assertEquals(true, res.get('success'));
        Map<String, Object> message = (Map<String, Object>)res.get('message');
        List<Map<String, Object>> creditRemarks = (List<Map<String, Object>>) message.get('creditRemarks');
        System.assertEquals(4, message.get('creditClass'));
        System.assert(creditRemarks.size() > 0);
        System.assertEquals(1250, creditRemarks[0].get('amount'));
    }

    private static BisnodeConfig__c insertAuthToken(Boolean isValid) {
        BisnodeConfig__c bisnodeConfig = new BisnodeConfig__c();
        bisnodeConfig.Expires_At__c = Datetime.now().addMinutes(isValid? 60 : -60);
        bisnodeConfig.Ticket__c = TestKiwiCommonMethods.getRandString(255);
        bisnodeConfig.End_Username__c = 'test';
        insert bisnodeConfig;
        return bisnodeConfig;
    }

    private static Account insertAccount() {
        Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Datetime initialTime = Datetime.now().addMinutes(-30);
        Account account = new Account();
        account.LastName = 'Test';
        account.SSN__c = 'test';
        account.RecordTypeId = personAccountRecordTypeId;
        account.PersonEmail = 'test@testorg.com';
        account.Credit_Class__c = 3;
        account.Credit_Class_Updated_At__c = initialTime;
        insert account;
        return account;
    }
}