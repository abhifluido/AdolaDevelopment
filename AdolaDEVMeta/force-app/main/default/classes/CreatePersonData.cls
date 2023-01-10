public class CreatePersonData {
    //public static List<Id> personDetailsInsert(String firstName, String lastName, String emailid,String Phone, String State,String Street,String City,String Country,String PostalCode, Boolean MarketingCheck, DateTime CreditUpdatedAt, Integer CreditScore, Boolean SMSPermission,String SSN){
    public static List<Id> personDetailsInsert(PersonParameters personParameter)
    {
            List<Id> returnIds = new List<Id>();
            Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
            //List<Account> AccCheck=[SELECT Id, PersonContactId FROM Account WHERE FirstName=:firstName AND LastName=:lastName];
             
            List<Account> AccCheck=[SELECT Id, PersonContactId FROM Account WHERE FirstName=:personParameter.firstName AND LastName=:personParameter.lastName AND PersonEmail=:personParameter.emailid AND PersonMobilePhone =:personParameter.Phone];
            if(AccCheck.size()==0)
            {
                Account newPersonAccount = new Account();
                newPersonAccount.FirstName = personParameter.firstName;
                newPersonAccount.LastName = personParameter.lastName;
                newPersonAccount.RecordTypeId = personAccountRecordTypeId;
                newPersonAccount.PersonEmail = personParameter.emailid;
                newPersonAccount.Phone = personParameter.Phone;
                newPersonAccount.PersonMobilePhone = personParameter.Phone;
                newPersonAccount.BillingState = personParameter.BillingState;
                newPersonAccount.BillingStreet = personParameter.BillingStreet;
                newPersonAccount.BillingCity = personParameter.BillingCity;
                newPersonAccount.BillingCountry = personParameter.BillingCountry;
                newPersonAccount.BillingPostalCode = personParameter.BillingPostalCode;
                newPersonAccount.ShippingState = personParameter.State;
                newPersonAccount.ShippingStreet = personParameter.Street;
                newPersonAccount.ShippingCity = personParameter.City;
                newPersonAccount.ShippingCountry = personParameter.Country;
                newPersonAccount.ShippingPostalCode = personParameter.PostalCode;
                newPersonAccount.Marketing_permission__c = personParameter.MarketingCheck;
                newPersonAccount.Marketing_permission__pc = personParameter.MarketingCheck;
                newPersonAccount.Credit_Class__c = personParameter.CreditScore;
                newPersonAccount.Credit_Class_Updated_At__c = personParameter.CreditUpdatedAt;
                newPersonAccount.SMS_Permission__c = personParameter.SMSPermission;
                newPersonAccount.SMS_Permission__pc = personParameter.SMSPermission;
                newPersonAccount.SSN__c = personParameter.SSN;
                insert newPersonAccount;
                returnIds.add(newPersonAccount.id);
                returnIds.add(newPersonAccount.PersonContactId);
                //List<Address> AddressCheck = [SELECT Id, Account__c FROM Address WHERE Street=:Street AND City=:City];variables.put('varOpportunityId', opportunityId);
                /*  Map<String, Object> variables = new Map<String, Object>();
                    variables.put('varAccId', newPersonAccount.id); 
                    variables.put('varStreet', Street); 
                    variables.put('varCity', City); 
                    variables.put('varPostalCode', PostalCode); 
                    myFlow = new Flow.Interview.Update_Address_Field(variables);
                    myFlow.start();*/
                
                return returnIds;
            }
            else{
                //return AccCheck.get(0).Id;
                returnIds.add(AccCheck.get(0).id);
                if(AccCheck.get(0).PersonContactId != null)
                    returnIds.add(AccCheck.get(0).PersonContactId);
                return returnIds;
            }
                
    }/*
    public static Id accountLocation(Id acc, String AreaCode){
        //Location Loc = [select id from Location where Name =: AreaCode LIMIT 1];
        List<Location> Loc=[SELECT Id, Name FROM Location WHERE Name =: AreaCode LIMIT 1];
        AssociatedLocation associatedLocation = new AssociatedLocation();
        associatedLocation.ParentRecordId = acc;
        if(Loc.size()>0){
            associatedLocation.LocationId = Loc.get(0).Id; 
        }
        insert associatedLocation;
        return associatedLocation.id;
    }
    public static Id addressInsert(Id acc, String State,String Street,String City,String Country,String PostalCode, String AreaCode){
        Address newAddress;
        newAddress.setCurrencyIsoCode='EUR';
        newAddress.ParentId = [select id from Location where Name ='AreaCode'];
        newAddress.setstate = State;
        newAddress.street = Street;
        newAddress.city = City;
        
        newAddress.Country = Country;
        newAddress.PostalCode = PostalCode;
        newAddress.Account__c = acc;
        insert newAddress;
        
    }*/
    public static Id contractInsert(Id accId, Id contactId, Id pricebookId, Id orderId){
        Contract newContract = new Contract();
        newContract.CurrencyIsoCode='EUR';
        //newAddress.ParentId = [select id from Location where Name ='AreaCode'];
        newContract.AccountId = accId;
        newContract.Pricebook2Id = pricebookId;
        newContract.CustomerSignedId = contactId;
        newContract.Order__c = orderId;
        //newContract.ActivatedDate = Date.today();
        newContract.StartDate = Date.today();
        newContract.Status='Draft';
        //newContract.EndDate = Date.today().addYears(2);
        insert newContract;
        newContract.Status='Activated';
        update newContract;
        return newContract.id;
        
    }
    public class PersonParameters{
        public String firstName;
        public String lastName;
        public String emailid;
        public String Phone;
        public String State;
        public String Street;
        public String City;
        public String Country;
        public String PostalCode;
        public Boolean MarketingCheck;
        public DateTime CreditUpdatedAt; 
        public Integer CreditScore; 
        public Boolean SMSPermission;
        public String SSN;
        public String BillingState;
        public String BillingStreet;
        public String BillingCity;
        public String BillingCountry;
        public String BillingPostalCode;
    }
}