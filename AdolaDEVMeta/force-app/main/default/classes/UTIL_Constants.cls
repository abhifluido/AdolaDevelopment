/*
    ***********************************************************************
    Name        : UTIL_Constants
    Author      : Ashish Kumar Singh, Fluido AB
    CreatedDate : December 12, 2022
    Description : Utility class to hold Reusable Constants
    ***********************************************************************
*/
Public Class UTIL_Constants{
    public static final string ADD_STATUS_AVAILABLE = 'Available';
    public static final string ADD_STATUS_UNAVAILABLE = 'Unavailable';
    
    public static final String ROPO_INVPDF_ENDPOINT = 'https://rc.ropo24.fi/rest/jobs/pdf?billnum=';
    public static final String ROPO_SENDINVOICE_ENDPOINT = 'https://rc.ropo24.fi/rest/jobs';
    public static final String REST_METHOD_GET = 'GET';
    public static final String REST_METHOD_POST = 'POST';
    public static final String REST_CONTENT_HEADER = 'Content-Type';
    public static final String REST_CONTENT_HEADER_ACCEPT = 'Accept';
    public static final String REST_CONTENT_HEADER_AUTH = 'Authorization';
    public static final String REST_CONTENT_HEADER_BEARER = 'Bearer ';
    public static final String REST_CONTENT_HEADER_PDF = 'application/pdf';
    public static final String REST_CONTENT_HEADER_JSON = 'application/json';
    public static final Integer REST_TIMEOUT = 120000;
    public static final Integer REST_STATUS_CODE_200 = 200;
    public static final Integer REST_STATUS_CODE_201 = 201;
    public static final String ROPO_CID ='cid';
    public static final String ROPO_APICODE ='apicode';
    public static final String CALLING_FROM_UI ='UI';
    public static final String CALLING_FROM_BATCH ='batch';
}