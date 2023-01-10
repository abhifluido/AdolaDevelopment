/**
 * Created by bartubazna on 14.11.2022.
 */

public without sharing class KiwiOnboardingController {

    Account createdAccount;
    Contact createdContact;
    public KiwiOnboardingController() { }

    @TestVisible
    private Contact createAccountAndContact(CreatePersonData.PersonParameters personParameters) {
        List<Id> idList = CreatePersonData.personDetailsInsert(personParameters);
        createdAccount = [SELECT Id, Name, OwnerId FROM Account WHERE Id IN :idList LIMIT 1];
        createdContact = [SELECT Id, FirstName, LastName, Name, AccountId, Email FROM Contact WHERE AccountId = :createdAccount.Id LIMIT 1];
        return createdContact;
    }

    @TestVisible
    private static String createUserAndLogin(String firstName, String lastName, String email, Id contactId, Id accountId) {
        List<User> users = [SELECT Id FROM User WHERE ContactId = :contactId];
        if (users != null && users.size() > 0) return null;
        Profile communityProfile = [SELECT Id FROM Profile WHERE UserType = 'CspLitePortal' AND Name = 'Kiwi Portal User' LIMIT 1];
        List<PermissionSet> permissionSets = [SELECT Id, Name FROM PermissionSet WHERE Name IN ('CommerceUser', 'Kiwi', 'SDocs_User')];
        String username = getUsername(email);
        String alias = getAlias(firstName, lastName);
        User userObj = new User(
                FirstName = firstName,
                LastName = lastName,
                Email = email,
                Username = username,
                ContactId = contactId,
                CommunityNickname = alias+String.valueOf(getRandNumber(10)),
                Alias = alias,
                TimeZoneSidKey = 'Europe/Helsinki',
                LocaleSidKey = 'fi_FI',
                EmailEncodingKey = 'ISO-8859-1',
                ProfileId = communityProfile.Id,
                LanguageLocaleKey = 'fi'
        );
        String pw = generatePassword();
        Id userId = Site.createPortalUser(userObj, accountId, pw, false);
        if (Test.isRunningTest()) {
            insert userObj;
            userId = userObj.Id;
        }
        List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
        for (PermissionSet permissionSet : permissionSets) {
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = permissionSet.Id, AssigneeId = userId);
            permissionSetAssignments.add(psa);
        }
        insert permissionSetAssignments;
        PageReference ref = Site.login(username, pw, Site.getPathPrefix()+'/create-order-after-auth');
        if (Test.isRunningTest()) {
            ref = new PageReference('testUrl');
        }
        return ref.getUrl();
    }

    @TestVisible
    private static String getUsername(String email) {
        String hostName = System.Url.getSalesforceBaseUrl().getHost();
        String sandboxName;
        String res = email;
        if(hostName.indexOf('--') != -1) {
            Integer startIndexOfSandboxName = hostName.indexOf('--') + 2;
            Integer endIndex = hostName.indexOf('.');
            sandboxName = hostName.mid(startIndexOfSandboxName, endIndex - startIndexOfSandboxName);
        }

        if (sandboxName != null) {
            res += '.'+sandboxName+getRandNumber(4);
        }
        return res;
    }

    @AuraEnabled
    public static Map<String, Object> createPortalContactAndAccount(String firstName, String lastName, String email, String phone, String street, String postCode, String city, Integer creditClass, String SSN, Boolean marketingPermissions, Boolean smsPermissions, String differentBillingAddress) {
        KiwiOnboardingController controller = new KiwiOnboardingController();
        try {
            CreatePersonData.PersonParameters personParameters = new CreatePersonData.PersonParameters();
            personParameters.firstName = firstName;
            personParameters.lastName = lastName;
            personParameters.emailid = email;
            personParameters.Phone = phone;
            personParameters.CreditScore = creditClass;
            personParameters.CreditUpdatedAt = Datetime.now();
            personParameters.Street = street;
            personParameters.PostalCode = postCode;
            personParameters.City = city;
            personParameters.State = '';
            personParameters.Country = 'Finland';
            personParameters.MarketingCheck = marketingPermissions != null ? marketingPermissions : false;
            personParameters.SMSPermission = smsPermissions != null ? smsPermissions : false;
            personParameters.SSN = SSN;
            if (differentBillingAddress != null && differentBillingAddress != '') {
                Object jsonObj = JSON.deserializeUntyped(differentBillingAddress);
                Map<String, Object> billingAddressMap = (Map<String, Object>) jsonObj;
                personParameters.BillingCity = (String) billingAddressMap.get('city');
                personParameters.BillingCountry = 'Finland';
                personParameters.BillingPostalCode = (String) billingAddressMap.get('postalCode');
                personParameters.BillingState = '';
                personParameters.BillingStreet = (String) billingAddressMap.get('street');
            } else {
                personParameters.BillingCity = city;
                personParameters.BillingCountry = 'Finland';
                personParameters.BillingPostalCode = postCode;
                personParameters.BillingState = '';
                personParameters.BillingStreet = street;
            }

            Contact contactObj = controller.createAccountAndContact(personParameters);
            Map<String, Object> res = new Map<String, Object>();
            res.put('contact', contactObj);
            System.debug(res);
            return KiwiUtils.prepareResponseWithMap(res, false);
        } catch (Exception e) {
            rollbackAccount(controller.createdAccount);
            return KiwiUtils.prepareResponseWithString(e.getMessage(), true);
        }
    }

    @AuraEnabled
    public static Map<String, Object> createPortalUser(Contact contactObj, String email) {
        KiwiOnboardingController controller = new KiwiOnboardingController();
        try {
            Account accountObj = new Account(Id = contactObj.AccountId);
            controller.createdAccount = accountObj;
            Map<String, Object> resBody = new Map<String, Object>();
            String redirectUrl = createUserAndLogin(contactObj.FirstName, contactObj.LastName, email, contactObj.Id, contactObj.AccountId);
            resBody.put('redirectUrl', redirectUrl);
            return KiwiUtils.prepareResponseWithMap(resBody, false);
        } catch (Exception e) {
            Map<String, Object> resMap = new Map<String, Object>();
            resMap.put('stackTrace', e.getStackTraceString());
            resMap.put('message', e.getMessage());
            resMap.put('extra', e.getTypeName());
            return KiwiUtils.prepareResponseWithMap(resMap, true);
        }
    }

    @AuraEnabled
    public static Map<String, Object> convertLeadToPersonAccount(Contact contactObj, Id leadId) {
        Map<String, Object> res = new Map<String, Object>();
        Database.LeadConvert leadConvert = new Database.LeadConvert();
        try {
            LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
            leadConvert.setLeadId(leadId);
            leadConvert.setAccountId(contactObj.AccountId);
            leadConvert.setContactId(contactObj.Id);
            leadConvert.setConvertedStatus(convertStatus.MasterLabel);
            Database.LeadConvertResult leadConvertResult = Database.convertLead(leadConvert);
            res.put('leadConvertResult', leadConvertResult.isSuccess());
            return KiwiUtils.prepareResponseWithMap(res, false);
        } catch (Exception e) {
            res.put('cause', e.getCause());
            res.put('message', e.getMessage());
            return KiwiUtils.prepareResponseWithMap(res, true);
        }
    }

    /**
     * @param accountObj Account
     *
     * Deletes account that was created during onboarding
     */
    private static void rollbackAccount(Account accountObj) {
        if (accountObj != null) {
            delete accountObj;
        }

    }

    @TestVisible
    private static String getAlias(String firstName, String lastName) {
        return firstName.substring(0, 2) +
                lastName.substring(0, 2) +
                getRandNumber(4);
    }

    public static String generatePassword() {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz!"#$%&\'()*+,-./:;<=>?@[\\] _`{|}~.';
        final String specials = '!"#$%&\'()*+,-./:;<=>?@[\\]_`{|}~.';
        final String nums = '0123456789';
        final String alphas = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        Boolean includesSpecial = false;
        Boolean includesNums = false;
        Boolean includesAlphas = false;
        while (randStr.length() < 17) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            if (alphas.contains(chars.substring(idx, idx+1))) {
                includesAlphas = true;
            }
            if (nums.contains(chars.substring(idx, idx+1))) {
                includesNums = true;
            }
            if (specials.contains(chars.substring(idx, idx+1))) {
                includesSpecial = true;
            }
            randStr += chars.substring(idx, idx+1);
        }
        if (!includesAlphas) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), alphas.length());
            randStr += chars.substring(idx, idx+1);
        }
        if (!includesNums) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), nums.length());
            randStr += chars.substring(idx, idx+1);
        }
        if (!includesSpecial) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), specials.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr;
    }

    private static Integer getRandNumber(Integer length) {
        return Integer.valueOf(Math.floor(Math.random() * Math.pow(10, length)));
    }

}