trigger ContactPointEmailTrigger on ContactPointEmail (before insert, before update) {
    vosh.TriggerHandler.execute(Schema.ContactPointEmail.SObjectType);
}