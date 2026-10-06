public with sharing class SLAService {

    public static void setSLADeadlines(List<Case> cases) {
        Set<String> priorities = new Set<String>();

        // Collect all priorities from the Cases
        for (Case caseRecord : cases) {
            if (caseRecord.AI_Priority__c != null) {
                priorities.add(caseRecord.AI_Priority__c);
            }
        }

        if (priorities.isEmpty()) {
            return;
        }

        // Get the relevant SLA rules in a single query
        List<SLA_Rule__c> rules = [
            SELECT Priority__c, Resolution_Time_Hours__c
            FROM SLA_Rule__c
            WHERE Priority__c IN :priorities
        ];

        // Map each priority to its SLA rule
        Map<String, SLA_Rule__c> rulesByPriority =
            new Map<String, SLA_Rule__c>();

        for (SLA_Rule__c rule : rules) {
            rulesByPriority.put(rule.Priority__c, rule);
        }

        // Calculate the deadline for each Case
        for (Case caseRecord : cases) {
            SLA_Rule__c rule =
                rulesByPriority.get(caseRecord.AI_Priority__c);

            if (rule != null && rule.Resolution_Time_Hours__c != null) {
                Integer hours =
                    rule.Resolution_Time_Hours__c.intValue();

                caseRecord.SLA_Deadline__c =
                    System.now().addHours(hours);
            }
        }
    }
}