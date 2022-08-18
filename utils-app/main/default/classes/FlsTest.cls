@isTest(isParallel=true)
public class FlsTest {
  @isTest
  static void main() {
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

    Fls sec = new Fls(Schema.Contact.SObjectType, System.AccessType.UPDATABLE)
      .queue(new Set<Schema.SObjectField>{ Schema.Contact.FirstName, Schema.Contact.LastName })
      .queue(Schema.Contact.Title);

    Fls.Report rep;

    Schema.Contact anyone = new Schema.Contact(LastName = 'Anyone', HasOptedOutOfEmail = true);

    System.runAs(insufficientUser) {
      rep = Fls.audit(anyone, System.AccessType.CREATABLE);

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

    rep = Fls.audit(anyone, System.AccessType.CREATABLE);

    System.assert(rep.isAuthorized(), 'It should have been authorized');

    rep = sec.audit();

    System.assert(rep.isAuthorized(), 'It should have been authorized');
  }
}
