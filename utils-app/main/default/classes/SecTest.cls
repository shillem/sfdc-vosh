@isTest(isParallel=true)
public class SecTest {
  @isTest
  static void authorization() {
    Schema.User insufficientUser = createInsufficientUser();
    Schema.Contact anyone = new Schema.Contact(LastName = 'Anyone', HasOptedOutOfEmail = true);

    System.runAs(insufficientUser) {
      Sec.AuditResult res = Sec.audit(anyone, Sec.AccessType.CREATABLE);

      System.assert(!res.isAuthorized(), 'It should not have been authorized');

      try {
        res.throwExceptionIfUnauthorized();

        System.assert(false, 'It should have thrown a Sec.AuditException');
      } catch (Sec.AuditException e) {
        System.assert(
          e.getMessage().contains(String.valueOf(Schema.Contact.HasOptedOutOfEmail)),
          'It should have contained HasOptedOutOfEmail field: ' + e.getMessage()
        );

        System.assert(
          res.getFailedFields().contains(Schema.Contact.HasOptedOutOfEmail),
          'It should have contained HasOptedOutOfEmail field: ' + res.getFailedFields()
        );
      }
    }

    Sec.AuditResult res = Sec.audit(anyone, Sec.AccessType.CREATABLE);

    System.assert(res.isAuthorized(), 'It should have been authorized');
  }

  private static Schema.User createInsufficientUser() {
    Schema.User insufficientUser;

    System.runAs(TestUtils.getUser()) {
      // Generating user
      insufficientUser = (Schema.User) new TestUtils.UserMaker()
        .setProfileId(TestUtils.getChatterProfileId())
        .setLastName('Insufficient')
        .setCount(1)
        .make()
        .get(0);
    }

    return insufficientUser;
  }

  @isTest
  static void dmlRequest() {
    List<Schema.Account> accts = new TestUtils.AccountMaker()
      .setName('Demo')
      .setCount(3)
      .setAutoInsert(false)
      .make();

    Sec.insertMany(accts, new Sec.DmlRequest().any());

    System.assertEquals(3, [SELECT Id FROM Account LIMIT 10].size());

    accts[0].Name = 'Demoist';

    {
      Sec.DmlResponse res = Sec.updateMany(accts, new Sec.DmlRequest().any());

      System.assert(res.getResults() instanceof List<Database.SaveResult>);
      System.assertEquals(3, res.getSucceeded().size());
      System.assertEquals(1, [SELECT Id FROM Account WHERE Name = 'Demoist' LIMIT 10].size());
    }

    {
      Sec.DmlResponse res = Sec.deleteOne(accts.remove(0), new Sec.DmlRequest().any());

      System.assert(res.getResults() instanceof List<Database.DeleteResult>);
      System.assertEquals(1, res.getSucceeded().size());
      System.assertEquals(2, [SELECT Id FROM Account LIMIT 10].size());
    }

    {
      accts.add(
        (Schema.Account) new TestUtils.AccountMaker()
          .setName('Upsert')
          .setCount(1)
          .setAutoInsert(false)
          .make()
          .get(0)
      );

      System.assertEquals(3, accts.size());

      Sec.DmlResponse res = Sec.upsertMany(accts, new Sec.DmlRequest().all());

      System.assert(res.getResults() instanceof List<Database.UpsertResult>);
      System.assertEquals(3, res.getSucceeded().size());
      System.assertEquals(3, [SELECT Id FROM Account LIMIT 10].size());
    }
  }

  @isTest
  static void failSilently() {
    Schema.Account acct = new Schema.Account();

    try {
      insert acct;

      System.assert(false, 'It should have failed');
    } catch (System.DmlException e) {
      System.assertEquals(System.StatusCode.REQUIRED_FIELD_MISSING.name(), e.getDmlStatusCode(0));
    }

    Schema.User insufficientUser = createInsufficientUser();

    System.runAs(insufficientUser) {
      acct.Name = 'Demo';

      try {
        Sec.insertOne(acct, new Sec.DmlRequest().any());

        System.assert(false, 'It should have failed');
      } catch (Sec.AuditException e) {
        Sec.AuditResult res = e.getAuditResult();

        System.assertEquals(Schema.Account.SObjectType, res.getFailedObject());
        System.assertEquals(Schema.Account.SObjectType, res.getFailedObject());
        System.assert(res.getFailedFields().contains(Schema.Account.Name));
      }

      Sec.DmlResponse res = Sec.insertOne(acct, new Sec.DmlRequest().any().failSilently());

      System.assertEquals(1, res.getFailed().size());
    }
  }
}
