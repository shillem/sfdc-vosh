@isTest(isParallel=true)
public with sharing class SObjectCollectorTest {
  @isTest
  static void main() {
    List<Schema.Account> accts = new List<Schema.Account>{
      new Account(Name = 'A', BillingCountry = 'Italy'),
      new Account(Name = 'B', BillingCountry = 'Germany'),
      new Account(Name = 'C', BillingCountry = 'Germany')
    };

    SObjectCollector soc = new SObjectCollector();
    soc.addAll(accts);

    SObjectCollector.Criteria criteria1 = new SObjectCollector.FieldCriteria(
      Schema.Account.BillingCountry
    );

    Map<Object, List<SObject>> lists = soc.makeMapOfLists(criteria1);
    System.assertEquals(2, lists.size());
    System.assert(lists.containsKey('Italy'));

    List<Schema.Account> castAccounts = (List<Schema.Account>) lists.get('Italy');

    insert accts;

    Map<Object, Map<Id, SObject>> maps = soc.makeMapOfMaps(criteria1);
    System.assertEquals(2, maps.get('Germany').size());

    accts[2].Name = 'C of B';
    accts[2].ParentId = accts[1].Id;

    update accts[2];

    SObjectCollector.Criteria criteria2 = new SObjectCollector.FieldCriteria(
      Schema.Account.ParentId
    );

    {
      final Map<Id, List<SObject>> idLists = soc.makeIdMapOfLists(criteria2);
      System.assertEquals(1, idLists.size());

      final Map<Id, Map<Id, SObject>> idMaps = soc.makeIdMapOfMaps(criteria2);
      System.assert(idMaps.get(accts[1].Id).containsKey(accts[2].Id));
    }

    {
      final Map<Object, List<SObject>> objectList = SObjectCollector.collectBy(
        Schema.Account.BillingCountry,
        accts
      );

      System.assert(objectList.containsKey('Italy'));
      System.assertEquals(1, ((List<Schema.Account>) objectList.get('Italy')).size());
    }
  }
}
