trigger CaseTrigger on Case (
    before insert,
    before update,
    after insert
) {

    if (Trigger.isBefore && Trigger.isInsert) {
        CaseTriggerHandler.beforeInsert(Trigger.new);
    }

    if (Trigger.isBefore && Trigger.isUpdate) {
        CaseTriggerHandler.beforeUpdate(
            Trigger.new,
            Trigger.oldMap
        );
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        CaseTriggerHandler.afterInsert(Trigger.new);
    }
}