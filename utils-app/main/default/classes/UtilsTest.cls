@isTest(isParallel=true)
public class UtilsTest {
    private class AccountTriggerHandlerTest extends TriggerHandler.Routine {
        public override Schema.SObjectType getSObjectType() {
            return Schema.Account.SObjectType;
        }
    }

    @isTest
    static void describer() {
        Utils.Describer describ = Utils.getDescriber();
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

        System.assertEquals(
            'Contacts',
            describ.getObjectRelationshipName(accountType, Schema.Contact.SObjectType)
        );
    }

    @isTest
    static void entry() {
        List<Utils.Entry> entries = new List<Utils.Entry>{
            new Utils.Entry('value1', 'label1'),
            new Utils.Entry('value0', 'label0'),
            new Utils.Entry('value9')
        };

        System.assertEquals('value1', entries[0].getValue());
        System.assertEquals('value9', entries[2].getLabel());
        System.assertEquals(entries.size(), 3);

        // This will sort the entries according to their label
        entries.sort();

        System.assertEquals('label0', entries[0].getLabel());

        Set<Utils.Entry> entrySet = new Set<Utils.Entry>(entries);

        // This is not going to be added because it is a duplicate
        entrySet.add(new Utils.Entry('value1', 'label1'));

        System.assertEquals(entries.size(), 3);
    }

