/**
 * Created by bartubazna on 12.12.2022.
 */

public with sharing class KiwiSupportController {
    @AuraEnabled
    public static Map<String, Object> getSecurityDepositQueue() {
        Map<String, Object> res = new Map<String, Object>();
        try {
            List<Group> csGroups = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Security_Deposit_Queue'];
            Id groupId;
            if (csGroups != null && csGroups.size() > 0) groupId = csGroups[0].Id;
            res.put('groupId', groupId);
            return KiwiUtils.prepareResponseWithMap(res, false);
        } catch (Exception e) {
            res.put('cause', e.getCause());
            res.put('message', e.getMessage());
            return KiwiUtils.prepareResponseWithMap(res, true);
        }
    }

    @AuraEnabled
    public static Map<String, Object> createCase(Case caseObj) {
        Map<String, Object> res = new Map<String, Object>();
        try {
            insert caseObj;
            res.put('caseId', caseObj.Id);
            return KiwiUtils.prepareResponseWithMap(res, false);
        } catch (Exception e) {
            res.put('cause', e.getCause());
            res.put('message', e.getMessage());
            return KiwiUtils.prepareResponseWithMap(res, true);
        }
    }

    @AuraEnabled
    public static Map<String, Object> sendEmailWithLink(String link, String email) {
        Map<String, Object> res = new Map<String, Object>();
        try {
            EmailTemplate emailTemplate = [SELECT FIELDS(STANDARD) FROM EmailTemplate WHERE DeveloperName = 'Sales_Rep_Purhcase_Link' ORDER BY CreatedDate DESC LIMIT 1];
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String html = emailTemplate.HtmlValue;
            String textBody = emailTemplate.Body;
            html = html.replace('{!Valoo.PurchaseLink}', link);
            textBody = textBody.replace('{!Valoo.PurchaseLink}', link);
            mail.setToAddresses(new List<String>{email});
            mail.setHtmlBody(html);
            mail.setPlainTextBody(textBody);
            mail.setSenderDisplayName('OmaValoo Sales');
            mail.setSubject(emailTemplate.Subject);
            List<Messaging.SendEmailResult> emailResults = Messaging.sendEmail(new List<Messaging.Email>{mail});
            Boolean emailResult = false;
            if (emailResults != null && emailResults.size() > 0) {
                emailResult = emailResults[0].isSuccess();
            }
            res.put('emailResult', emailResult);
            return KiwiUtils.prepareResponseWithMap(res, false);
        } catch (Exception e) {
            res.put('cause', e.getCause());
            res.put('message', e.getMessage());
            return KiwiUtils.prepareResponseWithMap(res, true);
        }
    }
}