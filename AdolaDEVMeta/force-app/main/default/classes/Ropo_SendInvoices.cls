/*
    ***********************************************************************
    Name        : Ropo_SendInvoices
    Author      : Ashish Kumar Singh, Fluido AB
    CreatedDate : December 01, 2022
    Description : Helper class for Invoice Mechanism
    ***********************************************************************
*/
public Class Ropo_SendInvoices{
    
    public static Map<String,Invoice> invMaps;
    /*
        Description : method to do callout to Ropo Capital to send Invoice Data
        Author      : Ashish Kumar Singh, Fluido AB
        Param       : list of invoiceId
        returntype  : N/A
    */
    @future(Callout= true)
    public static void sendInvFutrue(Set<String> invIds){
        MyRopoApp__c myRopo = MyRopoApp__c.getInstance();
        //Stop Sending Invoice Data to Ropo Capitals
        if(myRopo.IsInvoiceON__c){
            String token = UTIL_GenerateToken.generateTokenRopo(myRopo);
            String reqbody = getInvoiceData(invIds);
            system.debug('=====reqbody====='+reqbody);
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            cls_responseModel rpm = new cls_responseModel();
            Try{
                req.setBody(reqbody);
                  req.setMethod(UTIL_Constants.REST_METHOD_POST);
                  req.setEndpoint(myRopo.InvoiceEndpoint__c);
                  req.setHeader(UTIL_Constants.REST_CONTENT_HEADER, UTIL_Constants.REST_CONTENT_HEADER_JSON);
                  req.setHeader(UTIL_Constants.REST_CONTENT_HEADER_ACCEPT, UTIL_Constants.REST_CONTENT_HEADER_JSON);
                  req.setHeader(UTIL_Constants.REST_CONTENT_HEADER_AUTH, UTIL_Constants.REST_CONTENT_HEADER_BEARER + token);
                  req.setTimeout(UTIL_Constants.REST_TIMEOUT);
              HttpResponse res = h.send(req);
              system.debug('=====res.getBody()====='+res.getBody());
              rpm = (cls_responseModel)JSON.deserialize(res.getBody(), cls_responseModel.class); 
              system.debug('=====rpm====='+rpm);
              processResponse(rpm);
             } catch(exception ex){
                system.debug('====ex===='+ex);
                UTIL_ExceptionLogsHandler.buildExceptionLogs('Ropo_SendInvoices','sendInvFutrue','Invoice',null, ex, 'Sending Invoice');
            } 
         }
        
              
    }
    /*
        Description : method to make json payloads as required by Ropo Capital
        Author      : Ashish Kumar Singh, Fluido AB
        Param       : Set of invoiceId
        returntype  : String of JSON Payload
    */
    public static string getInvoiceData(Set<String> invIds){
      cls_requestModel dsts = new cls_requestModel();
      cls_datastream dst = new cls_datastream();
      list<cls_dataset> dsList = new list<cls_dataset>();
      list<cls_payrow> payRowList;
      invMaps = new Map<String,Invoice>();
      for(Invoice inv: [Select id, InvoiceNumber,InvoiceDate,DueDate,DocumentNumber,Description,TotalAmountWithTax,TotalAmount,
                          BillingAccount.Customer_Number__c,BillingAccount.Invoice_delivery_method__c,BillingAccount.Name,BillingAccount.Type, BillingAccount.BillingStreet,BillingAccount.BillingCity,BillingAccount.BillingPostalCode,BillingAccount.BillingCountry,BillToContact.Email,BillToContact.phone,
                          (select id,Name,TaxCode,TaxRate,ChargeAmount,TaxAmount,LineAmount,Type,RelatedLine.ChargeAmount,RelatedLine.LineAmount from invoiceLines Where Type = 'Tax') 
                          From Invoice 
                          Where id IN :invIds]){
          invMaps.put(inv.DocumentNumber,inv);
          cls_dataset ds = new cls_dataset();
              ds.payrow = payRowList;
              ds.jobtype = '0';
              //Customer Details
              ds.custnum = inv.BillingAccount.Customer_Number__c;//Customer_Number__c
              ds.person = inv.BillingAccount.Name;
              ds.vatlayout = '1';
              ds.customertype = '2';//(inv.BillingAccount.Type == 'Customer') ? '2':'1';
              ds.address = inv.BillingAccount.BillingStreet;
              ds.postcode = inv.BillingAccount.BillingPostalCode;
              ds.city = inv.BillingAccount.BillingCity;
              ds.addresscountry = inv.BillingAccount.BillingCountry;
              ds.email = inv.BillToContact.Email;
              ds.phone = inv.BillToContact.phone;
              //Invoice Details
              ds.billnum = inv.DocumentNumber;
              ds.billcode = inv.Id;
              ds.billdate = inv.InvoiceDate;
              ds.paydate = inv.DueDate;
              ds.totalamount = inv.TotalAmount;
              ds.accountdate = inv.InvoiceDate;
              ds.sendtype = inv.BillingAccount.Invoice_delivery_method__c == 'Paper' ? 'post' : inv.BillingAccount.Invoice_delivery_method__c == 'Email' ? 'email' : 'evoice'; //if paper==> post, Email==> email, E-Invoice ==> evoice
              ds.evoice = '';
              ds.evoiceint = '';
              payRowList = new list<cls_payrow>();
              list<cls_accountrow> accountRowList = new list<cls_accountrow>();
              integer linecounter=0;             
              for(InvoiceLine line : inv.invoiceLines){//Invoice Line Details
                  linecounter = linecounter+1;
                  cls_payrow pr = new cls_payrow();
                      pr.count = linecounter;
                      pr.amount = line.RelatedLine.ChargeAmount;
                      pr.netamount = line.RelatedLine.LineAmount;
                      pr.discount = 50;
                      pr.taxpr = line.TaxRate;
                      pr.vatamount = line.LineAmount;
                      pr.totalamount = line.RelatedLine.LineAmount + line.LineAmount;
                      pr.description = line.Name;
                      system.debug('=====line====='+line);
                 
                 payRowList.add(pr); 
                 accountRowList.addAll(getAccountRows(line));
              }
          ds.payrow = payRowList;
          ds.accountrow = accountRowList;
        dsList.add(ds);  
      }
      dst.dataset= dsList;
      dsts.datastream = dst;
      String jsonStr = JSON.serialize(dsts);
      system.debug('======='+jsonStr);
      return jsonStr.replace('description','desc');  
    }
    
    /*
        Description : method to make AccountRows Data required by Ropo Capital
        Author      : Ashish Kumar Singh, Fluido AB
        Param       : Object of InvoiceLine
        returntype  : list<cls_accountrow>
    */
    public static list<cls_accountrow> getAccountRows(InvoiceLine line){
        list<cls_accountrow> accountRows = new list<cls_accountrow>();
      
            cls_accountrow accountDebit = new cls_accountrow();
            accountDebit.accountid = '1731';
            accountDebit.description = line.Name;
            accountDebit.vatcode = line.TaxCode;
            accountDebit.taxpr = line.TaxRate;
            accountDebit.vatamount = line.LineAmount;
            accountDebit.netamount = line.RelatedLine.LineAmount;
            accountDebit.debit = line.RelatedLine.LineAmount;
            accountDebit.credit = null;
            accountDebit.type = '';
            accountDebit.type2 = '';
            accountDebit.type3 = '';
            accountDebit.type4 = '';
            accountRows.add(accountDebit);
            
            cls_accountrow accountCredit = new cls_accountrow();
            accountCredit.accountid = '3059';
            accountCredit.description = line.Name;
            accountCredit.vatcode = line.TaxCode;
            accountCredit.taxpr = line.TaxRate;
            accountCredit.vatamount = line.LineAmount;
            accountCredit.netamount = line.RelatedLine.LineAmount;
            accountCredit.debit = null;
            accountCredit.credit = line.RelatedLine.LineAmount;
            accountCredit.type = '';
            accountCredit.type2 = '';
            accountCredit.type3 = '';
            accountCredit.type4 = '';
            accountRows.add(accountCredit);
       
        return accountRows;
    }
    
    /*
        Description : method to process callout response received from Ropo Capital
        Author      : Ashish Kumar Singh, Fluido AB
        Param       : responseModel
        returntype  : N/A
    */
    public static void processResponse(cls_responseModel rpm){
        list<Invoice> invToUpdate = new list<Invoice>();
          if(rpm.result != null && rpm.result.size() > 0){
              for(cls_result rp :rpm.result){
                  if(invMaps.containskey(rp.billnum)){
                      Invoice inv = invMaps.get(rp.billnum);
                        if(rp.accepted == 1){//Scenario 1 
                            inv.RC_JobId__c = rp.jobid;
                            inv.RC_ReferenceNo__c = rp.reference;
                            inv.RC_InvoiceNotice__c = rp.notice != null ? String.ValueOf(rp.notice) : '';
                            inv.RC_Accepted__c = True;
                        } else if(rp.accepted == 0){//Scenario 2
                            inv.RC_Error__c = rp.error != null ? rp.error : '';
                            inv.RC_Accepted__c = False;
                        }
                     invToUpdate.add(inv);   
                   }
              }
              if(invToUpdate != null && invToUpdate.size() > 0){
                  List<Database.SaveResult> results = Database.update(invToUpdate, false);
                    for (Database.SaveResult result : results) {
                      if (!result.isSuccess()){
                        for (Database.Error err : result.getErrors()){
                            System.debug('Error: '+ err.getStatusCode() + ' ' + err.getMessage());
                        }
                      }
                    }
              }
          }
          if(rpm.errors != null && rpm.errors.size() > 0){
              system.debug(rpm.errors);
          }
    }
    //Request JSON Model Class Starts
    public class cls_requestModel{
        public cls_datastream datastream;
    }
    public class cls_datastream{
        list<cls_dataset> dataset;
    }
    public class cls_dataset{
        public String jobtype; 
        public String custnum;
        public String customertype;
        public String billnum;
        public String billcode;
        public String address;
        public String postcode;
        public String city;
        public String addresscountry; 
        public String email; 
        public String phone; 
        public String sendtype;
        public Date billdate; 
        public Date paydate; 
        public Date accountdate;
        public String person;
        public String vatlayout;
        public String evoice;
        public String evoiceint; 
        public list<cls_payrow> payrow;
        public list<cls_accountrow> accountrow;
        public Double totalamount; 
    }
    public class cls_payrow{
        public String description;
        public integer count; 
        public Double amount; 
        public Double taxpr;
        public Double discount;
        public Double vatamount;
        public Double netamount;
        public Double totalamount;
    }
    public class cls_accountrow{
        public String accountid; 
        public String description; //Product description
        public String vatcode;  //XX
        public Double taxpr;   //24
        public Double vatamount;    
        public Double netamount;
        public Double debit;
        public Double credit; 
        public String type; //YY
        public String type2; //ZZ
        public String type3; //NN
        public String type4; //HH
    }    
    //Request JSON Model Class Ends
    
    //Response JSON Model Class Starts
    public class cls_responseModel{
        public list<cls_result> result;
        public list<cls_errors> errors;
        public Integer accepted;
    }
    class cls_result {
        public Integer accepted; 
        public double amount;   
        public String billnum; 
        public String error; 
        public String evoicetype; 
        public Integer jobid;  
        public String jobstatus;  
        public String jobtype; 
        public list<string> notice;  
        public String origbillnum; 
        public String ownref;  
        public String print;  
        public String receiver;
        public String reference; 
        public String sendtype; 
    }
    class cls_errors {
        public String error;
    }
       
    //Response JSON Model Class Ends
    
    //Response JSON Format
    //Scenario 1
    /*
        {
        "result": [
            {
                "accepted": 1,
                "amount": "152.05",
                "billnum": "1102159476",
                "error": null,
                "evoicetype": "",
                "jobid": 13054357,
                "jobstatus": "0",
                "jobtype": "0",
                "notice": null,
                "origbillnum": null,
                "ownref": "",
                "print": null,
                "receiver": "TEST PERSON2",
                "reference": "127001360130543570",
                "sendtype": "post"
            }
        ],
        "errors": [],
        "accepted": 1
        }
    */
    //Scenario 2
    /*
    {
          "result": [
            {
              "accepted": 0,
              "amount": null,
              "billnum": "DOC-00000008639",
              "error": "Billnum DOC-00000008639 already exists",
              "evoicetype": null,
              "jobid": null,
              "jobstatus": "",
              "jobtype": "",
              "notice": null,
              "origbillnum": null,
              "ownref": "",
              "print": null,
              "receiver": "TestingfirstName11 TestingfirstName11",
              "reference": "",
              "sendtype": "post"
            }
          ],
          "errors": [
            {
              "error": "Error in bill: DOC-00000008639: Billnum DOC-00000008639 already exists"
            }
          ],
          "accepted": 0
        }
    */
}