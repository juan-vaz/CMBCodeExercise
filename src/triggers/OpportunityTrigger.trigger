trigger OpportunityTrigger on Opportunity (after update, before delete) {
    if(Trigger.isAfter && Trigger.isUpdate){
        new Opportunities(Trigger.new).onAfterUpdate(Trigger.oldMap);
    }
    if(Trigger.isBefore && Trigger.isDelete){
        new Opportunities(Trigger.old).onBeforeDelete();
    }
}