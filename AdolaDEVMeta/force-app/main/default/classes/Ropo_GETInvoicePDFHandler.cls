/*
    ***********************************************************************
    Name        : Ropo_GETInvoicePDFHandler
    Author      : Ashish Kumar Singh, Fluido AB
    CreatedDate : December 12, 2022
    Description : Class to Fetch Invoice PDF from ROPO
    ***********************************************************************
*/
global class Ropo_GETInvoicePDFHandler{
    
   /*
        Description : method to do callout to Ropo Capital
        Author      : Ashish Kumar Singh, Fluido AB
        Param       : list of invoiceId from flow
        returntype  : pdf in blob
    */
   @InvocableMethod(callout=true label='Fetch and Attach Invoice PDF') 
   public Static void doGET(list<string> InvoiceId){
       Try{
           HTTP h = new HTTP();
           MyRopoApp__c myRopo = MyRopoApp__c.getInstance();
           String token = UTIL_GenerateToken.generateTokenRopo(myRopo);
           system.debug('===InvoiceId===='+InvoiceId);
           Invoice invData = getInvoice(InvoiceId);
            HTTPRequest req = new HTTPRequest();
                req.setMethod(UTIL_Constants.REST_METHOD_GET);
                req.setEndpoint(myRopo.InvoicePDFEndpoint__c + invData.DocumentNumber);
                req.setHeader(UTIL_Constants.REST_CONTENT_HEADER, UTIL_Constants.REST_CONTENT_HEADER_PDF);
                req.setHeader(UTIL_Constants.REST_CONTENT_HEADER_ACCEPT, UTIL_Constants.REST_CONTENT_HEADER_PDF);
                req.setHeader(UTIL_Constants.REST_CONTENT_HEADER_AUTH, UTIL_Constants.REST_CONTENT_HEADER_BEARER + token );
                req.setTimeout(UTIL_Constants.REST_TIMEOUT);
            
            HTTPResponse resp = h.send(req); 
            if(resp.getStatusCode()==UTIL_Constants.REST_STATUS_CODE_200){ 
                //String base64Response = resp.getBody();
                blob response = resp.getBodyAsBlob();
                Attachment attach = new Attachment();
                attach.contentType = 'application/pdf';
                attach.name = 'myfile111.pdf';
                attach.parentId = invData.Id;
                attach.body = response; 
                //insert attach;
                
                ContentVersion cv = new ContentVersion();
                    cv.Title = 'Invoice';
                    cv.PathOnClient = 'Invoice.pdf';
                    cv.VersionData = response;
                    cv.IsMajorVersion = true;
                Insert cv;
                Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
                ContentDocumentLink cdl = New ContentDocumentLink();
                    cdl.LinkedEntityId = invData.Id;
                    cdl.ContentDocumentId = conDocId;
                    cdl.shareType = 'V';
                Insert cdl;
            }
         }catch(Exception e) {
            System.debug('Exception caught: ' + e.getMessage());    
        }   
   }
   /*
        Description : method to get invoiceId
        Author      : Ashish Kumar Singh, Fluido AB
        Param       : list of invoiceId
        returntype  : invoice object
    */
   public static Invoice getInvoice(list<String> InvoiceId){
       system.debug('===InvoiceId==='+InvoiceId);
       Invoice inv = [Select id,DocumentNumber From Invoice Where id IN : InvoiceId];
      
      return inv; 
   }
}