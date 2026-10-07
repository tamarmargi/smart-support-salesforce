@isTest
private class CaseTriggerTest {

    @TestSetup
    static void setupData() {
        insert new List<SLA_Rule__c>{
            new SLA_Rule__c(
                Name = 'High SLA',
                Priority__c = 'High',
                Response_Time_Hours__c = 2,
                Resolution_Time_Hours__c = 8
            ),
            new SLA_Rule__c(
                Name = 'Critical SLA',
                Priority__c = 'Critical',
                Response_Time_Hours__c = 1,
                Resolution_Time_Hours__c = 4
            )
        };
    }

    @isTest
    static void shouldSetDeadlineWhenCaseIsCreated() {

        Case newCase = new Case(
            Subject = 'Test SLA',
            Status = 'New',
            Origin = 'Web',
            AI_Priority__c = 'High'
        );

        Test.startTest();
        insert newCase;
        Test.stopTest();

        Case savedCase = [
            SELECT AI_Priority__c, SLA_Deadline__c
            FROM Case
            WHERE Id = :newCase.Id
        ];

        System.assertEquals(
            'High',
            savedCase.AI_Priority__c
        );

        System.assertNotEquals(
            null,
            savedCase.SLA_Deadline__c,
            'SLA Deadline should be calculated'
        );
    }

    @isTest
    static void shouldRecalculateDeadlineWhenPriorityChanges() {

        Case newCase = new Case(
            Subject = 'Priority change test',
            Status = 'New',
            Origin = 'Web',
            AI_Priority__c = 'High'
        );

        insert newCase;

        Case beforeUpdate = [
            SELECT AI_Priority__c, SLA_Deadline__c
            FROM Case
            WHERE Id = :newCase.Id
        ];

        Datetime highDeadline = beforeUpdate.SLA_Deadline__c;

        Test.startTest();

        beforeUpdate.AI_Priority__c = 'Critical';
        update beforeUpdate;

        Test.stopTest();

        Case afterUpdate = [
            SELECT AI_Priority__c, SLA_Deadline__c
            FROM Case
            WHERE Id = :newCase.Id
        ];

        System.assertEquals(
            'Critical',
            afterUpdate.AI_Priority__c
        );

        System.assertNotEquals(
            highDeadline,
            afterUpdate.SLA_Deadline__c,
            'Deadline should change when AI Priority changes'
        );

        System.assert(
            afterUpdate.SLA_Deadline__c < highDeadline,
            'Critical SLA should have an earlier deadline than High SLA'
        );
    }
}