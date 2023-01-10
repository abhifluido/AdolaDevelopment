@isTest
global with sharing class KiwiControllerMock implements HttpCalloutMock {
  global HttpResponse respond(HttpRequest request) {
    // Create a fake response
    HttpResponse response = new HttpResponse();
    response.setHeader('Content-Type', 'application/json');
    response.setBody('{"valid_captcha":true,"location":"Saatavuusalue:HelsinkiX4","url":"https://valonnopea.tayskuitu.fi/tilaus/ennakko-0-0-1?alue=HelsinkiX4"}');
    response.setStatusCode(200);
    return response;
  }
}