public with sharing class CaseTriggerHandler {

    public static void beforeInsert(List<Case> newCases) {
        SLAService.setSLADeadlines(newCases);
    }

    public static void beforeUpdate(
        List<Case> newCases,
        Map<Id, Case> oldCases
    ) {
        List<Case> casesToRecalculate = new List<Case>();

        for (Case newCase : newCases) {
            Case oldCase = oldCases.get(newCase.Id);

            if (newCase.AI_Priority__c != oldCase.AI_Priority__c) {
                casesToRecalculate.add(newCase);
            }
        }

        if (!casesToRecalculate.isEmpty()) {
            SLAService.setSLADeadlines(casesToRecalculate);
        }
    }

    public static void afterInsert(List<Case> newCases) {
        Set<Id> caseIds = new Set<Id>();

        for (Case caseRecord : newCases) {
            if (!caseRecord.AI_Processed__c) {
                caseIds.add(caseRecord.Id);
            }
        }

        if (!caseIds.isEmpty()) {
            System.enqueueJob(
                new CaseAIQueueable(caseIds)
            );
        }
    }
}