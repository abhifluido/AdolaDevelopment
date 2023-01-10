public without sharing class KiwiController {
  @AuraEnabled
  public static void saveAbandonedCartLead(String email, Boolean emailOptOut,  String link) {
    try {
      // TODO: Create lead
      Lead lead = new Lead(
        Email = email,
        HasOptedOutOfEmail = emailOptOut,
        LeadSource = 'Abandoned Cart',
        LastName = 'Unknown'
      );
      insert lead;
      // TODO: Set up org wide address, e.g., do-not-reply@valoo.fi
      OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'nikita.verkhoshintcev@columbiaroad.com'];
      if (!owea.isEmpty()) {
        EmailTemplate emailTemplate = [SELECT FIELDS(STANDARD) FROM EmailTemplate WHERE DeveloperName = 'Sales_Rep_Purhcase_Link' ORDER BY CreatedDate DESC LIMIT 1];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{email});
        String html = emailTemplate.HtmlValue;
        String textBody = emailTemplate.Body;
        html = html.replace('{!Valoo.PurchaseLink}', link);
        textBody = textBody.replace('{!Valoo.PurchaseLink}', link);
        mail.setHtmlBody(html);
        mail.setPlainTextBody(textBody);
        mail.setSubject(emailTemplate.Subject);
        mail.setSaveAsActivity(true);
        mail.setOrgWideEmailAddressId(owea[0].Id);
        if (!Test.isRunningTest()) {
          Messaging.sendEmail(new List<Messaging.Email>{mail});
        }
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
  /**
   * Availability Search
   */
  @AuraEnabled
  public static Address__c getArea(String postinro, String address) {
    try {
      List<Address__c> addresses = [SELECT Id, Name, Status__c FROM Address__c WHERE Address__PostalCode__s = :postinro AND Address__Street__s = :address];
      if (addresses.isEmpty()) {
        return null;
      }
      return addresses[0];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
  /**
   * Get subscription products that have evergreen selling model type.
   */
  @AuraEnabled(cacheable=true)
  public static List<PricebookEntry> getPriceBookEntries() {
    return [
      SELECT Id, UnitPrice, Product2Id, Product2.Name, Product2.Description, Product2.Product_Image_Link__c,
        Product2.Product_Extra_Description__c, Product2.Product_Recommended__c, Product2.Product_CTA__c,
        ProductSellingModel.Status, ProductSellingModel.SellingModelType, ProductSellingModel.Name
      FROM PricebookEntry
      WHERE Pricebook2.Name = 'Standard Price Book'
        AND ProductSellingModel.Status = 'Active'
        AND ProductSellingModel.SellingModelType = 'Evergreen'
        AND Product2.Family = 'Subscription'
        AND Product2.IsActive = true
      ORDER BY UnitPrice
    ];
  }
  /**
   * Get the order details of the current user
   */
  @AuraEnabled(cacheable=true)
  public static List<Order> getMyOrders() {
    try {
      User u = [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId()];
      List<Order> orders = [SELECT Id, ShippingStreet, ShippingCity, ShippingPostalCode FROM Order WHERE AccountId = :u.AccountId];
      return orders;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
  @AuraEnabled(cacheable=true)
  public static List<PricebookEntry> getMyOrderItems() {
    try {
      List<Order> orders = getMyOrders();
      if (orders.isEmpty()) {
        return null;
      }
      List<OrderItem> orderItems = [
        SELECT Id, PricebookEntryId
        FROM OrderItem
        WHERE OrderId = :orders[0].Id
      ];
      Set<Id> priceBookEntryIds = new Set<Id>();
      for (OrderItem oi : orderItems) {
        priceBookEntryIds.add(oi.PricebookEntryId);
      }
      return [
        SELECT Id, UnitPrice, Product2Id, Product2.Name, Product2.Product_Image_Link__c,
          Product2.Product_Recommended__c, Product2.Product_CTA__c, Product2.Family,
          ProductSellingModel.Status, ProductSellingModel.SellingModelType, ProductSellingModel.Name
        FROM PricebookEntry
        WHERE Id IN :priceBookEntryIds
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
  /**
   * Get the current subsciption
   */
  @AuraEnabled(cacheable=true)
  public static List<OrderItem> getMySubscriptions() {
    try {
      List<Order> orders = getMyOrders();
      Set<Id> orderIds = new Set<Id>();
      for (Order o : orders) {
        orderIds.add(o.Id);
      }
      List<OrderItem> orderItems = [
        SELECT Id, PricebookEntry.UnitPrice, PricebookEntryId
        FROM OrderItem
        WHERE OrderId IN :orderIds
          AND PricebookEntry.ProductSellingModel.SellingModelType = 'Evergreen'
      ];
      return orderItems;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
  /**
   * Get the next upgrade to the current subscription if applicable.
   */
  @AuraEnabled(cacheable=true)
  public static PriceBookEntry getUpgradePriceBookEntry() {
    try {
      List<OrderItem> orderItems = getMySubscriptions();
      if (orderItems.isEmpty()) {
        return null;
      }
      List<PricebookEntry> upgradePriceBookEntries = [
        SELECT Id, UnitPrice, Product2Id, Product2.Name, Product2.Description, Product2.Product_Image_Link__c,
          Product2.Product_Extra_Description__c, Product2.Product_Recommended__c, Product2.Product_CTA__c,
          Product2.Family, ProductSellingModel.Status, ProductSellingModel.SellingModelType, ProductSellingModel.Name
        FROM PricebookEntry
        WHERE Pricebook2.Name = 'Standard Price Book'
          AND ProductSellingModel.Status = 'Active'
          AND ProductSellingModel.SellingModelType = 'Evergreen'
          AND Product2.Family = 'Subscription'
          AND Product2.IsActive = true
          AND UnitPrice > :orderItems[0].PricebookEntry.UnitPrice
        ORDER BY UnitPrice
      ];
      if (upgradePriceBookEntries.isEmpty()) {
        return null;
      }
      return upgradePriceBookEntries[0];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Product_Category__c> getProductCategories() {
    return [SELECT Id, Name, Description__c FROM Product_Category__c ORDER BY CreatedDate];
  }

  @AuraEnabled(cacheable=true)
  public static List<PricebookEntry> getPriceBookEntriesByCategory(Id categoryId) {
    return [
      SELECT Id, UnitPrice, Product2Id, Product2.Name, Product2.Description, Product2.Product_Image_Link__c,
        Product2.Product_Extra_Description__c, Product2.Product_Recommended__c, Product2.Product_CTA__c,
        ProductSellingModel.Status, ProductSellingModel.SellingModelType, ProductSellingModel.Name,
        Product2.Product_Category__c
      FROM PricebookEntry
      WHERE Pricebook2.Name = 'Standard Price Book' AND Product2.Product_Category__c = :categoryId
        AND ProductSellingModel.Status = 'Active'
        AND Product2.IsActive = true
      ORDER BY UnitPrice
    ];
  }

  @AuraEnabled
  public static Object getAvailability(String payload) {
    try {
      HttpRequest req = new HttpRequest();
      req.setEndpoint('https://portaali.netplaza.fi/hubspot/saatavuuskysely/haeosoitteentuotteet_keycom_url.php');
      req.setMethod('GET');
      req.setBody(payload);
      req.setHeader('Content-Type', 'application/json');
      req.setHeader('Origin', 'https://www.valoo.fi');
      Http http = new Http();
      HttpResponse res = http.send(req);
      System.debug(res.getBody());
      return JSON.deserializeUntyped(res.getBody());
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}