/*
    ***********************************************************************
    Name        : UTIL_GenerateToken
    Author      : Ashish Kumar Singh, Fluido AB
    CreatedDate : December 12, 2022
    Description : Utility class Token Generation
    ***********************************************************************
*/
public class UTIL_GenerateToken{
      
      public static String generateTokenRopo(MyRopoApp__c myRopo){
          AcctokenDTO dto = new AcctokenDTO();            
          String reqbody = UTIL_GenerateToken.getJSONBody(myRopo);
          Http h = new Http();
          HttpRequest req = new HttpRequest();
              req.setBody(reqbody);
              req.setMethod(UTIL_Constants.REST_METHOD_POST);
              req.setEndpoint(myRopo.TokenEndpoint__c);
              req.setHeader(UTIL_Constants.REST_CONTENT_HEADER, UTIL_Constants.REST_CONTENT_HEADER_JSON);
              req.setHeader(UTIL_Constants.REST_CONTENT_HEADER_ACCEPT, UTIL_Constants.REST_CONTENT_HEADER_JSON);
              req.setTimeout(UTIL_Constants.REST_TIMEOUT);
          HttpResponse res = h.send(req);
          if(res.getStatusCode() == 201){
              dto = (AcctokenDTO)JSON.deserialize(res.getBody(), AcctokenDTO.class); 
          }
          system.debug('====code===='+dto.token);
       return dto.token;   
      }
      public static string getJSONBody(MyRopoApp__c myRopo){
          JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();     
            gen.writeStringField(UTIL_Constants.ROPO_CID, myRopo.CID__c);
            gen.writeStringField(UTIL_Constants.ROPO_APICODE, myRopo.Apicode__c);
            gen.writeEndObject();
        return gen.getAsString();   
      }
      public class AcctokenDTO {
          public String token { get; set; }
     }
}