/**
 * Created by bartubazna on 30.12.2022.
 */

@IsTest
private class TestKiwiSupportController {
    @IsTest
    static void testGetSecurityDepositQueue() {
        Map<String, Object> res = KiwiSupportController.getSecurityDepositQueue();
        Map<String, Object> message = (Map<String, Object>) res.get('message');
        System.assertEquals(true, res.get('success'));
        System.assertNotEquals(null, message.get('groupId'));
    }

    @IsTest
    static void testCreateCase() {
        Case caseObj = new Case(Subject = 'Test');
        Map<String, Object> res = KiwiSupportController.createCase(caseObj);
        Map<String, Object> message = (Map<String, Object>) res.get('message');
        System.assertEquals(true, res.get('success'));
        System.assertNotEquals(null, message.get('caseId'));
        Case caseObj2 = new Case(OwnerId='012000000000000AAA');
        Map<String, Object> res2 = KiwiSupportController.createCase(caseObj2);
        Map<String, Object> message2 = (Map<String, Object>) res2.get('message');
        System.assertEquals(false, res2.get('success'));
        System.assertEquals(null, message2.get('caseId'));
    }

    @IsTest
    static void testSendEmailWithLink() {
        Test.startTest();
        Map<String, Object> res = KiwiSupportController.sendEmailWithLink('https://valoo.fi', 'test@example.com');
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertEquals(true, res.get('success'));
        System.assertEquals(1, emailInvocations);
    }

    @IsTest
    static void testSendEmailWithLinkFail() {
        Test.startTest();
        Map<String, Object> res = KiwiSupportController.sendEmailWithLink('https://valoo.fi', 'test');
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();
        System.debug(res);
        System.assertEquals(false, res.get('success'));
        System.assertEquals(0, emailInvocations);
    }
}