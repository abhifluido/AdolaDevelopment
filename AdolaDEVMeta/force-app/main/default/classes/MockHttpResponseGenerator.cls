@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req){
        try{
            //if(req.getEndpoint()=='https://google.com'){
                String strBody = testParse();
                //String strBody = '{"token": "eyJ0eXAiO"}';
                HttpResponse res= new HttpResponse();
                res.setHeader('Content-Type','application/json');
                res.setBody(strBody);
                res.setStatusCode(200);
                return res;
            //}
        }catch(Exception ex){
                System.debug('ERROR Message>>>'+ex.getMessage()+' Error Line Number>>> '+ex.getLineNumber());
        }
        return null;
    }  
    static string testParse() {
        String jsonstr= '{"result": {"status": [{"jobid": 13164734,"statusid": "C18850945","billnum": "DOC-000000116","openamount": 10.44,"origamount": 10.44,"statustype": "comment","statustime": "2022-12-20 11:49:49","statusref": "Laskutus","statustext": "Lasku luotu","statuscode": "0","paydate": "2022-12-20","amount": 0}]}}';
       return  jsonstr;
    }   
}