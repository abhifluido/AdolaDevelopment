/**
 * Created by bartubazna on 25.11.2022.
 */

public with sharing class KiwiOrderController {

    @TestVisible
    public class KiwiOrderRequest {
        public Id accountId;
        public Id billToContactId;
        public Id pricebook2Id;
        public Boolean requiresDeposit;
        public String inboundOutbound;
        public String status;
        public Boolean isDepositOrder;
    }

    @TestVisible
    public class KiwiOrderItemRequest {
        public Id pricebookEntryId;
        public Id product2Id;
        public Integer discountPercentage;
        public Id taxTreatmentId;
    }

    @AuraEnabled
    public static Map<String, Object> createOrderWithBuyNow(Map<String, Object> kiwiOrderRequestMap, List<String> kiwiOrderItemRequestList, Id paymentMethodId) {
        Map<String, Object> res = new Map<String, Object>();
        try {
            KiwiOrderRequest kiwiOrderRequest = convertMapToKiwiOrderRequest(kiwiOrderRequestMap);
            Order orderObj = createOrderObject(kiwiOrderRequest);
            List<OrderItem> orderItems = createOrderItems(kiwiOrderItemRequestList);
            Map<String, Object> request = new Map<String, Object>();
            request.put('order', orderObj);
            request.put('orderItems', orderItems);
            request.put('paymentMethodId', paymentMethodId);
            Flow.Interview.BuyNow_Draft buynowFlow = new Flow.Interview.BuyNow_Draft(request);
            buynowFlow.start();
            res.put('url', Site.getPathPrefix()+'/');
            return KiwiUtils.prepareResponseWithMap(res, false);
        } catch (Exception e) {
            System.debug(e);
            res.put('url', Site.getPathPrefix()+'/');
            res.put('cause', e.getCause());
            res.put('message', e.getMessage());
            return KiwiUtils.prepareResponseWithMap(res, true);
        }
    }

    @AuraEnabled
    public static Map<String, Object> createDraftOrder(Map<String, Object> kiwiOrderRequestMap, List<String> kiwiOrderItemRequestList, String salesRepId) {
        Map<String, Object> res = new Map<String, Object>();
        try {
            KiwiOrderRequest kiwiOrderRequest = convertMapToKiwiOrderRequest(kiwiOrderRequestMap);
            Order orderObj = createOrderObject(kiwiOrderRequest);
            List<OrderItem> orderItems = createOrderItems(kiwiOrderItemRequestList);
            Id orderId = insertDraftOrderData(orderObj, orderItems, salesRepId);
            res.put('url', Site.getPathPrefix()+'/');
            res.put('orderId', orderId);
            return KiwiUtils.prepareResponseWithMap(res, false);
        } catch (Exception e) {
            System.debug(e);
            System.debug(e.getStackTraceString());
            res.put('url', Site.getPathPrefix()+'/');
            res.put('cause', e.getCause());
            res.put('message', e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(Cacheable=true)
    public static Map<String, Object> getSecurityDepositProduct(Integer creditClass) {
        Map<String, Object> res = new Map<String, Object>();
        String productName;
        try {
            switch on creditClass {
                when 2 {
                    productName = 'Deposit 200';
                }
                when 3 {
                    productName = 'Deposit 400';
                }
            }
            PricebookEntry pbe = [
                    SELECT Id, UnitPrice, Product2Id, Product2.Name, Product2.Description, Product2.Product_Image_Link__c,
                            Product2.Product_Extra_Description__c, Product2.Product_Recommended__c, Product2.Product_CTA__c,
                            ProductSellingModel.Status, ProductSellingModel.SellingModelType, ProductSellingModel.Name
                    FROM PricebookEntry
                    WHERE Name = :productName
                    AND ProductSellingModel.Status = 'Active'
                    AND Product2.IsActive = TRUE
                    ORDER BY UnitPrice
                    LIMIT 1
            ];
            res.put('productInfo', pbe);
            return KiwiUtils.prepareResponseWithMap(res, false);
        } catch (Exception e) {
            System.debug(e);
            res.put('cause', e.getCause());
            res.put('message', e.getMessage());
            return KiwiUtils.prepareResponseWithMap(res, true);
        }
    }

    @TestVisible
    private static Id insertDraftOrderData(Order order, List<OrderItem> orderItems, String salesRepId) {
        insert order;
        AppUsageAssignment appUsageAssignment = new AppUsageAssignment(RecordId = order.Id, AppUsageType='SubscriptionManagement');
        OrderAction orderAction = new OrderAction(Type='New Sale', OrderId=order.Id);
        insert appUsageAssignment;
        insert orderAction;
        List<OrderItem> orderItemsToInsert = assignOrderAndOrderActionId(orderItems, order.Id, orderAction.Id);
        insert orderItemsToInsert;
        List<OrderItemTaxLineItem> orderItemTaxLineItems = createOrderItemTaxLineItems(orderItemsToInsert);
        insert orderItemTaxLineItems;
        if (salesRepId != null) assignSalesRepId(order, salesRepId);
        return order.Id;
    }

    private static List<OrderItem> assignOrderAndOrderActionId(List<OrderItem> orderItems, Id orderId, Id orderActionId) {
        List<OrderItem> res = new List<OrderItem>();
        for (OrderItem orderItem : orderItems) {
            orderItem.OrderActionId = orderActionId;
            orderItem.OrderId = orderId;
            res.add(orderItem);
        }
        return res;
    }

    private static List<OrderItemTaxLineItem> createOrderItemTaxLineItems(List<OrderItem> orderItems) {
        List<OrderItemTaxLineItem> res = new List<OrderItemTaxLineItem>();
        for (OrderItem orderItem : orderItems) {
            Decimal unitPrice = orderItem.UnitPrice;
            Decimal estimatedTax = unitPrice * 0.24; // 24% tax calculation
            estimatedTax = estimatedTax.setScale(2);
            OrderItemTaxLineItem orderItemTaxLineItem = new OrderItemTaxLineItem(
                    OrderItemId = orderItem.Id,
                    Name = 'Sales Tax',
                    Amount = estimatedTax,
                    Type = 'Estimated',
                    TaxEffectiveDate = Date.today());
            res.add(orderItemTaxLineItem);
        }
        return res;
    }

    private static void assignSalesRepId(Order order, String salesRepId) {
        Map<String, Object> request = new Map<String, Object>();
        request.put('order', order);
        request.put('salesRepId', salesRepId);
        Flow.Interview.B2C_Sales_Assign_sales_rep_Id salesRepIdFlow = new Flow.Interview.B2C_Sales_Assign_sales_rep_Id(request);
        salesRepIdFlow.start();
    }

    private static PricebookEntry findPriceBookEntryById(Id id, List<PricebookEntry> pricebookEntries) {
        PricebookEntry res;
        for (PricebookEntry pricebookEntry : pricebookEntries) {
            if (pricebookEntry.Id == id) res = pricebookEntry;
        }
        return res;
    }

    @TestVisible
    private static KiwiOrderRequest convertMapToKiwiOrderRequest(Map<String, Object> req) {
        KiwiOrderRequest kiwiOrderRequest = new KiwiOrderRequest();
        kiwiOrderRequest.inboundOutbound = (String) req.get('inboundOutbound');
        kiwiOrderRequest.requiresDeposit = (Boolean) req.get('requiresDeposit');
        kiwiOrderRequest.pricebook2Id = (Id) req.get('pricebook2Id');
        kiwiOrderRequest.billToContactId = (Id) req.get('billToContactId');
        kiwiOrderRequest.accountId = (Id) req.get('accountId');
        kiwiOrderRequest.status = 'Draft';
        kiwiOrderRequest.isDepositOrder = (Boolean) req.get('isDepositOrder');
        return kiwiOrderRequest;
    }

    @TestVisible
    private static KiwiOrderItemRequest convertMapToKiwiOrderItemRequest(Map<String, Object> req) {
        KiwiOrderItemRequest kiwiOrderItemRequest = new KiwiOrderItemRequest();
        kiwiOrderItemRequest.taxTreatmentId = (String) req.get('taxTreatmentId');
        kiwiOrderItemRequest.product2Id = (Id) req.get('product2Id');
        kiwiOrderItemRequest.pricebookEntryId = (Id) req.get('pricebookEntryId');
        kiwiOrderItemRequest.discountPercentage = (Integer) req.get('discountPercentage');
        return kiwiOrderItemRequest;
    }

    @TestVisible
    private static OrderItem createOrderItemObject(PricebookEntry pbe, KiwiOrderItemRequest kiwiOrderItemRequest) {
        Decimal discountMultiplier = 1;
        if (kiwiOrderItemRequest.discountPercentage != null && kiwiOrderItemRequest.discountPercentage != 0) {
            Decimal percentageMinus100 = 100 - kiwiOrderItemRequest.discountPercentage;
            discountMultiplier = percentageMinus100.divide(100, 2);
        }
        System.debug(discountMultiplier);
        OrderItem orderItem = new OrderItem();
        orderItem.UnitPrice = pbe.UnitPrice;
        orderItem.NetUnitPrice = pbe.UnitPrice * discountMultiplier;
        orderItem.TotalLineAmount = pbe.UnitPrice * discountMultiplier;
        orderItem.Discount__c = kiwiOrderItemRequest.discountPercentage;
        orderItem.ServiceDate = Date.today();
        orderItem.PricebookEntryId = kiwiOrderItemRequest.pricebookEntryId;
        orderItem.Product2Id = kiwiOrderItemRequest.product2Id;
        orderItem.Quantity = 1;
        orderItem.TaxTreatmentId = kiwiOrderItemRequest.taxTreatmentId;
//                    orderItem.ProductSellingModelId = kiwiOrderItemRequest.productSellingModelId;
        if (pbe.ProductSellingModel.SellingModelType == 'Evergreen') {
            orderItem.BillingFrequency2 = 'Monthly';
            orderItem.PeriodBoundary = 'Anniversary';
        }
        if (pbe.ProductSellingModel.SellingModelType == 'TermDefined' || pbe.ProductSellingModel.SellingModelType == 'Termdefined') {
            orderItem.BillingFrequency2 = 'Monthly';
            orderItem.PeriodBoundary = 'Anniversary';
            orderItem.EndDate = Date.today().addYears(2);
            orderItem.PricingTermCount = 24;
        }
        System.debug(orderItem);
        return orderItem;
    }

    @TestVisible
    private static Order createOrderObject(KiwiOrderRequest kiwiOrderRequest) {
        Order orderObj = new Order();
        orderObj.AccountId = kiwiOrderRequest.accountId;
        orderObj.BillToContactId = kiwiOrderRequest.billToContactId;
        orderObj.Pricebook2Id = kiwiOrderRequest.pricebook2Id;
        orderObj.EffectiveDate = Date.today();
        orderObj.Requires_Deposit__c = kiwiOrderRequest.requiresDeposit;
        orderObj.Inbound_Outbound__c = kiwiOrderRequest.inboundOutbound;
        orderObj.Deposit_Order__c = Boolean.valueOf(kiwiOrderRequest.isDepositOrder);
        orderObj.Status = 'Draft';
        return orderObj;
    }

    @TestVisible
    private static List<OrderItem> createOrderItems(List<String> kiwiOrderItemRequestList) {
        List<KiwiOrderItemRequest> kiwiOrderItemRequests = new List<KiwiOrderItemRequest>();
        for (String kiwiOrderItemRequest : kiwiOrderItemRequestList) {
            Map<String, Object> mapVals = (Map<String, Object>) JSON.deserializeUntyped(kiwiOrderItemRequest);
            kiwiOrderItemRequests.add(convertMapToKiwiOrderItemRequest(mapVals));
        }
        List<Id> orderItemIds = new List<Id>();
        for (KiwiOrderItemRequest kiwiOrderItemRequest : kiwiOrderItemRequests) {
            orderItemIds.add(kiwiOrderItemRequest.pricebookEntryId);
        }
        List<PricebookEntry> pricebookEntries = [SELECT UnitPrice, ProductSellingModel.SellingModelType FROM PricebookEntry WHERE Id IN :orderItemIds];
        List<OrderItem> orderItems = new List<OrderItem>();
        for (KiwiOrderItemRequest kiwiOrderItemRequest : kiwiOrderItemRequests) {
            PricebookEntry pbe = findPriceBookEntryById(kiwiOrderItemRequest.pricebookEntryId, pricebookEntries);
            if (pbe != null) {
                orderItems.add(createOrderItemObject(pbe, kiwiOrderItemRequest));
            }
        }
        return orderItems;
    }

}