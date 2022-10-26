/**
 * @description A utility class that perform FLS/CRUD checks
 * in accordance with <a href="https://developer.salesforce.com/docs/atlas.en-us.214.0.lightning.meta/lightning/apex_crud_fls.htm">Salesforce guidelines</a>.
 *
 * @since 1.1
 */
global inherited sharing class Sec {
  global enum AccessType {
    CREATABLE,
    DELETABLE,
    READABLE,
    UPDATABLE,
    UPSERTABLE
  }

  global class AuditException extends Exception {
    private final AuditResult value;

    private AuditException(AuditResult value) {
      this.value = value;

      String message = value.aType + ' not allowed for: ';
      List<String> objs = new List<String>();

      if (value.failedObject != null) {
        objs.add(String.valueOf(value.failedObject));
      }

      if (!value.failedFields.isEmpty()) {
        for (Schema.SObjectField field : value.failedFields) {
          objs.add(String.valueOf(field));
        }
      }

      setMessage(message + String.join(objs, ', '));
    }

    global AuditResult getAuditResult() {
      return value;
    }
  }

  global class AuditResult {
    private final AccessType aType;
    private final Set<Schema.SObjectField> failedFields;
    private final Schema.SObjectType failedObject;

    private AuditResult(
      AccessType aType,
      Schema.SObjectType sType,
      Set<Schema.SObjectField> sFields
    ) {
      this.aType = aType;
      this.failedFields = check(sFields);
      this.failedObject = check(sType);
    }

    private Set<Schema.SObjectField> check(Set<Schema.SObjectField> sFields) {
      Set<Schema.SObjectField> failures = new Set<Schema.SObjectField>();

      if (sFields == null || sFields.isEmpty()) {
        return failures;
      }

      for (Schema.SObjectField sField : sFields) {
        final DescribeFieldResult dfr = Describer.getInstance().getFieldDescribe(sField);
        final Boolean perm;

        switch on (aType) {
          when CREATABLE {
            perm = dfr.isCreateable();
          }
          when READABLE {
            perm = dfr.isAccessible();
          }
          when UPDATABLE {
            perm = NON_UPDATABLE_FIELD_NAMES.contains(dfr.getName()) || dfr.isUpdateable();
          }
          when UPSERTABLE {
            perm =
              NON_UPDATABLE_FIELD_NAMES.contains(dfr.getName()) ||
              (dfr.isCreateable() && dfr.isUpdateable());
          }
          when else {
            throw new UnsupportedOperationException(aType.name());
          }
        }

        if (!perm) {
          failures.add(sField);
        }
      }

      return failures;
    }

    private Schema.SObjectType check(Schema.SObjectType sType) {
      if (sType == null) {
        return null;
      }

      final DescribeSObjectResult dsr = Describer.getInstance().getObjectDescribe(sType);
      final Boolean perm;

      switch on (aType) {
        when CREATABLE {
          perm = dsr.isCreateable();
        }
        when DELETABLE {
          perm = dsr.isDeletable();
        }
        when READABLE {
          perm = dsr.isAccessible();
        }
        when UPDATABLE {
          perm = dsr.isUpdateable();
        }
        when UPSERTABLE {
          perm = dsr.isCreateable() && dsr.isUpdateable();
        }
        when else {
          throw new UnsupportedOperationException(aType.name());
        }
      }

      return perm ? null : sType;
    }

    global Set<Schema.SObjectField> getFailedFields() {
      return failedFields;
    }

    global Schema.SObjectType getFailedObject() {
      return failedObject;
    }

    global Boolean isAuthorized() {
      return failedObject == null && failedFields.isEmpty();
    }

    global void throwExceptionIfUnauthorized() {
      if (!isAuthorized()) {
        throw new AuditException(this);
      }
    }
  }

  global class DmlRequest {
    private Boolean allOrNone;
    private Schema.SObjectField eif;
    private Boolean silent;

    global DmlRequest() {
      allOrNone = false;
      silent = false;
    }

    global DmlRequest any() {
      allOrNone = false;
      return this;
    }

    global DmlRequest all() {
      allOrNone = true;
      return this;
    }

    global DmlRequest externalIdField(Schema.SObjectField value) {
      eif = value;
      return this;
    }

    global DmlRequest failSilently() {
      silent = true;
      return this;
    }
  }

  global class DmlResponse {
    private final List<Object> results;
    private final List<SObject> submitted;

    private List<SObject> failed;
    private List<SObject> succeeded;

    private DmlResponse(List<SObject> submitted, List<Database.DeleteResult> results) {
      this.submitted = submitted;
      this.results = results;
    }

    private DmlResponse(List<SObject> submitted, List<Database.SaveResult> results) {
      this.submitted = submitted;
      this.results = results;
    }

    private DmlResponse(List<SObject> submitted, List<Database.UpsertResult> results) {
      this.submitted = submitted;
      this.results = results;
    }

    global List<Database.Error> getErrors(Integer numOfRecords) {
      if (results.isEmpty()) {
        return new List<Database.Error>();
      }

      if (results[0] instanceof Database.SaveResult) {
        return readSaveErrors((List<Database.SaveResult>) results, numOfRecords);
      }

      if (results[0] instanceof Database.UpsertResult) {
        return readUpsertErrors((List<Database.UpsertResult>) results, numOfRecords);
      }

      if (results[0] instanceof Database.DeleteResult) {
        return readDeleteErrors((List<Database.DeleteResult>) results, numOfRecords);
      }

      return new List<Database.Error>();
    }

    global List<SObject> getFailed() {
      if (failed == null) {
        load();
      }

      return failed;
    }

    global List<Object> getResults() {
      return results;
    }

    global List<SObject> getSucceeded() {
      if (succeeded == null) {
        load();
      }

      return succeeded;
    }

    private void load() {
      succeeded = new List<SObject>();
      failed = new List<SObject>();

      if (submitted.isEmpty()) {
        return;
      }

      if (results.isEmpty()) {
        failed.addAll(submitted);

        return;
      }

      if (results[0] instanceof Database.SaveResult) {
        loadSaveResults((List<Database.SaveResult>) results);
      } else if (results[0] instanceof Database.UpsertResult) {
        loadUpsertResults((List<Database.UpsertResult>) results);
      } else if (results[0] instanceof Database.DeleteResult) {
        loadDeleteResults((List<Database.DeleteResult>) results);
      }
    }

    private void loadDeleteResults(List<Database.DeleteResult> results) {
      for (Integer i = 0; i < submitted.size(); i++) {
        if (results[i].isSuccess()) {
          succeeded.add(submitted[i]);
        } else {
          failed.add(submitted[i]);
        }
      }
    }

    private void loadSaveResults(List<Database.SaveResult> results) {
      for (Integer i = 0; i < submitted.size(); i++) {
        if (results[i].isSuccess()) {
          succeeded.add(submitted[i]);
        } else {
          failed.add(submitted[i]);
        }
      }
    }

    private void loadUpsertResults(List<Database.UpsertResult> results) {
      for (Integer i = 0; i < submitted.size(); i++) {
        if (results[i].isSuccess()) {
          succeeded.add(submitted[i]);
        } else {
          failed.add(submitted[i]);
        }
      }
    }

    private List<Database.Error> readDeleteErrors(
      List<Database.DeleteResult> results,
      Integer numOfRecords
    ) {
      final List<Database.Error> errors = new List<Database.Error>();

      Integer count = 0;

      for (Integer i = 0; i < results.size() && count < numOfRecords; i++) {
        final Database.DeleteResult result = results[i];

        if (!result.isSuccess()) {
          errors.addAll(result.getErrors());

          count++;
        }
      }

      return errors;
    }

    private List<Database.Error> readSaveErrors(
      List<Database.SaveResult> results,
      Integer numOfRecords
    ) {
      final List<Database.Error> errors = new List<Database.Error>();

      Integer count = 0;

      for (Integer i = 0; i < results.size() && count < numOfRecords; i++) {
        final Database.SaveResult result = results[i];

        if (!result.isSuccess()) {
          errors.addAll(result.getErrors());
          
          count++;
        }
      }

      return errors;
    }

    private List<Database.Error> readUpsertErrors(
      List<Database.UpsertResult> results,
      Integer numOfRecords
    ) {
      final List<Database.Error> errors = new List<Database.Error>();

      Integer count = 0;

      for (Integer i = 0; i < results.size() && count < numOfRecords; i++) {
        final Database.UpsertResult result = results[i];

        if (!result.isSuccess()) {
          errors.addAll(result.getErrors());
          
          count++;
        }
      }

      return errors;
    }
  }

  private static final List<String> NON_UPDATABLE_FIELD_NAMES = new List<String>{
    'CreatedById',
    'CreatedDate',
    'Id',
    'IsDeleted',
    'LastModifiedById',
    'LastModifiedDate',
    'SystemModstamp'
  };

  global static AuditResult audit(SObject record, AccessType aType) {
    Utils.requireNonNull(record, 'Record cannot be null');
    Utils.requireNonNull(aType, 'Access type cannot be null');

    final Schema.SObjectType sType = record.getSObjectType();
    final Map<String, Schema.SObjectField> sTypeFields = Describer.getInstance()
      .getObjectFieldMap(sType);
    final Set<Schema.SObjectField> sFields = new Set<Schema.SObjectField>();

    for (String n : record.getPopulatedFieldsAsMap().keySet()) {
      final Schema.SObjectField f = sTypeFields.get(n);

      // Necessary check since to exclude children reference fields from real fields
      if (f != null) {
        sFields.add(f);
      }
    }

    return new AuditResult(aType, sType, sFields);
  }

  global static AuditResult audit(Schema.SObjectField sField, AccessType aType) {
    Utils.requireNonNull(sField, 'SObject field cannot be null');
    Utils.requireNonNull(aType, 'Access type cannot be null');

    return audit(new Set<Schema.SObjectField>{ sField }, aType);
  }

  global static AuditResult audit(Set<Schema.SObjectField> sFields, AccessType aType) {
    Utils.requireNonNull(sFields, 'SObject fields cannot be null');
    Utils.requireNonNull(aType, 'Access type cannot be null');

    return new AuditResult(aType, null, sFields);
  }

  global static AuditResult audit(Schema.SObjectType sType, AccessType aType) {
    Utils.requireNonNull(sType, 'SObject type cannot be null');
    Utils.requireNonNull(aType, 'Access type cannot be null');

    return new AuditResult(aType, sType, null);
  }

  global static DmlResponse deleteOne(SObject record, DmlRequest o) {
    Utils.requireNonNull(record, 'Record cannot be null');

    return deleteMany(new List<SObject>{ record }, o);
  }

  global static DmlResponse deleteMany(List<SObject> records, DmlRequest o) {
    Utils.requireNonNull(records, 'Records cannot be null');
    Utils.requireNonNull(o, 'Operation request cannot be null');

    if (records.isEmpty()) {
      return new DmlResponse(records, new List<Database.DeleteResult>());
    }

    if (o.eif != null) {
      throw new UnsupportedOperationException(
        'External Id Field can be specified only for upsert operations'
      );
    }

    final AuditResult aud = audit(records[0].getSObjectType(), AccessType.DELETABLE);

    if (!aud.isAuthorized()) {
      if (!o.silent) {
        aud.throwExceptionIfUnauthorized();
      }

      return new DmlResponse(records, new List<Database.DeleteResult>());
    }

    return new DmlResponse(records, Database.delete(records, o.allOrNone));
  }

  global static DmlResponse insertOne(SObject record, DmlRequest o) {
    Utils.requireNonNull(record, 'Record cannot be null');

    return insertMany(new List<SObject>{ record }, o);
  }

  global static DmlResponse insertMany(List<SObject> records, DmlRequest o) {
    Utils.requireNonNull(records, 'Records cannot be null');
    Utils.requireNonNull(o, 'Operation request cannot be null');

    if (records.isEmpty()) {
      return new DmlResponse(records, new List<Database.SaveResult>());
    }

    if (o.eif != null) {
      throw new UnsupportedOperationException(
        'External Id Field can be specified only for upsert operations'
      );
    }

    final AuditResult aud = audit(records[0], AccessType.CREATABLE);

    if (!aud.isAuthorized()) {
      if (!o.silent) {
        aud.throwExceptionIfUnauthorized();
      }

      return new DmlResponse(records, new List<Database.SaveResult>());
    }

    return new DmlResponse(records, Database.insert(records, o.allOrNone));
  }

  global static DmlResponse updateOne(SObject record, DmlRequest o) {
    Utils.requireNonNull(record, 'Record cannot be null');

    return updateMany(new List<SObject>{ record }, o);
  }

  global static DmlResponse updateMany(List<SObject> records, DmlRequest o) {
    Utils.requireNonNull(records, 'Records cannot be null');
    Utils.requireNonNull(o, 'Operation request cannot be null');

    if (records.isEmpty()) {
      return new DmlResponse(records, new List<Database.SaveResult>());
    }

    if (o.eif != null) {
      throw new UnsupportedOperationException(
        'External Id Field can be specified only for upsert operations'
      );
    }

    final AuditResult aud = audit(records[0], AccessType.UPDATABLE);

    if (!aud.isAuthorized()) {
      if (!o.silent) {
        aud.throwExceptionIfUnauthorized();
      }

      return new DmlResponse(records, new List<Database.SaveResult>());
    }

    return new DmlResponse(records, Database.update(records, o.allOrNone));
  }

  global static DmlResponse upsertOne(SObject record, DmlRequest o) {
    Utils.requireNonNull(record, 'Record cannot be null');

    return upsertMany(new List<SObject>{ record }, o);
  }

  global static DmlResponse upsertMany(List<SObject> records, DmlRequest o) {
    Utils.requireNonNull(records, 'Records cannot be null');
    Utils.requireNonNull(o, 'Operation request cannot be null');

    if (records.isEmpty()) {
      return new DmlResponse(records, new List<Database.UpsertResult>());
    }

    final AuditResult aud = audit(records[0], AccessType.UPSERTABLE);

    if (!aud.isAuthorized()) {
      if (!o.silent) {
        aud.throwExceptionIfUnauthorized();
      }

      return new DmlResponse(records, new List<Database.UpsertResult>());
    }

    if (o.eif != null) {
      return new DmlResponse(records, Database.upsert(records, o.eif, o.allOrNone));
    }

    return new DmlResponse(records, Database.upsert(records, o.allOrNone));
  }
}
