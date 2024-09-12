@isTest(isParallel=true)
public class SchemaUtilsTest {
  @isTest
  static void differ() {
    final List<Schema.SObjectField> sof = new List<Schema.SObjectField>{
      Schema.Account.Name,
      Schema.Account.Description
    };
    final List<String> sofn = new List<String>();

    for (Schema.SObjectField f : sof) {
      sofn.add(String.valueOf(f));
    }

    final Schema.Account acct1 = new Schema.Account(Name = 'Test1', Description = 'Test1');
    final Schema.Account acct2 = new Schema.Account(Name = 'Test2', Description = 'Test2');

    Assert.isTrue(SchemaUtils.differAll(acct1, acct2, sofn));
    Assert.isTrue(SchemaUtils.differAll(acct1, acct2, sof));
    Assert.isTrue(SchemaUtils.differAny(acct1, acct2, sofn));
    Assert.isTrue(SchemaUtils.differAny(acct1, acct2, sof));

    acct2.Name = 'Test1';
    acct2.Description = 'Test1';

    Assert.isFalse(SchemaUtils.differAll(acct1, acct2, sofn));
    Assert.isFalse(SchemaUtils.differAll(acct1, acct2, sof));
    Assert.isFalse(SchemaUtils.differAny(acct1, acct2, sofn));
    Assert.isFalse(SchemaUtils.differAny(acct1, acct2, sof));
  }
}
