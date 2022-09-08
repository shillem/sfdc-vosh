@isTest(isParallel=true)
public class FlsTest {
  @isTest
  static void authorization() {
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

    Test.startTest();

    Fls sec = new Fls(Schema.Contact.SObjectType, Fls.AccessType.UPDATABLE)
      .queue(new Set<Schema.SObjectField>{ Schema.Contact.FirstName, Schema.Contact.LastName })
      .queue(Schema.Contact.Title);

    Fls.Report rep;

    Schema.Contact anyone = new Schema.Contact(LastName = 'Anyone', HasOptedOutOfEmail = true);

    System.runAs(insufficientUser) {
      rep = Fls.audit(anyone, Fls.AccessType.CREATABLE);

      System.assert(!rep.isAuthorized(), 'It should not have been authorized');

      try {
        rep.throwExceptionIfUnauthorized();

        System.assert(false, 'It should have thrown a Fls.ReportException');
      } catch (Fls.ReportException e) {
        System.assert(
          e.getMessage().contains(String.valueOf(Schema.Contact.HasOptedOutOfEmail)),
          'It should have contained HasOptedOutOfEmail field: ' + e.getMessage()
        );
        System.assert(
          e.getReport().getFieldFailures().contains(Schema.Contact.HasOptedOutOfEmail),
          'It should have contained HasOptedOutOfEmail field: ' + e.getReport().getFieldFailures()
        );
      }

      rep = sec.audit();

      System.assert(!rep.isAuthorized(), 'It should not have been authorized');
    }

    rep = Fls.audit(anyone, Fls.AccessType.CREATABLE);

    System.assert(rep.isAuthorized(), 'It should have been authorized');

    rep = sec.audit();

    System.assert(rep.isAuthorized(), 'It should have been authorized');
  }

  @isTest
  static void crud() {
    List<Schema.Account> accts = new TestUtils.AccountMaker()
      .setName('Demo')
      .setCount(3)
      .setAutoInsert(false)
      .make();

    Fls.insertMany(accts, new Fls.OpReq().any());

    System.assertEquals(3, [SELECT Id FROM Account LIMIT 10].size());

    accts[0].Name = 'Demoist';

    {
      Fls.OpRes res = Fls.updateMany(accts, new Fls.OpReq().any());

      System.assertEquals(3, res.getSucceeded().size());
      System.assertEquals(1, [SELECT Id FROM Account WHERE Name = 'Demoist' LIMIT 10].size());
    }

    {
      Fls.OpRes res = Fls.deleteOne(accts.remove(0), new Fls.OpReq().any());
      
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

      Fls.OpRes res = Fls.upsertMany(accts, new Fls.OpReq().all());

      System.assertEquals(3, res.getSucceeded().size());
      System.assertEquals(3, [SELECT Id FROM Account LIMIT 10].size());
    }
  }
}
