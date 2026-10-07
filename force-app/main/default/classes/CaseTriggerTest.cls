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

        Test.setMock(
            HttpCalloutMock.class,
            new GeminiHttpMock()
        );

        Case newCase = new Case(
            Subject = 'Test SLA',
            Description = 'Customer cannot access the system.',
            Status = 'New',
            Origin = 'Web',
            AI_Priority__c = 'High',
            AI_Processed__c = true
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

        Test.setMock(
            HttpCalloutMock.class,
            new GeminiHttpMock()
        );

        Case newCase = new Case(
            Subject = 'Priority change test',
            Status = 'New',
            Origin = 'Web',
            AI_Priority__c = 'High',
            AI_Processed__c = true
        );

        insert newCase;

        Case beforeUpdate = [
            SELECT AI_Priority__c, SLA_Deadline__c
            FROM Case
            WHERE Id = :newCase.Id
        ];

        Datetime highDeadline =
            beforeUpdate.SLA_Deadline__c;

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

    @isTest
    static void shouldAnalyzeCaseWithAI() {

        Test.setMock(
            HttpCalloutMock.class,
            new GeminiHttpMock()
        );

        Case newCase = new Case(
            Subject = 'Cannot access system',
            Description = 'Customer cannot login to the system.',
            Status = 'New',
            Origin = 'Web',
            AI_Processed__c = false
        );

        Test.startTest();

        insert newCase;

        Test.stopTest();

        Case processedCase = [
            SELECT AI_Category__c,
                   AI_Priority__c,
                   AI_Summary__c,
                   AI_Processed__c,
                   SLA_Deadline__c
            FROM Case
            WHERE Id = :newCase.Id
        ];

        System.assertEquals(
            'Technical',
            processedCase.AI_Category__c
        );

        System.assertEquals(
            'Critical',
            processedCase.AI_Priority__c
        );

        System.assertEquals(
            'Customer cannot access the system.',
            processedCase.AI_Summary__c
        );

        System.assertEquals(
            true,
            processedCase.AI_Processed__c
        );

        System.assertNotEquals(
            null,
            processedCase.SLA_Deadline__c,
            'AI priority should trigger SLA calculation'
        );
    }
}