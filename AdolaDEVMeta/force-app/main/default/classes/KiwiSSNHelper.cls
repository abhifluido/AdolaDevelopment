/**
 * Created by bartubazna on 22.12.2022.
 */

public without sharing class KiwiSSNHelper {

    public static String decryptSSN(Id accountId) {
        Account acc = [SELECT SSN__c, PersonEmail FROM Account WHERE Id = :accountId LIMIT 1];
        if (isUserAllowed(acc)) {
            return acc.SSN__c;
        } else {
            return null;
        }

    }

    @TestVisible
    private static Boolean isUserAllowed(Account account) {
        Boolean res = false;
        List<String> profileNames = new List<String> {'System Administrator', 'Adola Finance User', 'Adola Power User', 'Adola Sales User', 'Adola Service User'};
        Profile profile = [SELECT Id, Name, PermissionsViewEncryptedData FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
        if (profile.PermissionsViewEncryptedData) res = true;
        if (profileNames.contains(profile.Name)) res = true;

        return res;
    }
}