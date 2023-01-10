global class KiwiISPIntegration {
    @InvocableMethod(label='Ping ISP integration' description='Sends Customer ID to ISP Integration when changed')
    public static void PingISPIntegrationOnCustomerChange(List<String> ids){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://prod-202.westeurope.logic.azure.com:443/workflows/0b999e63c0fb4e26adfbae67c42b8fc5/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=CVL12xm9xf864I-Lp9so7l1elUbXGFECKzmeKU-yUYk');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');  
        
        Map<String, Object> body = new Map<String, Object>{'ids' => ids};
        req.setBody(JSON.serialize(body));

        Http http = new Http();
        HTTPResponse res = http.send(req);
    }
}