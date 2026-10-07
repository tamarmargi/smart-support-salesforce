public with sharing class GeminiService {

    public class AnalysisResult {
        public String category;
        public String priority;
        public String summary;
    }

    public static AnalysisResult analyzeCase(
        String subject,
        String description
    ) {
        HttpRequest request = new HttpRequest();

        request.setEndpoint(
            'callout:Gemini_API/v1beta/models/gemini-3.8-flash:generateContent'
        );
        request.setMethod('POST');
        request.setTimeout(30000);
        request.setHeader('Content-Type', 'application/json');

        String prompt =
            'Analyze this customer support case. ' +
            'Return ONLY valid JSON with this exact structure: ' +
            '{"category":"Technical|Billing|Account|General",' +
            '"priority":"Low|Medium|High|Critical",' +
            '"summary":"short summary"}.' +
            '\n\nSubject: ' + subject +
            '\nDescription: ' + description;

        Map<String, Object> body = new Map<String, Object>{
            'contents' => new List<Object>{
                new Map<String, Object>{
                    'parts' => new List<Object>{
                        new Map<String, Object>{
                            'text' => prompt
                        }
                    }
                }
            }
        };

        request.setBody(JSON.serialize(body));

        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() != 200) {
            throw new CalloutException(
                'Gemini API failed. Status: ' +
                response.getStatusCode() +
                ', Body: ' +
                response.getBody()
            );
        }

        Map<String, Object> responseBody =
            (Map<String, Object>) JSON.deserializeUntyped(
                response.getBody()
            );

        List<Object> candidates =
            (List<Object>) responseBody.get('candidates');

        Map<String, Object> firstCandidate =
            (Map<String, Object>) candidates[0];

        Map<String, Object> content =
            (Map<String, Object>) firstCandidate.get('content');

        List<Object> parts =
            (List<Object>) content.get('parts');

        Map<String, Object> firstPart =
            (Map<String, Object>) parts[0];

        String aiText =
            (String) firstPart.get('text');

        aiText = aiText
            .replace('```json', '')
            .replace('```', '')
            .trim();

        return (AnalysisResult) JSON.deserialize(
            aiText,
            AnalysisResult.class
        );
    }
}