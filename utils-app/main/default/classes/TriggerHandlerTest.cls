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
    final String acctTypeName = String.valueOf(Schema.Account.SObjectType);
    final System.Type stype1 = AccountTriggerHandlerTest1.class;
    final System.Type stype2 = AccountTriggerHandlerTest2.class;

    TriggerHandler.commitSpecs(
      new List<TriggerHandler.Spec>{
        new TriggerHandler.Spec(stype1),
        new TriggerHandler.Spec(stype2).setOrder(2)
      }
    );

    {
      final List<Schema.Cs_TriggerHandlerRoutine__c> records = [
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
    }

    TriggerHandler.execute(Schema.Account.SObjectType);

    TriggerHandler.commitSpecs(
      new List<TriggerHandler.Spec>{ TriggerHandler.readSpec(stype2).setDisabled(true) }
    );

    {
      final List<Schema.Cs_TriggerHandlerRoutine__c> records = [
        SELECT Name, Is_Disabled__c
        FROM Cs_TriggerHandlerRoutine__c
        WHERE ClassName__c = :stype2.getName()
      ];

      Assert.areEqual(
        1,
        records.size(),
        'There should be exactly one routine record for ' + stype2.getName()
      );

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
    }
  }

  @isTest
  static void triggerHandlerSpecOptions() {
    final TriggerHandler.Spec spec = new TriggerHandler.Spec(AccountTriggerHandlerTest1.class);

    spec.setOption('a', true);

    Assert.isTrue((Boolean) spec.getOption('a'), 'Option a should have been set to true');
    Assert.isFalse(spec.isAllOptionsDisabled(), 'It should have returned true because a is true');
    Assert.isFalse(
      spec.isDisabled(),
      'It should have returned false because a new spec is enabled by default'
    );

    spec.setOption('a', false);
    spec.setDisabled(spec.isAllOptionsDisabled());
    Assert.isTrue(spec.isDisabled(), 'It should have returned true because a is now false');
  }
}
