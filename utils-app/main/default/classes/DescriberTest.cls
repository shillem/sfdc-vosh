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
  static void displayFamilies() {
    System.assertEquals(
      Describer.DisplayFamily.BOOL,
      Describer.getDisplayFamily(Schema.DisplayType.BOOLEAN)
    );
    System.assertEquals(
      Describer.DisplayFamily.CHOICE,
      Describer.getDisplayFamily(Schema.DisplayType.PICKLIST)
    );
    System.assertEquals(
      Describer.DisplayFamily.NUM,
      Describer.getDisplayFamily(Schema.DisplayType.PERCENT)
    );
    System.assertEquals(
      Describer.DisplayFamily.TEXT,
      Describer.getDisplayFamily(Schema.DisplayType.STRING)
    );
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

    try {
      describ.getRelatedObjectValue(oppt, 'Contact.Owner.Name');

      System.assert(false, 'It should have thrown an SObjectException');
    } catch (System.SObjectException e) {
      System.assert(e.getMessage().contains('Invalid relationship'), e.getMessage());
    }
  }

  @isTest
  static void relationship() {
    Describer describ = Describer.getInstance();

    System.assertEquals(
      'Contacts',
      describ.getObjectRelationshipName(Schema.Account.SObjectType, Schema.Contact.SObjectType)
    );

    try {
      describ.getObjectRelationshipName(Schema.Contact.SObjectType, Schema.Account.SObjectType);

      System.assert(false, 'It should have thrown an IllegalArgumentException');
    } catch (IllegalArgumentException e) {
      System.assert(e.getMessage().contains('does not have a relationship with'), e.getMessage());
    }
  }

  @isTest
  static void traverseWithSObjectType() {
    Describer describ = Describer.getInstance();

    List<Describer.Hop> hops = describ.traverse(Schema.Contact.SObjectType, 'Account.Owner.Name');

    System.assertEquals(3, hops.size());
    System.assert(
      hops[0].getType() == Schema.Contact.SObjectType &&
      hops[0].getField() == Schema.Contact.AccountId,
      hops
    );
    System.assert(
      hops[1].getType() == Schema.Account.SObjectType &&
      hops[1].getField() == Schema.Account.OwnerId
    );
    System.assert(
      hops[2].getType() == Schema.User.SObjectType &&
      hops[2].getField() == Schema.User.Name
    );

    try {
      describ.traverse(Schema.Account.SObjectType, 'Contact.Owner.Name');

      System.assert(false, 'It should have thrown an IllegalArgumentException');
    } catch (System.IllegalArgumentException e) {
      System.assert(e.getMessage().contains('not a valid reference field name'), e.getMessage());
    }

    hops = describ.traverse(Schema.Account.SObjectType, 'OwnerId');

    System.assertEquals(2, hops.size(), hops);
    System.assert(
      hops[0].getType() == Schema.Account.SObjectType &&
      hops[0].getField() == Schema.Account.OwnerId
    );
    System.assert(hops[1].getType() == Schema.User.SObjectType && hops[1].getField() == null, hops);
  }

  @isTest
  static void traverseWithSyntaxOnly() {
    Describer describ = Describer.getInstance();

    List<Describer.Hop> hops = describ.traverse('Account.Owner.Name');

    System.assertEquals(2, hops.size());
    System.assert(
      hops[0].getType() == Schema.Account.SObjectType &&
      hops[0].getField() == Schema.Account.OwnerId
    );
    System.assert(
      hops[1].getType() == Schema.User.SObjectType &&
      hops[1].getField() == Schema.User.Name
    );

    try {
      describ.traverse('Accountz.Owner.Name');

      System.assert(false, 'It should have thrown an IllegalArgumentException');
    } catch (System.IllegalArgumentException e) {
      System.assert(e.getMessage().contains('not a valid SObject'), e.getMessage());
    }
  }
}
