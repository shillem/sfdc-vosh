trigger CmsmTrigger on Campaign(after insert) {
  TriggerHandler.execute(Schema.Campaign.SObjectType);
}
