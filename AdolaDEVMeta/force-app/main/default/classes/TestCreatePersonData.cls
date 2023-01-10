@isTest
public class TestCreatePersonData {
    static testMethod void testingPersonData(){
        CreatePersonData.PersonParameters perData = new CreatePersonData.PersonParameters();
        perData.firstName = 'TestFirstNmWrapper01';
        perData.lastName = 'TestLastNmWrapper01';
        perData.emailid = 'test01@wrapper.com';
        perData.Phone = '90887465679';
        perData.State = '';
        perData.Street = '4 Norrgårdinkatu';
        perData.City = 'Turku';
        perData.Country='Finland';
        perData.PostalCode='20901';
        perData.MarketingCheck=TRUE;
        //Datetime dt = Datetime.parse('20/12/2022 08:00AM'); 
        perData.CreditUpdatedAt=Datetime.parse('3.11.2022 14.49');
        perData.CreditScore=1; 
        perData.SMSPermission=TRUE;
        List<Id> returnval = CreatePersonData.personDetailsInsert(perData);
        System.debug(returnval);
        System.assertEquals(2, returnval.size(), 'Test Person Data Successful 1');
        List<Id> returnval1 = CreatePersonData.personDetailsInsert(perData);
        System.assertEquals(2, returnval.size(), 'Test Person Data Successful 2');
        Account acc = [select id,PersonContactId from Account where id =: returnval[0]];
        Order o = new Order(
            EffectiveDate = Date.today(),
            Status = 'Draft',
            AccountId = acc.id,
            BillToContactId = acc.PersonContactId,
            BillingState = 'CA',
            BillingCity = 'Beverly Hills',
            BillingCountry = 'US',
            BillingPostalCode = '90210',
            BillingStreet = '444 Fake St.',
            OrderedDate = Datetime.newInstance(2022, 1, 2, 3, 4, 5),
            Pricebook2Id = System.Test.getStandardPricebookId()
        );
        Id contractId = CreatePersonData.contractInsert(acc.id, acc.PersonContactId, System.Test.getStandardPricebookId(), o.id);
        System.debug(contractId);
        System.assert(contractId != null , 'Test Contract Creation Successful');
    }
    
        
}