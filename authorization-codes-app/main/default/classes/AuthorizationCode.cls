public without sharing class AuthorizationCode {
    public enum Status {
        ABSENT,
        EXPIRED,
        INVALID,
        VALID
    }

    public static String generate(Id referenceId, Integer durationInSecs) {
        vosh.Utils.requireNonNull(referenceId, 'Reference Id cannot be null');

        Schema.Authorization_Code__c record = getRecord(referenceId);

        if (record == null) {
            record = new Schema.Authorization_Code__c(Reference_Id__c = referenceId);
        }

        Datetime now = Datetime.now();

        record.Code__c = generateCode();
        record.Effective_From__c = now;
        record.Effective_To__c = now.addSeconds(durationInSecs);

        upsert record;

        return record.Code__c;
    }

    private static String generateCode() {
        return new vosh.Utils.RandomizerBuilder()
            .setLength(6)
            .setPreferences(
                new Set<vosh.Utils.RandomizerPreference>{ vosh.Utils.RandomizerPreference.INCLUDE_NUMBER }
            )
            .build()
            .generate();
    }

    private static Schema.Authorization_Code__c getRecord(Id referenceId) {
        List<Schema.Authorization_Code__c> records = [
            SELECT Id, Code__c, Effective_From__c, Effective_To__c
            FROM Authorization_Code__c
            WHERE Reference_Id__c = :referenceId
        ];

        return records.isEmpty() ? null : records[0];
    }

    public static Boolean lists(Id referenceId) {
        vosh.Utils.requireNonNull(referenceId, 'Reference Id cannot be null');

        Schema.Authorization_Code__c record = getRecord(referenceId);

        if (record == null) {
            return false;
        }

        Datetime now = Datetime.now();

        if (now < record.Effective_From__c || now > record.Effective_To__c) {
            return false;
        }

        return true;
    }

    public static Status match(String code, Id referenceId) {
        vosh.Utils.requireNonNull(code, 'Code cannot be null');
        vosh.Utils.requireNonNull(referenceId, 'Reference Id cannot be null');

        Schema.Authorization_Code__c record = getRecord(referenceId);

        if (record == null) {
            return Status.ABSENT;
        }

        Datetime now = Datetime.now();

        if (now < record.Effective_From__c || now > record.Effective_To__c) {
            return Status.EXPIRED;
        }

        if (!code.equalsIgnoreCase(record.Code__c)) {
            return Status.INVALID;
        }

        return Status.VALID;
    }

    public static void notify(String code) {
        //TODO
    }
}
