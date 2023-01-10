/**
 * Created by bartubazna on 11.11.2022.
 */

public with sharing class KiwiBisnodeController {
    public static final String BISNODE_CALLOUT_URL = 'callout:BisnodeNC';
    @TestVisible
    private BisnodeConfig__c bisnodeConfig { get; set; }
    @TestVisible
    private Boolean updateTicket { get; set; }
    @TestVisible
    private String ticket { get; set; }
    @TestVisible
    private String endUsername { get; set; }

    public KiwiBisnodeController() {
        List<BisnodeConfig__c> bisnodeConfigs = [
                SELECT Id, LastModifiedDate, Ticket__c, Expires_At__c, End_Username__c FROM BisnodeConfig__c
        ];
        if (bisnodeConfigs != null && bisnodeConfigs.size() > 0) bisnodeConfig = bisnodeConfigs[0];
    }

    /**
     * Initialise HttpRequest and add ticket. If ticket isn't available or is expired,
     * authenticateBisnodeAndGetTicket method is called to update the access token.
     *
     * This method should always be called before any callout to prevent 401/403 responses.
     *
     * @param method String - Request method
     * @param resource String - Resource path (Example: /identification/v2/sessions)
     *
     * @return HttpRequest
     */
    public HttpRequest initBisnode(String method, String resource) {
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod(method);
        httpRequest.setEndpoint(BISNODE_CALLOUT_URL + resource);
        Boolean isTokenStillValid = false;
        if (bisnodeConfig != null) {
            isTokenStillValid = isTokenValid();
        }

        if (isTokenStillValid) {
            httpRequest.setHeader('x-api-key', bisnodeConfig.Ticket__c);
        } else {
            httpRequest.setHeader('x-api-key', authenticateBisnodeAndGetTicket());
        }
        return httpRequest;

    }

    @TestVisible
    /**
     * Starts the OAuth flow against Signicat API and returns the granted access token.
     * @return String
     */
    private String authenticateBisnodeAndGetTicket() {
        HttpRequest ticketRequest = new HttpRequest();
        Http http = new Http();
        ticketRequest.setEndpoint(BISNODE_CALLOUT_URL + '/permission/v1/ticket');
        ticketRequest.setMethod('GET');
        ticketRequest.setHeader('Content-Type', 'application/json');
        ticketRequest.setHeader('Authorization', 'Basic {!$Credential.AuthorizationHeaderValue}');
        HttpResponse httpResponse = http.send(ticketRequest);
        if (httpResponse.getStatusCode() == 200) {
            Object jsonObj = JSON.deserializeUntyped(httpResponse.getBody());
            Map<String, Object> mapVals = (Map<String, Object>) jsonObj;
            ticket = String.valueOf(mapVals.get('ticket'));
            endUsername = String.valueOf(mapVals.get('endusername'));
            updateTicket = true;
        }
        return ticket;
    }

    /**
     * Call this function at the end of execution to save ticket.
     * If called before end of execution, SF will complain about pending work that is not committed.
     */
    public void saveTicket() {
        if (ticket == null || ticket.length() == 0 || !updateTicket) return;

        Boolean isInsert = false;

        if (bisnodeConfig != null && isTokenValid()) return;
        if (bisnodeConfig != null) {
            bisnodeConfig.Ticket__c = '';
            isInsert = false;
        } else {
            bisnodeConfig = new BisnodeConfig__c();
            isInsert = true;
        }
        bisnodeConfig.Ticket__c = ticket;
        bisnodeConfig.End_Username__c = endUsername;
        bisnodeConfig.Expires_At__c = Datetime.now().addMinutes(20);
        if (isInsert) {
            insert bisnodeConfig;
        } else {
            update bisnodeConfig;
        }
    }

    @TestVisible
    /**
     * Checks if token has expired
     *
     * @return Boolean
     */
    private Boolean isTokenValid() {
        return Datetime.now() <= bisnodeConfig.Expires_At__c;
    }

    @TestVisible
    private static String buildQueryParams(String query, Map<String, Object> params) {
        List<String> keys = new List<String>(params.keySet());
        Integer i = 0;
        for (String key : keys) {
            if (i == 0) query += '?'+key+'='+params.get(key);
            if (i > 0) query+='&'+key+'='+params.get(key);
            i++;
        }
        return query;
    }

    public String retrieveCreditRemarksFromBisnode(String hetu) {
        Http http = new Http();
        Map<String, Object> params = new Map<String, Object>();
        params.put('user', bisnodeConfig.End_Username__c);
        params.put('id', hetu);
        params.put('purposeCode', 1);
        HttpRequest request = initBisnode('GET', buildQueryParams('/people/info/v2/remarks', params));
        HttpResponse res = http.send(request);
        if (res.getStatusCode() != 200) {
            throw new KiwiException('Failed to get credit remarks');
        }
        return res.getBody();
    }

    @TestVisible
    /**
     * @param body String
     * Prases the credit class from the response from Bisnode credit remarks API
     *
     * @return Integer
     */
    private static Integer getCreditClass(String body) {
        Object jsonObj = JSON.deserializeUntyped(body);
        Map<String, Object> mapVals = (Map<String, Object>) jsonObj;
        Integer creditClass = Integer.valueOf(mapVals.get('creditClass'));
        return creditClass;
    }

    @TestVisible
    /**
     * @param body String
     * Parses the credit remarks entries from the response from Bisnode credit remarks API
     *
     * @return List<Map<String, Object>>
     */
    private static List<Map<String, Object>> getCreditRemarksList(String body) {
        Object jsonObj = JSON.deserializeUntyped(body);
        Map<String, Object> mapVals = (Map<String, Object>) jsonObj;
        List<Map<String, Object>> myMaps = new List<Map<String, Object>>();
        List<Object> myMapObjects = (List<Object>) mapVals.get('remarks');
        for (Object obj : myMapObjects) {
            myMaps.add((Map<String, Object>)obj);
        }
        return myMaps;
    }

    @TestVisible
    private static void updateUserCreditClass(Account account, Integer creditClass) {
        try {
            if (account != null) {
                account.Credit_Class__c = creditClass;
                account.Credit_Class_Updated_At__c = Datetime.now();
                update account;
            }
        } catch (Exception e) {
            System.debug('#### Failed to update credit class ####');
        }
    }

    @AuraEnabled
    public static Map<String, Object> getCreditRemarks(String hetu) {
        KiwiBisnodeController controller = new KiwiBisnodeController();
        Map<String, Object> res = new Map<String, Object>();
        Map<String, Object> resInfo = new Map<String, Object>();
        try {
            String creditRemarks = controller.retrieveCreditRemarksFromBisnode(hetu);
            resInfo.put('creditClass', getCreditClass(creditRemarks));
            res = KiwiUtils.prepareResponseWithMap(resInfo, false);
            controller.saveTicket();
            return res;
        } catch (Exception e) {
            controller.saveTicket();
            return KiwiUtils.prepareResponseWithString(e.getMessage(), true);
        }
    }

    @AuraEnabled
    public static Map<String, Object> getCreditRemarksForRegisteredUser(Id accountId) {
        KiwiBisnodeController controller = new KiwiBisnodeController();
        Map<String, Object> res = new Map<String, Object>();
        Map<String, Object> resInfo = new Map<String, Object>();
        try {
            Account account = [SELECT Credit_Class__c, Credit_Class_Updated_At__c FROM Account WHERE Id = :accountId LIMIT 1];
            String ssn = KiwiSSNHelper.decryptSSN(accountId);
            String creditRemarks = controller.retrieveCreditRemarksFromBisnode(ssn);
            resInfo.put('creditClass', getCreditClass(creditRemarks));
            resInfo.put('creditRemarks', getCreditRemarksList(creditRemarks));
            res = KiwiUtils.prepareResponseWithMap(resInfo, false);
            updateUserCreditClass(account, getCreditClass(creditRemarks));
            controller.saveTicket();
            return res;
        } catch (Exception e) {
            controller.saveTicket();
            return KiwiUtils.prepareResponseWithString(e.getMessage(), true);
        }
    }

}