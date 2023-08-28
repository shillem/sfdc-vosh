@isTest(isParallel=true)
public class BatchableDeletableTest {
  @isTest
  static void batchableDeletable() {
    List<Schema.Account> acct = (List<Schema.Account>) new TestUtils.AccountMaker()
      .setName('Dummy')
      .setCount(3)
      .make();

    String q = 'SELECT COUNT() FROM Account';

    System.assertEquals(3, Database.countQuery(q));

    Test.startTest();

    final BatchableDeletable.Parameters params = new BatchableDeletable.Parameters();
    params.query = 'SELECT Id FROM Account';
    params.emptyRecycleBin = true;

    Database.executeBatch(new BatchableDeletable(JSON.serialize(params)));

    Test.stopTest();

    System.assertEquals(0, Database.countQuery(q));
  }
}
