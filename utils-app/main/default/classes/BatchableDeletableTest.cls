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

        Database.executeBatch(new BatchableDeletable('SELECT Id FROM Account', true));

        Test.stopTest();

        System.assertEquals(0, Database.countQuery(q));
    }
}
