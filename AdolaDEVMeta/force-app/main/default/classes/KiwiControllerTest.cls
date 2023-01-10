@isTest
public with sharing class KiwiControllerTest {
  @isTest
  public static void  testMethods() {
    Test.setMock(HttpCalloutMock.class, new KiwiControllerMock());
    Product_Category__c category = new Product_Category__c();
    category.Name = 'Test';
    category.Description__c = 'Test';
    insert category;
    Product2 product = new Product2(
      Name = 'Test',
      Description = 'Test',
      IsActive = true,
      Family = 'Subscription',
      Product_Category__c = category.Id
    );
    insert product;
    ProductSellingModel psm = new ProductSellingModel(
      Name = 'Test',
      Status = 'Active',
      SellingModelType = 'Evergreen',
      PricingTerm = 1,
      PricingTermUnit = 'Months'
    );
    insert psm;
    PricebookEntry pbe = new PricebookEntry(
      UnitPrice = 10,
      Product2Id = product.Id,
      ProductSellingModelId = psm.Id,
      Pricebook2Id = Test.getStandardPricebookId()
    );
    insert pbe;
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User']; 
    Account a = new Account(
      Name = 'Test'
    );
    insert a;
    Contact c = new Contact(
      AccountId = a.Id,
      LastName = 'Test'
    );
    insert c;
    User u = new User(
      Alias = 'standt',
      Email = 'standardusertest@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US', 
      LocaleSidKey = 'en_US',
      ProfileId = p.Id, 
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'standardusertest@testorg.com',
      ContactId = c.Id
    );
    insert u;
    User user = [SELECT Id, AccountId FROM User WHERE Id = :u.Id];
    System.debug(user.AccountId);
    Order o = new Order(
      AccountId = a.Id,
      Status = 'Draft',
      EffectiveDate = System.today(),
      EndDate = System.today() + 4,
      Pricebook2Id = Test.getStandardPricebookId()
    );
    insert o;
    OrderItem oi = new OrderItem(
      PricebookEntryId = pbe.Id,
      Product2Id = product.Id,
      Quantity = 1,
      UnitPrice = 240,
      OrderId = o.Id
    );
    insert oi;
    Address__c address = new Address__c();
    address.Status__c = 'Available';
    address.Address__PostalCode__s = '00100';
    address.Address__Street__s = 'Test Street 1A';
    insert address;
    Test.startTest();
    KiwiController.getPriceBookEntries();
    KiwiController.getProductCategories();
    KiwiController.getPriceBookEntriesByCategory(category.Id);
    KiwiController.getAvailability('test');
    System.runAs(u) {
      KiwiController.getMyOrderItems();
      KiwiController.getMySubscriptions();
      KiwiController.getUpgradePriceBookEntry();
    }
    KiwiController.saveAbandonedCartLead('test@testaaja.com', false, 'test');
    KiwiController.getArea('00100', 'Test Street 1A');
    KiwiController.getArea('00100', 'Not found');
    Test.stopTest();
  }
}