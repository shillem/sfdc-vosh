@isTest
public class PrivacyManagerTest {
    @isTest
    static void contactPointEmailTrigger() {
        TriggerHandler.enable(ContactPointEmailTriggerHandler.class);

        List<Schema.ContactPointEmail> cpes = new List<Schema.ContactPointEmail>{
            new Schema.ContactPointEmail(
                EmailAddress = 'example@example.com'
            ),
            new Schema.ContactPointEmail(
                EmailAddress = 'typo@example.com'
            )
        };

        insert cpes;

        System.assertEquals(
            2,
            (Integer) ([SELECT COUNT(Id) FROM ContactPointEmail][0].get('expr0'))
        );

        Test.startTest();

        try {
            insert new List<Schema.ContactPointEmail>{
                new Schema.ContactPointEmail(EmailAddress = 'demo@example.com'),
                new Schema.ContactPointEmail(EmailAddress = 'demo@example.com')
            };

            System.assert(false, 'It should have thrown a duplicate exception');
        } catch (System.DmlException e) {
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
        }

        try {
            insert new List<Schema.ContactPointEmail>{
                new Schema.ContactPointEmail(EmailAddress = 'example@example.com')
            };

            System.assert(false, 'It should have thrown a duplicate exception');
        } catch (System.DmlException e) {
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
        }

        try {
            cpes[1].EmailAddress = 'example@example.com';

            update cpes[1];

            System.assert(false, 'It should have thrown a duplicate exception');
        } catch (System.DmlException e) {
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
        }

        Test.stopTest();

        System.assertEquals(
            2,
            (Integer) ([SELECT COUNT(Id) FROM ContactPointEmail][0].get('expr0'))
        );
    }
}