    @isTest
    static void hasher() {
        Utils.Hasher hs;

        try {
            hs = new Utils.Hasher('MD6');
        } catch (UnsupportedOperationException e) {
            System.assert(e.getMessage().contains('Algorithm must be'));
        }

        hs = new Utils.Hasher();
        String value = 'Hash Me!';

        System.assertEquals(
            EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(value))),
            hs.hash(value)
        );
    }

    @isTest
    static void fieldLevelSecurity() {
        Schema.Profile insufficientProfile = [
            SELECT Id
            FROM Profile
            WHERE UserType = 'CsnOnly'
            LIMIT 1
        ];

        Schema.User insufficientUser;

        System.runAs(TestUtils.getUser()) {
            // Generating user
            insufficientUser = (Schema.User) new TestUtils.UserMaker()
                .setProfileId(insufficientProfile.Id)
                .setName('Insufficient')
                .setCount(1)
                .make()
                .get(0);
        }

        Test.startTest();

        Fls sec = new Fls(Schema.Contact.SObjectType, System.AccessType.UPDATABLE)
            .queue(
                new Set<Schema.SObjectField>{ Schema.Contact.FirstName, Schema.Contact.LastName }
            )
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
                    'It should have contained HasOptedOutOfEmail field: ' +
                    e.getReport().getFieldFailures()
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

    @isTest
    static void mapper() {
        Utils.Entry dummy = new Utils.Entry('value1', 'label1');
        String serializedDummy = JSON.serialize(dummy);

        Utils.Mapper umapper = Utils.deserializeToMapper(serializedDummy);

        System.assert(umapper.containsKey('label'), 'It should have contained label key');
        System.assertEquals(dummy.getLabel(), umapper.getString('label'));
        System.assertEquals(dummy.getValue(), umapper.getString('value'));
    }

    @isTest
    static void randomizerGenerator() {
        Utils.RandomizerBuilder builder;
        String randomizer;
        List<String> components;

        builder = new Utils.RandomizerBuilder();
        randomizer = builder
            .setCurrentTimeMillis(true)
            .setLength(6)
            .setPreferences(
                new Set<Utils.RandomizerPreference>{
                    Utils.RandomizerPreference.INCLUDE_LETTER,
                    Utils.RandomizerPreference.INCLUDE_NUMBER
                }
            )
            .setPrefix('TEST')
            .build()
            .generate();
        components = randomizer.split('-');

        System.assertEquals(
            3,
            components.size(),
            'The randomizer components should have been 3: ' + randomizer
        );
        System.assertEquals('TEST', components[0]);
        System.assertEquals(6, components[1].length());
        System.assert(
            components[1].isAlphanumeric(),
            'The 2nd component should have been alphanumeric ' + components[1]
        );

        builder = new Utils.RandomizerBuilder();
        randomizer = builder
            .setPreferences(
                new Set<Utils.RandomizerPreference>{ Utils.RandomizerPreference.INCLUDE_NUMBER }
            )
            .setLength(3)
            .build()
            .generate();
        components = randomizer.split('-');

        System.assertEquals(3, components[0].length());
        System.assert(
            !components[0].isAlpha(),
            'The component should not have contained letters: ' + components[0]
        );
    }

    @isTest
    static void recordTypeInvocableProcessor() {
        Schema.Account acc = new Schema.Account(Name = 'Test');

        insert acc;

        Test.startTest();

        RecordTypeInvocableProcessor.Request req = new RecordTypeInvocableProcessor.Request();

        req.recordId = acc.Id;
        req.recordTypeName = 'Test';

        RecordTypeInvocableProcessor.execute(new List<RecordTypeInvocableProcessor.Request>{ req });

        Test.stopTest();

        System.assertEquals(acc.Id, [SELECT Id FROM Account WHERE Name = :acc.Name LIMIT 1].Id);
    }

    @isTest
    static void requireNonNull() {
        String message = 'Something is required';

        try {
            Utils.requireNonNull((Schema.Account) null, message);

            System.assert(false, 'It should have thrown a NullPointerException');
        } catch (NullPointerException e) {
            System.assertEquals(message, e.getMessage());
        }
    }

    @isTest
    static void sleep() {
        Long start = System.currentTimeMillis();

        Utils.sleep(3);

        Long elapsed = System.currentTimeMillis() - start;

        System.assert(elapsed >= 3000, 'It should have slept for about 3 seconds');
    }

    @isTest
    static void triggerHandler() {
        // Enablement
        System.Type stype = AccountTriggerHandlerTest.class;
        List<Schema.Cs_TriggerHandlerRoutine__c> records;

        TriggerHandler.enable(stype);

        records = [
            SELECT Name, Is_Disabled__c, SObjectType__c
            FROM Cs_TriggerHandlerRoutine__c
            WHERE ClassName__c = :stype.getName()
        ];

        System.assert(!records.isEmpty(), 'Routine record should have been present');
        System.assert(!records[0].Is_Disabled__c, 'Routine record should have been enabled');
        System.assertEquals(String.valueOf(Schema.Account.SObjectType), records[0].SObjectType__c);

        TriggerHandler.execute(Schema.Account.SObjectType);

        TriggerHandler.disable(stype);

        records = [
            SELECT Name, Is_Disabled__c
            FROM Cs_TriggerHandlerRoutine__c
            WHERE ClassName__c = :stype.getName()
        ];

        System.assert(records[0].Is_Disabled__c, 'Routine record should have been disabled');

        // Tagging
        String key = 'any';
        AccountTriggerHandlerTest handler = new AccountTriggerHandlerTest();

        handler.tag(records[0].Id, key);

        System.assert(handler.isTagged(records[0].Id, key), 'Id should have been tagged');

        handler.untag(records[0].Id, key);

        System.assert(!handler.isTagged(records[0].Id, key), 'Id should have been untagged');
    }

    @isTest
    static void uniquifiers() {
        Utils.ValueUniquifier uni = new Utils.ValueUniquifier();

        uni.addValue('A');
        uni.addValue('B');
        uni.addValue('C');

        System.assertEquals(3, uni.getValues().size());

        System.assert(!uni.addValue('A'), 'It should have prevented the value from being re-added');

        Schema.Contact cnt1 = new Schema.Contact(
            LastName = 'Contact1',
            Email = 'example@example.com'
        );
        Schema.Contact cnt2 = new Schema.Contact(
            LastName = 'Contact2',
            Email = 'example@example.com'
        );
        Schema.Contact cnt3 = new Schema.Contact(LastName = 'Contact2', Email = 'demo@example.com');
        Utils.RecordValueUniquifier recuni = new Utils.RecordValueUniquifier(Contact.Email);

        System.assertEquals(cnt3.Email, recuni.getRecordValue(cnt3));

        recuni.addRecordValue(cnt1);

        System.assertEquals(1, recuni.getValues().size());
        System.assert(
            recuni.getRecord('example@example.com') != null,
            'It should have returned the record by the email specified'
        );
        System.assert(
            !recuni.addRecordValue(cnt2),
            'It should have prevented the record value from being re-added'
        );
    }
}
