/*
    ***********************************************************************
    Name        : Ropo_GETInvoiceStatusHandler
    Author      : Ashish Kumar Singh, Fluido AB
    CreatedDate : December 27, 2022
    Description : Handler to get invoice status from Ropo
    ***********************************************************************
*/
global class Ropo_GETInvoiceStatusHandler{
   /*
        Description : this method is being called by screen flow to fetch invoice status
        Param       : list of InvoiceId
        returntype  : N/A
    */
   @InvocableMethod(callout=true label='Fetch Invoice Status') 
   public Static void getInvoiceStatusAction(list<string> InvoiceId){
       Try{
           system.debug('===InvoiceId===='+InvoiceId);
           Invoice invData = Ropo_GETInvoicePDFHandler.getInvoice(InvoiceId);
           doHttpGetCall(invData.DocumentNumber, UTIL_Constants.CALLING_FROM_UI);
         }catch(Exception e) {
            System.debug('Exception caught: ' + e.getMessage());    
        }   
   }
    /*
        Description : this method is handling http call to Ropo
        Param       : string params(billnum: status for particular invoice or billdate: status for all invoice updated in ropo for this date), string callingFrom
        returntype  : map<string,cls_status>
    */
   public static map<string,cls_status> doHttpGetCall(String params, string callingFrom){
       map<string,cls_status> statusMap = new map<string,cls_status>();
       Try{
           HTTP h = new HTTP();
           MyRopoApp__c myRopo = MyRopoApp__c.getInstance();
           String token = UTIL_GenerateToken.generateTokenRopo(myRopo);
            HTTPRequest req = new HTTPRequest();
                req.setMethod(UTIL_Constants.REST_METHOD_GET);
                if(callingFrom == UTIL_Constants.CALLING_FROM_UI){
                    req.setEndpoint(myRopo.InvoiceStatusEndpoint__c + params);
                }else{
                    req.setEndpoint(myRopo.InvoiceStatusByDate_Endpoint__c + params);
                }
                req.setHeader(UTIL_Constants.REST_CONTENT_HEADER, UTIL_Constants.REST_CONTENT_HEADER_JSON);
                req.setHeader(UTIL_Constants.REST_CONTENT_HEADER_ACCEPT, UTIL_Constants.REST_CONTENT_HEADER_JSON);
                req.setHeader(UTIL_Constants.REST_CONTENT_HEADER_AUTH, UTIL_Constants.REST_CONTENT_HEADER_BEARER + token );
                req.setTimeout(UTIL_Constants.REST_TIMEOUT);
            
            HTTPResponse resp = h.send(req); 
            if(resp.getStatusCode()==UTIL_Constants.REST_STATUS_CODE_200){ 
                system.debug('===resp==='+resp.getBody());
                statusMap = mapHTTPResponse(resp, callingFrom);
             	return statusMap;
            }
       } catch(Exception e){
           
       }
     return statusMap;
   }
    /*
        Description : this method is handling http response getting from Ropo
        Param       : HTTPResponse response, string callingFrom
        returntype  : map<string,cls_status>
    */
   public static map<string,cls_status> mapHTTPResponse(HTTPResponse response, string callingFrom){
       ResponseModel rpm;
       map<string,cls_status> invWithStatusMap = new map<string,cls_status> ();
       if(response != null){
           rpm = (ResponseModel)JSON.deserialize(response.getBody(), ResponseModel.class); 
  
           if(rpm.result.status != null){
               for(cls_status statusObj: rpm.result.status){
                   system.debug('=====statusObj.billnum====='+statusObj.billnum);
                   if(statusObj.billnum != null){
                       invWithStatusMap.put(statusObj.billnum, statusObj);
                   }
               }
               if(callingFrom == 'UI'){
                   updateInvoiceStatus(invWithStatusMap);
               }
           }
       }        
       return invWithStatusMap;
   }
    /*
        Description : this method is updating Invoices with http response getting from Ropo
        Param       : map<string,cls_status>
        returntype  : N/A
    */
   public static void updateInvoiceStatus(map<string,cls_status> invWithStatusMap){
       Map<string,Invoice> getInvoiceMap = getInvoiceByDoc(invWithStatusMap.keyset());
       List<Invoice> invoicesToUpdate = new List<Invoice>();
       for(cls_status statusObj: invWithStatusMap.values()){
           if(getInvoiceMap.containsKey(statusObj.billnum)){
               Invoice invObj = new Invoice(id = getInvoiceMap.get(statusObj.billnum).id);
                   invObj.RC_StatusId__c = statusObj.statusid;
                   invObj.RC_OpenAmount__c = statusObj.openamount;
                   invObj.RC_OriginalAmount__c = statusObj.origamount;
                   invObj.RC_StatusType__c = statusObj.statustype;
                   invObj.RC_StatusRef__c = statusObj.statusref;
                   invObj.RC_StatusText__c = statusObj.statustext;
                   invObj.RC_StatusCd__c = statusObj.statuscode;
                   invObj.RC_Amount__c = statusObj.amount;
                   if(String.isNotBlank(statusObj.statustime))
                       invObj.RC_StatusTime__c = DateTime.ValueOf(statusObj.statustime);                          
                   if(String.isNotBlank(statusObj.paydate))
                       invObj.RC_PayDate__c = Date.ValueOf(statusObj.paydate);               
                           
              invoicesToUpdate.add(invObj);            
            }          
       }
       if(!invoicesToUpdate.isEmpty()){
           system.debug(invoicesToUpdate);
           List<Database.SaveResult> results = Database.update(invoicesToUpdate, false);
       }               
   }
   /*
        Description : This method is for getting Invoices in map with docnum is key
        Param       : Set<String> docNumbers
        returntype  : Map<string,Invoice>
    */
   public static Map<string,Invoice> getInvoiceByDoc(Set<String> docNumbers){
       Map<string,Invoice> getInvoiceMaps = new Map<string,Invoice>();
       if(!docNumbers.isEmpty()){
           for(Invoice invObj: [Select id,DocumentNumber From Invoice Where DocumentNumber IN : docNumbers]){
               getInvoiceMaps.put(invObj.DocumentNumber,invObj);
           }
       }
      
      return getInvoiceMaps; 
   }
    public class ResponseModel{
        public cls_result result;
    }
    public class cls_result {
        public list<cls_status> status;
    }
    public class cls_status {
        public Integer jobid;   //13164734
        public String statusid; //C18850945
        public String billnum;  //DOC-000000116
        public Double openamount;   //10.44
        public Double origamount;   //10.44
        public String statustype;   //comment
        public String statustime;   //2022-12-20 11:49:49
        public String statusref;    //Laskutus
        public String statustext;   //Lasku luotu
        public String statuscode;  //0
        public String paydate;  //2022-12-20
        public Integer amount;  //0
    }
}