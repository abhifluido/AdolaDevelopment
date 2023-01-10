/**
 * Created by bartubazna on 16.11.2022.
 */

@IsTest
private class TestKiwiSignicatController {
    public class SignicatAuthenticateMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            System.assertEquals('callout:SignicatTestNC/oauth/connect/token', req.getEndpoint());
            System.assertEquals('POST', req.getMethod());
            HttpResponse res = new HttpResponse();
            String mockToken = TestKiwiCommonMethods.getRandString(255*6);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token":"'+mockToken+'", "expires_in": 3600}');
            res.setStatusCode(200);
            return res;
        }
    }

    public class SignicatCreateSessionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            System.assertEquals('callout:SignicatTestNC/identification/v2/sessions/', req.getEndpoint());
            System.assertEquals('POST', req.getMethod());
            HttpResponse res = new HttpResponse();

            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"url":"https://example.com"}');
            res.setStatusCode(201);
            return res;
        }
    }

    public class SignicatGetSessionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            System.assertEquals('callout:SignicatTestNC/identification/v2/sessions/test', req.getEndpoint());
            System.assertEquals('GET', req.getMethod());
            req.setHeader('Accept','application/json');
            HttpResponse res = new HttpResponse();

            res.setHeader('Content-Type', 'application/json; charset=utf-8');
            res.setBody('some_encrypted_data');
            res.setStatusCode(200);
            return res;
        }
    }

    public class KiwiDecryptorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            System.assertEquals('callout:KiwiDecryptorNC/api/decrypt', req.getEndpoint());
            System.assertEquals('POST', req.getMethod());
            HttpResponse res = new HttpResponse();

            res.setHeader('Content-Type', 'application/json');
            Blob AESKey = Blob.valueOf([SELECT AES_Key__c FROM SignicatConfig__c].AES_Key__c);
            Blob IV = Blob.valueOf(TestKiwiCommonMethods.getRandString(16));
            Blob encryptedData = Crypto.encrypt('AES256', AESKey, IV, Blob.valueOf('{"identity": {"firstName": "Test", "lastName": "Lastname"}, "status": "success"}'));
            String hexData = EncodingUtil.convertToHex(encryptedData);
            String hexIv = EncodingUtil.convertToHex(IV);
            res.setBody('{"data":"'+hexData+'", "iv": "'+hexIv+'"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    static void testAuthenticateSignicatAndGetAccessToken() {
        Test.setMock(HttpCalloutMock.class, new SignicatAuthenticateMock());
        Test.startTest();
        KiwiSignicatController controller = new KiwiSignicatController();
        controller.authenticateSignicatAndGetAccessToken();
        controller.saveAccessToken();
        Test.stopTest();
    }

    @IsTest
    static void testInitSignicatWithValidToken() {
        Test.setMock(HttpCalloutMock.class, new SignicatCreateSessionMock());
        Integer i = 1;
        SignicatConfig__c signicatConfig = new SignicatConfig__c();
        while(i<7) {
            signicatConfig.put('Access_Token_'+i+'__c', TestKiwiCommonMethods.getRandString(255));
            i++;
        }
        signicatConfig.Expires_At__c = Datetime.now().addMinutes(60);
        insert signicatConfig;
        Test.startTest();
        KiwiSignicatController controller = new KiwiSignicatController();
        controller.initSignicat('POST', '/identification/v2/sessions/');
        System.assertEquals(true, controller.isTokenValid());
        System.assertNotEquals(true, controller.updateAccessToken);
        System.assertNotEquals(null, controller.signicatConfig.Expires_At__c);
        Test.stopTest();
    }

    @IsTest
    static void testInitSignicatWithoutValidToken() {
        Test.setMock(HttpCalloutMock.class, new SignicatAuthenticateMock());
        Test.startTest();
        KiwiSignicatController controller = new KiwiSignicatController();
        controller.initSignicat('POST', '/identification/v2/sessions/');
        controller.saveAccessToken();
        System.assertNotEquals(null, controller.accessToken);
        System.assertNotEquals(null, controller.signicatConfig);
        System.assertEquals(true, controller.updateAccessToken);
        Test.stopTest();
    }

    @IsTest
    static void testUpdateAuthToken() {
        Test.setMock(HttpCalloutMock.class, new SignicatAuthenticateMock());
        insertAuthToken(false);
        Test.startTest();
        KiwiSignicatController controller = new KiwiSignicatController();
        HttpRequest res = controller.initSignicat('POST', '/identification/v2/sessions/');
        controller.saveAccessToken();
        System.assertNotEquals(null, controller.accessToken);
        System.assertNotEquals(null, controller.signicatConfig);
        System.assertEquals(true, controller.updateAccessToken);
        Test.stopTest();
    }

    @IsTest
    static void testCreateAuthSession() {
        Test.setMock(HttpCalloutMock.class, new SignicatCreateSessionMock());
        insertAuthToken(true);
        Test.startTest();
        KiwiSignicatController controller = new KiwiSignicatController();
        String res = KiwiSignicatController.createAuthSession(controller);
        System.assertEquals(null, controller.accessToken);
        System.assertNotEquals(true, controller.updateAccessToken);
        System.assertNotEquals(null, controller.signicatConfig);
        System.assertEquals('https://example.com', res);
        Test.stopTest();
    }

    @IsTest
    static void testGetEncryptedSessionData() {
        Test.setMock(HttpCalloutMock.class, new SignicatGetSessionMock());
        insertAuthToken(true);
        Test.startTest();
        KiwiSignicatController controller = new KiwiSignicatController();
        String res = KiwiSignicatController.getEncryptedSessionData(controller, 'test');
        System.assertEquals(null, controller.accessToken);
        System.assertNotEquals(true, controller.updateAccessToken);
        System.assertNotEquals(null, controller.signicatConfig);
        System.assertEquals('some_encrypted_data', res);
        Test.stopTest();
    }

    @IsTest
    static void testGetAESEncryptedData() {
        Test.setMock(HttpCalloutMock.class, new KiwiDecryptorMock());
        insertAuthToken(true);
        Test.startTest();
        String encrypted = KiwiSignicatController.getAESEncryptedData('randomstring');
        KiwiSignicatController controller = new KiwiSignicatController();
        Map<String, Object> res = controller.decryptWithPrivateKey(encrypted);
        System.assertEquals('Test', res.get('firstName'));
        System.assertEquals('Lastname', res.get('lastName'));
        Test.stopTest();
    }

    private static void insertAuthToken(Boolean isValid) {
        Integer i = 1;
        SignicatConfig__c signicatConfig = new SignicatConfig__c();
        while(i<7) {
            signicatConfig.put('Access_Token_'+i+'__c', TestKiwiCommonMethods.getRandString(255));
            i++;
        }
        signicatConfig.Expires_At__c = Datetime.now().addMinutes(isValid? 60 : -60);
        signicatConfig.AES_Key__c = TestKiwiCommonMethods.getRandString(32);
        insert signicatConfig;
    }

}