@isTest(isParallel=true)
public class CollectionsTest {
  @isTest
  static void flattening() {
    try {
      Collections.flatten(new List<List<Object>>());

      System.assert(false, 'It should have thrown an exception because of empty list');
    } catch (IllegalArgumentException e) {
      System.assertEquals('Lists cannot be empty', e.getMessage());
    }

    final TestUtils.AccountMaker maker = (TestUtils.AccountMaker) new TestUtils.AccountMaker()
      .enumerate(Schema.Account.Name)
      .setCount(3)
      .setAutoInsert(false);

    final List<Schema.Account> accts1 = maker.setName('First').make();
    final List<Schema.Account> accts2 = maker.setName('Second').make();

    final Map<String, List<Schema.Account>> accts = new Map<String, List<Schema.Account>>{
      'First' => accts1,
      'Second' => accts2
    };

    List<Schema.Account> flattenedAccounts = (List<Schema.Account>) Collections.flatten(
      accts.values()
    );

    System.assertEquals(6, flattenedAccounts.size());
  }

  @isTest
  static void subListing() {
    final List<Integer> values = new List<Integer>{ 1, 2, 3, 4, 5 };

    try {
      Collections.subList(values, -1, 1);

      System.assert(false, 'It should have failed on start index');
    } catch (IllegalArgumentException e) {
      System.assertEquals('Start index cannot be lower than 0', e.getMessage());
    }

    try {
      Collections.subList(values, 1, 0);

      System.assert(false, 'It should have failed on start index');
    } catch (IllegalArgumentException e) {
      System.assertEquals('Start index cannot be greater than end index', e.getMessage());
    }

    try {
      Collections.subList(values, 0, 10);

      System.assert(false, 'It should have failed on end index');
    } catch (IllegalArgumentException e) {
      System.assertEquals('End index cannot be greater than the list size - 1', e.getMessage());
    }

    System.assertEquals(new List<Integer>{ 2, 3, 4 }, Collections.subList(values, 1, 3));
  }
}
