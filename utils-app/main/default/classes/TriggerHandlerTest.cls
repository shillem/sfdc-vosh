@isTest
public class TriggerHandlerTest {
  private class AccountTriggerHandlerTest1 extends TriggerHandler.Routine {
    public override Schema.SObjectType getSObjectType() {
      return Schema.Account.SObjectType;
    }
  }

  private class AccountTriggerHandlerTest2 extends TriggerHandler.Routine {
    public override Schema.SObjectType getSObjectType() {
      return Schema.Account.SObjectType;
    }
  }

  @isTest
  static void triggerHandler() {
    // Enablement
    String acctTypeName = String.valueOf(Schema.Account.SObjectType);
    System.Type stype1 = AccountTriggerHandlerTest1.class;
    System.Type stype2 = AccountTriggerHandlerTest2.class;
    List<Schema.Cs_TriggerHandlerRoutine__c> records;

    TriggerHandler.enable(stype1);
    TriggerHandler.enable(
      new List<TriggerHandler.Spec>{ new TriggerHandler.Spec(stype2).setOrder(2) }
    );

    records = [
      SELECT Name, ClassName__c, Is_Disabled__c, SObjectType__c, Sort_Order__c
      FROM Cs_TriggerHandlerRoutine__c
      WHERE SObjectType__c = :acctTypeName
      ORDER BY Sort_Order__c ASC
    ];

    System.assertEquals(2, records.size());
    System.assert(!records[0].Is_Disabled__c, 'Routine record should have been enabled');
    System.assertEquals(stype1.getName(), records[0].ClassName__c);
    System.assertEquals(acctTypeName, records[0].SObjectType__c);
    System.assertEquals(1, records[0].Sort_Order__c);
    System.assertEquals(2, records[1].Sort_Order__c);

    TriggerHandler.execute(Schema.Account.SObjectType);

    TriggerHandler.disable(stype2);

    records = [
      SELECT Name, Is_Disabled__c
      FROM Cs_TriggerHandlerRoutine__c
      WHERE ClassName__c = :stype2.getName()
    ];

    System.assert(
      records[0].Is_Disabled__c,
      'Routine ' + stype2.getName() + ' record should have been disabled'
    );

    // Tagging
    String key = 'any';
    AccountTriggerHandlerTest1 handler = new AccountTriggerHandlerTest1();

    handler.tag(records[0].Id, key);

    System.assert(handler.isTagged(records[0].Id, key), 'Id should have been tagged');

    handler.untag(records[0].Id, key);

    System.assert(!handler.isTagged(records[0].Id, key), 'Id should have been untagged');

    // Matching
    List<Schema.Account> accts = new TestUtils.AccountMaker()
      .setName('Dummy')
      .set(Schema.Account.Phone, '0000')
      .setCount(2)
      .make();

    System.assert(
      handler.match(accts[0], accts[1], Schema.Account.Phone),
      'Account phone numbers should have matched'
    );

    System.assert(
      handler.anyDiffer(accts[0], accts[1], new List<Schema.SObjectField>{ Schema.Account.Id }),
      'Account Ids should have mismatched'
    );

    System.assert(
      !handler.allDiffer(
        accts[0],
        accts[1],
        new List<Schema.SObjectField>{ Schema.Account.Id, Schema.Account.Phone }
      ),
      'Account Ids should have mismatched'
    );
  }
}
