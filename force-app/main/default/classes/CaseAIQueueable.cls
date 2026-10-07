public with sharing class CaseAIQueueable
    implements Queueable, Database.AllowsCallouts {

    private Set<Id> caseIds;

    public CaseAIQueueable(Set<Id> caseIds) {
        this.caseIds = caseIds;
    }

    public void execute(QueueableContext context) {

        List<Case> casesToProcess = [
            SELECT Id, Subject, Description,
                   AI_Category__c,
                   AI_Priority__c,
                   AI_Summary__c,
                   AI_Processed__c
            FROM Case
            WHERE Id IN :caseIds
            AND AI_Processed__c = false
        ];

        List<Case> casesToUpdate = new List<Case>();

        for (Case caseRecord : casesToProcess) {

            try {
                GeminiService.AnalysisResult result =
                    GeminiService.analyzeCase(
                        caseRecord.Subject,
                        caseRecord.Description
                    );

                caseRecord.AI_Category__c = result.category;
                caseRecord.AI_Priority__c = result.priority;
                caseRecord.AI_Summary__c = result.summary;
                caseRecord.AI_Processed__c = true;

                casesToUpdate.add(caseRecord);

            } catch (Exception e) {
                System.debug(
                    'AI processing failed for Case ' +
                    caseRecord.Id +
                    ': ' +
                    e.getMessage()
                );
            }
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }
}