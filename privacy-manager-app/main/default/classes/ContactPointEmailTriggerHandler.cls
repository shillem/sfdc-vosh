global class ContactPointEmailTriggerHandler extends vosh.TriggerHandler.Routine {
    private vosh.Utils.RecordValueUniquifier emailUniquifier;

    private void addEmailError(SObject record, Object value) {
        record.addError('Email ' + value + ' is duplicate');
    }

    global override void beforeInsert(SObject record) {
        if (!emailUniquifier.addRecordValue(record)) {
            addEmailError(record, emailUniquifier.getRecordValue(record));
        }
    }

    global override void beforeUpdate(SObject stored, SObject memory) {
        if (
            !((Schema.ContactPointEmail) memory)
                .EmailAddress.equals(((Schema.ContactPointEmail) stored).EmailAddress)
        ) {
            beforeInsert(memory);
        }
    }

    global override Schema.SObjectType getSObjectType() {
        return Schema.ContactPointEmail.SObjectType;
    }

    global override void pre() {
        emailUniquifier = new vosh.Utils.RecordValueUniquifier(
            Schema.ContactPointEmail.EmailAddress
        );
    }

    global override void post() {
        List<String> emails = new List<String>();

        for (Object value : emailUniquifier.getValues()) {
            emails.add((String) value);
        }

        List<Schema.ContactPointEmail> cpes = [
            SELECT Id, EmailAddress
            FROM ContactPointEmail
            WHERE EmailAddress IN :emails
        ];

        if (cpes.isEmpty()) {
            return;
        }

        for (Schema.ContactPointEmail cpe : cpes) {
            Object value = emailUniquifier.getRecordValue(cpe);
            SObject record = emailUniquifier.getRecord(value);

            addEmailError(record, value + ' ' + record);

            if (record != null) {
                addEmailError(record, value);
            }
        }
    }
}