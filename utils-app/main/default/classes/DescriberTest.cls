@isTest(isParallel=true)
public class DescriberTest {
  @isTest
  static void basic() {
    Describer describ = Describer.getInstance();
    Schema.SObjectType accountType = Schema.Account.SObjectType;

    Schema.DescribeSObjectResult accResult1 = describ.getObjectDescribe(accountType);
    Schema.DescribeSObjectResult accResult2 = describ.getObjectDescribe(
      String.valueOf(accountType)
    );

    System.assertEquals(accResult1.getSObjectType(), accResult2.getSObjectType());

    Schema.SObjectField accountField = Schema.Account.Name;

    System.assertEquals(
      accountField,
      describ.getObjectFieldMap(accountType).get(String.valueOf(accountField))
    );

    Schema.DescribeFieldResult fieldResult = describ.getFieldDescribe(accountField);

    System.assertEquals(accountField, fieldResult.getSObjectField());
    System.assertEquals(accountField, describ.fieldValueOf('Account.Name'));
  }

  @isTest
  static void features() {
    //IsPersonAccount
    Describer describ = Describer.getInstance();

    System.assertEquals(
      Schema.SObjectType.Account.fields.getMap().containsKey('IsPersonAccount'),
      describ.isPersonAccountEnabled()
    );
  }

  @isTest
  static void relatedObject() {
    Schema.Account acct = (Schema.Account) new TestUtils.AccountMaker()
      .setName('Dummy')
      .set(Schema.Account.Phone, '0000')
      .setCount(1)
      .make()
      .get(0);

    Schema.Opportunity oppt = (Schema.Opportunity) new TestUtils.OpportunityMaker()
      .setAccountId(acct.Id)
      .setActiveStageName()
      .setName('Dummy')
      .setCloseDate(Date.today().addDays(1))
      .setCount(1)
      .make()
      .get(0);

    oppt = [SELECT Account.Owner.Name FROM Opportunity WHERE Id = :oppt.Id];

    Describer describ = Describer.getInstance();

    System.assertEquals(
      Schema.User.SObjectType,
      describ.getRelatedObject(oppt, 'Account.Owner.Name').getSObjectType()
    );

    System.assert(
      String.isNotEmpty((String) describ.getRelatedObjectValue(oppt, 'Account.Owner.Name'))
    );
  }

  @isTest
  static void relationship() {
    Describer describ = Describer.getInstance();

    System.assertEquals(
      'Contacts',
      describ.getObjectRelationshipName(Schema.Account.SObjectType, Schema.Contact.SObjectType)
    );
  }
}
