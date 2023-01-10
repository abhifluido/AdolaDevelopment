/**
 * Created by bartubazna on 31.10.2022.
 */

public with sharing class KiwiSignicatController {
    public static final String SIGNICAT_CALLOUT_URL = 'callout:SignicatTestNC';
    @TestVisible
    private SignicatConfig__c signicatConfig { get; set; }
    @TestVisible
    private Boolean updateAccessToken { get; set; }
    @TestVisible
    private String accessToken { get; set; }

    public KiwiSignicatController() {
        List<SignicatConfig__c> signicatConfigs = [
                SELECT Id, LastModifiedDate, Access_Token_1__c, Access_Token_2__c, Access_Token_3__c,
                        Access_Token_4__c, Access_Token_5__c, Access_Token_6__c, Expires_At__c, AES_Key__c,
                        Success_URL__c, Abort_URL__c, Error_URL__c
                FROM SignicatConfig__c
        ];
        if (signicatConfigs != null && signicatConfigs.size() > 0) signicatConfig = signicatConfigs[0];
    }

    @TestVisible
    /**
     * Initialise HttpRequest and add access_token. If access_token isn't available or is expired,
     * authenticateSignicatAndGetAccessToken method is called to update the access token.
     *
     * This method should always be called before any callout to prevent 401/403 responses.
     *
     * @param method String - Request method
     * @param resource String - Resource path (Example: /identification/v2/sessions)
     *
     * @return HttpRequest
     */
    private HttpRequest initSignicat(String method, String resource) {
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod(method);
        httpRequest.setEndpoint(SIGNICAT_CALLOUT_URL + resource);
        Boolean isTokenStillValid = false;
        if (signicatConfig != null) {
            isTokenStillValid = isTokenValid();
        }

        if (isTokenStillValid) {
            httpRequest.setHeader('Authorization', 'Bearer ' +
                    KiwiUtils.replaceNullVal(signicatConfig.Access_Token_1__c) +
                    KiwiUtils.replaceNullVal(signicatConfig.Access_Token_2__c) +
                    KiwiUtils.replaceNullVal(signicatConfig.Access_Token_3__c) +
                    KiwiUtils.replaceNullVal(signicatConfig.Access_Token_4__c) +
                    KiwiUtils.replaceNullVal(signicatConfig.Access_Token_5__c) +
                    KiwiUtils.replaceNullVal(signicatConfig.Access_Token_6__c)
            );
        } else {
            httpRequest.setHeader('Authorization', 'Bearer ' + authenticateSignicatAndGetAccessToken());
        }
        return httpRequest;

    }

    @TestVisible
    /**
     * Starts the OAuth flow against Signicat API and returns the granted access token.
     * @return String
     */
    private String authenticateSignicatAndGetAccessToken() {
        HttpRequest accessTokenRequest = new HttpRequest();
        Http http = new Http();
        accessTokenRequest.setEndpoint(SIGNICAT_CALLOUT_URL + '/oauth/connect/token');
        accessTokenRequest.setMethod('POST');
        accessTokenRequest.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        accessTokenRequest.setHeader('Authorization', 'Basic {!$Credential.AuthorizationHeaderValue}');
        String body = 'grant_type=client_credentials&scope=info_natural_person_read identify document_read document_write document_file';
        accessTokenRequest.setBody(body);
        HttpResponse httpResponse = http.send(accessTokenRequest);
        if (httpResponse.getStatusCode() == 200) {
            Object jsonObj = JSON.deserializeUntyped(httpResponse.getBody());
            Map<String, Object> mapVals = (Map<String, Object>) jsonObj;
            accessToken = String.valueOf(mapVals.get('access_token'));
            updateAccessToken = true;
        }
        return accessToken;
    }

    @TestVisible
    /**
     * Call this function at the end of execution to save access token.
     * If called before end of execution, SF will complain about pending work that is not committed.
     */
    private void saveAccessToken() {
        if (accessToken == null || accessToken.length() == 0 || !updateAccessToken) return;

        Boolean isInsert = false;

        if (signicatConfig != null && isTokenValid()) return;
        if (signicatConfig != null) {
            signicatConfig.Access_Token_1__c = '';
            signicatConfig.Access_Token_2__c = '';
            signicatConfig.Access_Token_3__c = '';
            signicatConfig.Access_Token_4__c = '';
            signicatConfig.Access_Token_5__c = '';
            signicatConfig.Access_Token_6__c = '';
            signicatConfig.Expires_At__c = null;
            isInsert = false;
        } else {
            signicatConfig = new SignicatConfig__c();
            isInsert = true;
        }

        if (accessToken.length() > 0) {
            signicatConfig.Access_Token_1__c = accessToken.length() > 255 ? accessToken.substring(0, 255) : accessToken.substring(0, accessToken.length());
        }
        if (accessToken.length() > 255) {
            signicatConfig.Access_Token_2__c = accessToken.length() > 510 ? accessToken.substring(255, 510) : accessToken.substring(255, accessToken.length());
        }
        if (accessToken.length() > 510) {
            signicatConfig.Access_Token_3__c = accessToken.length() > 765 ? accessToken.substring(510, 765) : accessToken.substring(510, accessToken.length());
        }
        if (accessToken.length() > 765) {
            signicatConfig.Access_Token_4__c = accessToken.length() > 1020 ? accessToken.substring(765, 1020) : accessToken.substring(765, accessToken.length());
        }
        if (accessToken.length() > 1020) {
            signicatConfig.Access_Token_5__c = accessToken.length() > 1275 ? accessToken.substring(1020, 1275) : accessToken.substring(1020, accessToken.length());
        }
        if (accessToken.length() > 1275) {
            signicatConfig.Access_Token_6__c = accessToken.substring(1275, accessToken.length());
        }
        signicatConfig.Expires_At__c = Datetime.now().addHours(1);
        if (isInsert) {
            insert signicatConfig;
        } else {
            update signicatConfig;
        }
    }

    @TestVisible
    /**
     * Sends the HttpRequest to Signicat API
     * @param httpRequest HttpRequest
     *
     * @return HttpResponse
     */
    private static HttpResponse sendHttpRequest(HttpRequest httpRequest) {
        Http http = new Http();
        HttpResponse httpResponse = http.send(httpRequest);
        return httpResponse;
    }

    @TestVisible
    /**
     * Checks if token has expired
     *
     * @return Boolean
     */
    private Boolean isTokenValid() {
        return Datetime.now() <= signicatConfig.Expires_At__c;
    }

    /**
     * Decrypts given encrypted information and returns a map of identity information
     * @param input String
     *
     * @return Boolean
     */
    public Map<String, Object> decryptWithPrivateKey(String input) {
        String decryptorRes = getAESEncryptedData(input);
        String hexIv;
        String hexData;
        if (decryptorRes != null) {
            Object jsonObj = JSON.deserializeUntyped(decryptorRes);
            Map<String, Object> mapVals = (Map<String, Object>) jsonObj;
            hexIv = String.valueOf(mapVals.get('iv'));
            hexData = String.valueOf(mapVals.get('data'));
        }
        String key = signicatConfig.AES_Key__c;
        Blob data = EncodingUtil.convertFromHex(hexData);
        Blob iv = EncodingUtil.convertFromHex(hexIv);
        Blob decrypted = Crypto.decrypt('AES256', Blob.valueOf(key), iv, data);
        Object relevantInformationJSON = JSON.deserializeUntyped(decrypted.toString());
        Map<String, Object> relevantInformationMap = (Map<String, Object>) relevantInformationJSON;
        Map<String, Object> identityInformationMap;
        if (relevantInformationMap != null && relevantInformationMap.get('status') == 'success') {
            identityInformationMap = (Map<String, Object>) relevantInformationMap.get('identity');
        }

        return identityInformationMap;
    }

    @TestVisible
    /**
     * Creates request body for creating authentication session with Signicat
     *
     * @return String
     */
    private static String createSessionBody(KiwiSignicatController controller) {
        Map<String, Object> body = new Map<String, Object>();
        body.put('flow', 'redirect');
        body.put('allowedProviders', new List<String>{
                'ftn'
        });
        body.put('include', new List<String>{
                'name', 'date_of_birth', 'nin'
        });
        Map<String, Object> redirectSettings = new Map<String, Object>();
        redirectSettings.put('successUrl', controller.signicatConfig.Success_URL__c);
        redirectSettings.put('abortUrl', controller.signicatConfig.Abort_URL__c);
        redirectSettings.put('errorUrl', controller.signicatConfig.Error_URL__c);
        body.put('redirectSettings', redirectSettings);
        return JSON.serialize(body);
    }

    @TestVisible
    /**
     * Fetches redirect url after successful session initiation
     *
     * @return String
     */
    private static String getRedirectUrl(String resBody) {
        Object jsonObj = JSON.deserializeUntyped(resBody);
        Map<String,Object> mapVals = (Map<String,Object>) jsonObj;
        return String.valueOf(mapVals.get('url'));
    }

    @TestVisible
    private static String createAuthSession(KiwiSignicatController controller) {
        HttpRequest signicatReq = controller.initSignicat('POST', '/identification/v2/sessions/');
        signicatReq.setBody(createSessionBody(controller));
        signicatReq.setHeader('Content-Type', 'application/json');
        HttpResponse res = sendHttpRequest(signicatReq);
        if (res.getStatusCode() != 201) {
            throw new KiwiException('Failed to create auth session');
        }
        controller.saveAccessToken();
        return getRedirectUrl(res.getBody());
    }

    @TestVisible
    /**
     * Fetches encrypted session data from Signicat
     *
     * @param controller KiwiSignicatController
     * @param sessionId String
     *
     * @return String
     */
    private static String getEncryptedSessionData(KiwiSignicatController controller, String sessionId) {
        HttpRequest signicatReq = controller.initSignicat('GET', '/identification/v2/sessions/' + sessionId);
        signicatReq.setHeader('Content-Type', 'application/json');
        signicatReq.setHeader('Accept', 'application/jwe');
        HttpResponse res = sendHttpRequest(signicatReq);
        if (res.getStatusCode() != 200) {
            throw new KiwiException('Failed to get auth details');
        }
        return res.getBody();
    }

    /**
     * @param input String
     * Takes encrypted string as input, sends a callout to microservice to decrypt RSA encrypted string
     * and retrieves an AES encrypted string back in response.
     *
     * @return String
     */
    public static String getAESEncryptedData(String input) {
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod('POST');
        httpRequest.setEndpoint('callout:KiwiDecryptorNC/api/decrypt');
        httpRequest.setHeader('Authorization', '{!$Credential.Password}');
        httpRequest.setHeader('Content-Type', 'application/json;charset=UTF-8');
        httpRequest.setTimeout(30000);
        Map<String, Object> body = new Map<String, Object>();
        body.put('data', input);
        httpRequest.setBody(JSON.serialize(body));
        HttpResponse res = sendHttpRequest(httpRequest);
        if (res.getStatusCode() != 200) {
            throw new KiwiException('Failed to decrypt data');
        }
        return res.getBody();
    }

    @AuraEnabled
    public static Map<String, Object> startUserSession() {
        try {
            KiwiSignicatController controller = new KiwiSignicatController();
            return KiwiUtils.prepareResponseWithString(createAuthSession(controller), false);
        } catch (Exception e) {
            return KiwiUtils.prepareResponseWithString(e.getMessage(), true);
        }
    }

    @AuraEnabled
    public static Map<String, Object> getSessionData(String sessionId) {
        KiwiSignicatController controller = new KiwiSignicatController();
        try {
            String encryptedSessionData = getEncryptedSessionData(controller, sessionId);
            Map<String, Object> res = controller.decryptWithPrivateKey(encryptedSessionData);
            controller.saveAccessToken();
            return KiwiUtils.prepareResponseWithMap(res, false);
        } catch (Exception e) {
            controller.saveAccessToken();
            return KiwiUtils.prepareResponseWithString(e.getMessage(), true);
        }
    }

}