@isTest(isParallel=true)
public class RecordTypeInvocableProcessorTest {
  @isTest
  static void recordTypeInvocableProcessor() {
    Schema.Account acc = new Schema.Account(Name = 'Test');

    insert acc;

    Test.startTest();

    RecordTypeInvocableProcessor.Request req = new RecordTypeInvocableProcessor.Request();

    req.recordId = acc.Id;
    req.recordTypeName = 'Test';

    RecordTypeInvocableProcessor.execute(new List<RecordTypeInvocableProcessor.Request>{ req });

    Test.stopTest();

    System.assertEquals(acc.Id, [SELECT Id FROM Account WHERE Name = :acc.Name LIMIT 1].Id);
  }
}
