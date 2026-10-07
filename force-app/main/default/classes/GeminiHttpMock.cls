@isTest
public class GeminiHttpMock implements HttpCalloutMock {

    public HTTPResponse respond(HTTPRequest request) {

        HttpResponse response = new HttpResponse();

        response.setStatusCode(200);
        response.setHeader('Content-Type', 'application/json');

        response.setBody(
            '{"candidates":[' +
                '{"content":{' +
                    '"parts":[' +
                        '{"text":"{\\"category\\":\\"Technical\\",' +
                        '\\"priority\\":\\"Critical\\",' +
                        '\\"summary\\":\\"Customer cannot access the system.\\"}"}' +
                    ']' +
                '}}' +
            ']}'
        );

        return response;
    }
}