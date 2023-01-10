/**
 * Created by bartubazna on 2.1.2023.
 */

@IsTest
public class TestKiwiCommonMethods {
    public static String getRandString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr;
    }

    public static User createTestUser(String profileName, Id userRoleId, String alias)
    {
        List<Profile> testProfiles = [SELECT FIELDS(STANDARD) FROM Profile WHERE Name = :profileName LIMIT 1];
        if(testProfiles.size()!=1)
            return null;
        String testUsername = System.now().format('yyyyMMddhhmmssSSS') + '@testorg.com';
        User testUser = new User(Alias = alias, Email='testuser@testorg.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = testProfiles[0].Id, TimeZoneSidKey='America/Los_Angeles', UserName=testUsername, UserRoleId=userRoleId);
        try {
            insert testUser;
        } catch (Exception e) {
            return null;
        }
        return testUser;
    }

    public static User createPortalUser(Id contactId, String alias)
    {
        List<Profile> testProfiles = [SELECT FIELDS(STANDARD) FROM Profile WHERE Name = 'Kiwi Portal User' LIMIT 1];
        if(testProfiles.size()!=1)
            return null;
        String testUsername = System.now().format('yyyyMMddhhmmssSSS') + '@testorg.com';
        User testUser = new User(Alias = alias, Email='testuser@testorg.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = testProfiles[0].Id, TimeZoneSidKey='America/Los_Angeles', UserName=testUsername, ContactId = contactId);
        try {
            insert testUser;
        } catch (Exception e) {
            return null;
        }
        return testUser;
    }

    public static CreatePersonData.PersonParameters createParameters(String firstName, String lastName, String email, String phone) {
        CreatePersonData.PersonParameters personParameters = new CreatePersonData.PersonParameters();
        personParameters.firstName = firstName;
        personParameters.lastName = lastName;
        personParameters.emailid = email;
        personParameters.Phone = phone;
        personParameters.CreditScore = 0;
        personParameters.CreditUpdatedAt = Datetime.now();
        personParameters.Street = 'Test street 1';
        personParameters.PostalCode = '00001';
        personParameters.City = 'Helsinki';
        personParameters.State = '';
        personParameters.Country = 'Finland';
        personParameters.MarketingCheck = false; // TODO: Remove hard-coding
        personParameters.SMSPermission = false; // TODO: Remove hard-coding
        personParameters.SSN = '010101-0101';
        return personParameters;
    }
}