/*
    ***********************************************************************
    Name        : UTIL_ExceptionLogsHandler
    Author      : Ashish Kumar Singh, Fluido AB
    CreatedDate : December 29, 2022
    Description : Utility Class for Exception Logging and handling
    ***********************************************************************
*/
Public Class UTIL_ExceptionLogsHandler{
    public static void buildExceptionLogs(String className, String methodName, String objectName, String recordId, Exception exceptionDetail, String operation){
        
        Exception__c excp = new Exception__c();
        excp.Class__c = className;
        excp.Method__c = methodName;
        excp.Object__c = objectName;
        excp.RecordId__c = recordId;
        excp.ExceptionDetails__c = String.ValueOf(exceptionDetail);
        excp.Operation__c = operation;
        
        insert excp;
    }
}