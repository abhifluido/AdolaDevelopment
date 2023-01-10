/**
 * Created by bartubazna on 9.1.2023.
 */

public with sharing class KiwiInvoiceController {


    private static List<Map<String, Object>> getInvoicesWithLinks(Id accountId, List<Invoice> invoices) {
        List<Map<String, Object>> res = new List<Map<String, Object>>();
        // Get place of use from Account.Address__r
        Account account = [SELECT Id, (SELECT Address__Street__s FROM Account.Address__r) FROM Account WHERE Id = :accountId];
        String street = account.Address__r != null ? account.Address__r[0].Address__Street__s : '';
        List<Id> invoiceIds = new List<Id>();
        List<Id> contentDocumentIds = new List<Id>();
        for (Invoice invoice : invoices) {
            invoiceIds.add(invoice.Id);
        }
        if (invoiceIds == null || invoiceIds.size() == 0) return res;
        List<ContentDocumentLink> contentDocumentLinks = [SELECT LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :invoiceIds];
        for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
            contentDocumentIds.add(contentDocumentLink.ContentDocumentId);
        }
        if (contentDocumentIds == null || contentDocumentIds.size() == 0) return res;
        List<ContentVersion> contentVersions = [SELECT FIELDS(STANDARD) FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds];
        // Map invoice to content version ID for download possibility
        for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
            Map<String, Object> infoMap = new Map<String, Object>();
            Id invoiceId = contentDocumentLink.LinkedEntityId;
            Id contentVersionId = findContentVersionId(contentVersions, contentDocumentLink.ContentDocumentId);
            Invoice invoice = findInvoice(invoices, invoiceId);
            infoMap.put('invoice', invoice);
            infoMap.put('contentVersionId', contentVersionId);
            infoMap.put('street', street);
            res.add(infoMap);
        }
        return res;
    }

    @TestVisible
    private static Id findContentVersionId(List<ContentVersion> contentVersions, Id contentDocumentId) {
        Id res;
        for (ContentVersion contentVersion : contentVersions) {
            if (contentVersion.ContentDocumentId == contentDocumentId) res = contentVersion.Id;
        }
        return res;
    }

    @TestVisible
    private static Invoice findInvoice(List<Invoice> invoices, Id invoiceId) {
        Invoice res = new Invoice();
        for (Invoice invoice : invoices) {
            if (invoice.Id == invoiceId) res = invoice;
        }
        return res;
    }

    @AuraEnabled(Cacheable=true)
    public static Map<String, Object> getInvoices(Id accountId) {
        Map<String, Object> res = new Map<String, Object>();
        try {
            List<Invoice> invoices = [SELECT Status, TotalAmountWithTax, InvoiceDate, InvoiceNumber, RC_StatusText__c FROM Invoice WHERE BillingAccountId = :accountId];
            List<Map<String, Object>> infoList = getInvoicesWithLinks(accountId, invoices);
            res.put('invoiceInformation', infoList);
            return KiwiUtils.prepareResponseWithMap(res, false);
        } catch (Exception e) {
            res.put('cause', e.getCause());
            res.put('message', e.getMessage());
            return KiwiUtils.prepareResponseWithMap(res, true);
        }
    }

}