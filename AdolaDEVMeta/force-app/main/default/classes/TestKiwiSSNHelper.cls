/**
 * Created by bartubazna on 29.12.2022.
 */

@IsTest
private class TestKiwiSSNHelper {
    private User powerUser {get; set;}
    private User marketingUser {get; set;}
    private User portalUser {get; set;}

    public TestKiwiSSNHelper() {
        List<User> users = [SELECT FIELDS(STANDARD), Profile.Name FROM User WHERE Alias = 'ssntest1'];
        for (User user : users) {
            if (user.Profile.Name == 'Adola Power User') this.powerUser = user;
            if (user.Profile.Name == 'Adola Marketing User') this.marketingUser = user;
            if (user.Profile.Name == 'Kiwi Portal User') this.portalUser = user;
        }
    }
    @TestSetup
    static void testSetup() {
        UserRole userRole = new UserRole();
        userRole.Name = 'Test Role SSN';
        userRole.DeveloperName = 'Test_Role_SSN';
        insert userRole;

        User testUser1 = TestKiwiCommonMethods.createTestUser('Adola Power User', userRole.Id, 'ssntest1');
        User testUser2 = TestKiwiCommonMethods.createTestUser('Adola Marketing User', null, 'ssntest1');
        System.runAs(testUser1) {
            List<Id> ids = CreatePersonData.personDetailsInsert(TestKiwiCommonMethods.createParameters('Test', 'Test', 'portalUser@testorg.com', '01234'));
            System.debug(ids);
            for (Id id : ids) {
                if (id == null) continue;
                SObjectType sObjectT = id.getSobjectType();
                if (sObjectT == Account.SObjectType) {
                    Account account = [SELECT PersonContactId FROM Account WHERE Id = :id LIMIT 1];
                    TestKiwiCommonMethods.createPortalUser(account.PersonContactId, 'ssntest1');
                }
            }
        }
    }
    @IsTest
    static void testIsUserAllowed() {
        TestKiwiSSNHelper testKiwiSSNHelper = new TestKiwiSSNHelper();
        User powerUser = testKiwiSSNHelper.powerUser;
        User marketingUser = testKiwiSSNHelper.marketingUser;
        User portalUser = testKiwiSSNHelper.portalUser;
        System.runAs(powerUser) {
            Boolean isUserAllowed = KiwiSSNHelper.isUserAllowed(new Account());
            System.assertEquals(true, isUserAllowed);
        }
        System.runAs(marketingUser) {
            Boolean isUserAllowed = KiwiSSNHelper.isUserAllowed(new Account());
            System.assertEquals(false, isUserAllowed);
        }
        System.runAs(portalUser) {
            Boolean isUserAllowed = KiwiSSNHelper.isUserAllowed(new Account());
            System.assertEquals(false, isUserAllowed);
        }
    }

    @IsTest
    static void testDecryptSSN() {
        TestKiwiSSNHelper testKiwiSSNHelper = new TestKiwiSSNHelper();
        Account account = [SELECT SSN__c, PersonEmail FROM Account WHERE PersonEmail = 'portalUser@testorg.com' LIMIT 1];
        User powerUser = testKiwiSSNHelper.powerUser;
        User marketingUser = testKiwiSSNHelper.marketingUser;
        User portalUser = testKiwiSSNHelper.portalUser;
        System.runAs(powerUser) {
            String ssn = KiwiSSNHelper.decryptSSN(account.Id);
            System.assertEquals('010101-0101', ssn);
        }
        System.runAs(marketingUser) {
            String ssn = KiwiSSNHelper.decryptSSN(account.Id);
            System.assertEquals(null, ssn);
        }
        System.runAs(portalUser) {
            String ssn = KiwiSSNHelper.decryptSSN(account.Id);
            System.assertEquals(null, ssn);
        }
    }
}