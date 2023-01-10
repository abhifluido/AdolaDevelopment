/**
 * Created by bartubazna on 5.12.2022.
 */

@IsTest
private class TestKiwiOnboardingController {

    @TestSetup
    static void testSetup() {
        UserRole userRole = new UserRole();
        userRole.Name = 'Test Role Onboarding';
        userRole.DeveloperName = 'Test_Role_Onboarding';
        insert userRole;
        TestKiwiCommonMethods.createTestUser('Adola Power User', userRole.Id, 'onbtest');
    }
    @IsTest
    static void testCreateAccountAndContact() {
        KiwiOnboardingController controller = new KiwiOnboardingController();
        User testUser = [SELECT FIELDS(STANDARD) FROM User WHERE Email = 'testuser@testorg.com' LIMIT 1];
        CreatePersonData.PersonParameters personParameters = TestKiwiCommonMethods.createParameters(testUser.FirstName, testUser.LastName, testUser.Email, testUser.Phone);
        Contact contact = controller.createAccountAndContact(personParameters);
        Account createdAccount = [SELECT Id, Name, OwnerId FROM Account WHERE Id IN (:contact.AccountId) LIMIT 1];
        Contact createdContact = [SELECT Id, FirstName, LastName, Name, AccountId, Email FROM Contact WHERE AccountId = :createdAccount.Id LIMIT 1];
        System.assertEquals(contact.Id, createdContact.Id);
        System.assertNotEquals(null, createdAccount);
        System.assertEquals(createdAccount.Id, createdContact.AccountId);
    }

    @IsTest
    static void testCreatePortalContactAndAccount() {
        User portalOwner = [SELECT FIELDS(STANDARD) FROM User WHERE Email = 'testuser@testorg.com' LIMIT 1];
        Map<String, Object> res;
        System.runAs(portalOwner) {
            res = KiwiOnboardingController.createPortalContactAndAccount('Test', 'Test', 'portaluser@testorg.com', '01234', 'Test street 1', '00001', 'Testcity', 0, 'test-ssn', true, true, '{"city": "Testcity2", "postalCode": "000001", "street": "Teststreet 2"}');
        }

        System.assertEquals(true, res.get('success'));
        Map<String, Object> message = (Map<String, Object>)res.get('message');
        System.assertNotEquals(null, message.get('contact'));
        Contact contactObj = (Contact) message.get('contact');
        System.assertEquals('portaluser@testorg.com', contactObj.Email);
    }

    @IsTest
    static void testConvertLeadToPersonAccount() {
        Lead leadObj = new Lead();
        leadObj.FirstName = 'Test';
        leadObj.LastName = 'Test';
        leadObj.Email = 'portalUser@testorg.com';
        User portalOwner = [SELECT FIELDS(STANDARD) FROM User WHERE Email = 'testuser@testorg.com' LIMIT 1];
        Map<String, Object> res;
        System.runAs(portalOwner) {
            res = KiwiOnboardingController.createPortalContactAndAccount('Test', 'Test', 'portalUser@testorg.com', '01234', 'Test street 1', '00001', 'Testcity', 0, 'test-ssn', true, true, '{"city": "Testcity2", "postalCode": "000001", "street": "Teststreet 2"}');
        }
        insert leadObj;
        Map<String, Object> message = (Map<String, Object>)res.get('message');
        Contact contactObj = (Contact) message.get('contact');
        Map<String, Object> res2 = KiwiOnboardingController.convertLeadToPersonAccount(contactObj, leadObj.Id);
        Map<String, Object> message2 = (Map<String, Object>) res2.get('message');
        System.assertEquals(true, message2.get('leadConvertResult'));
    }

    @IsTest
    static void testCreatePortalUser() {
        Test.startTest();
        Account createdAccount;
        Contact createdContact;
        User portalOwner = [SELECT FIELDS(STANDARD) FROM User WHERE Email = 'testuser@testorg.com' LIMIT 1];
        KiwiOnboardingController controller = new KiwiOnboardingController();
        CreatePersonData.PersonParameters personParameters = TestKiwiCommonMethods.createParameters('Test', 'Test', 'portalUser@testorg.com', '0123');
        Map<String, Object> res;
        System.runAs(portalOwner) {
            Contact contact = controller.createAccountAndContact(personParameters);
            createdAccount = [SELECT Id, Name, OwnerId FROM Account WHERE Id IN (:contact.AccountId) LIMIT 1];
            createdContact = [SELECT Id, FirstName, LastName, Name, AccountId, Email FROM Contact WHERE AccountId = :createdAccount.Id LIMIT 1];
            res = KiwiOnboardingController.createPortalUser(createdContact, 'portalUser@testOrg.com');
        }
        Test.stopTest();
        Map<String, Object> message = (Map<String, Object>)res.get('message');
        User testUser = [SELECT FIELDS(STANDARD) FROM User WHERE AccountId = :createdAccount.Id LIMIT 1];
        NetworkMember networkMember = [SELECT FIELDS(STANDARD), Network.Name, Member.AccountId FROM NetworkMember WHERE Network.Name = 'OmaValoo' AND Member.AccountId = :testUser.AccountId LIMIT 1];
        System.assertEquals(testUser.Id, networkMember.MemberId);
        System.assertEquals(true, res.get('success'));
        System.assertEquals('testUrl', message.get('redirectUrl'));
        System.assertEquals(true, testUser.IsPortalEnabled);
    }
}