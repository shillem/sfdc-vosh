@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class RecordTypeInvocableProcessor {
  global class Request {
    @InvocableVariable(required=true label='Record Id')
    global Id recordId;
    @InvocableVariable(required=true label='Record Type Name')
    global String recordTypeName;
  }

  @InvocableMethod(
    label='Set Record Type From Name'
    description='Maps record types by their developer name'
  )
  global static void execute(List<Request> requests) {
    Map<String, Id> recordTypeIds = new Map<String, Id>();
    List<SObject> records = new List<SObject>();

    for (Request req : requests) {
      Schema.SObjectType type = req.recordId.getSObjectType();
      String key = type + req.recordTypeName;
      Id recordTypeId = recordTypeIds.get(key);

      if (recordTypeId == null) {
        Schema.RecordTypeInfo info = Describer.getInstance()
          .getObjectDescribe(type)
          .getRecordTypeInfosByDeveloperName()
          .get(req.recordTypeName);

        if (info == null) {
          continue;
        }

        recordTypeId = info.getRecordTypeId();

        recordTypeIds.put(key, recordTypeId);
      }

      SObject obj = type.newSObject(req.recordId);

      obj.put('RecordTypeId', recordTypeId);

      records.add(obj);
    }

    if (!records.isEmpty()) {
      update records;
    }
  }
}
