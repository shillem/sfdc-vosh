@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.CyclomaticComplexity')
global inherited sharing class Fls {
  global enum AccessType {
    CREATABLE,
    DELETABLE,
    READABLE,
    UPDATABLE,
    UPSERTABLE
  }

  global class AuditException extends Exception {
    private AuditException(Object value, AccessType aType) {
      setMessage(aType + ' is not allowed on ' + value);
    }
  }

  global class OpReq {
    private Schema.SObjectField eif;
    private Boolean allOrNone;
    private Boolean silent;

    global OpReq() {
      allOrNone = false;
      silent = false;
    }

    global OpReq any() {
      allOrNone = false;
      return this;
    }

    global OpReq all() {
      allOrNone = true;
      return this;
    }

    global OpReq externalIdField(Schema.SObjectField value) {
      eif = value;
      return this;
    }

    global OpReq failSilently() {
      silent = true;
      return this;
    }
  }

  global class OpRes {
    private List<SObject> failed;
    private List<Object> results;
    private List<SObject> submitted;
    private List<SObject> succeeded;

    private OpRes(List<SObject> submitted) {
      this(submitted, new List<Object>());
    }

    private OpRes(List<SObject> submitted, List<Object> results) {
      this.submitted = submitted;
      this.results = results;
    }

    global List<SObject> getFailed() {
      if (failed == null) {
        load();
      }

      return failed;
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
  }

  global class Report {
    private final Schema.SObjectType sType;
    private final AccessType aType;

    private Boolean objectFailure;
    private Set<Schema.SObjectField> fieldFailures;

    private Report(Fls value) {
      sType = value.sType;
      aType = value.aType;

      objectFailure = false;
      fieldFailures = new Set<Schema.SObjectField>();
    }

    global Boolean isAuthorized() {
      return !objectFailure || fieldFailures.isEmpty();
    }

    global Set<Schema.SObjectField> getFieldFailures() {
      return fieldFailures;
    }

    global void throwExceptionIfUnauthorized() {
      if (!isAuthorized()) {
        throw new ReportException(this);
      }
    }
  }

  global class ReportException extends Exception {
    private final Report value;

    private ReportException(Report value) {
      this.value = value;

      String message = value.aType + ' not allowed for: ';
      List<String> objs = new List<String>();

      if (value.objectFailure) {
        objs.add(String.valueOf(value.sType));
      }

      if (!value.fieldFailures.isEmpty()) {
        for (Schema.SObjectField field : value.fieldFailures) {
          objs.add(String.valueOf(field));
        }
      }

      setMessage(message + String.join(objs, ', '));
    }

    global Report getReport() {
      return value;
    }
  }

  private final Schema.SObjectType sType;
  private final AccessType aType;
  private final Set<Schema.SObjectField> fields;

  global Fls(Schema.SObjectType sType, AccessType aType) {
    Utils.requireNonNull(sType, 'SObject sType cannot be null');
    Utils.requireNonNull(aType, 'Access sType cannot be null');

    this.sType = sType;
    this.aType = aType;
    this.fields = new Set<Schema.SObjectField>();
  }

  global Report audit() {
    final Report rep = new Report(this);

    rep.objectFailure = !audit(sType, aType, false);

    for (Schema.SObjectField field : fields) {
      if (!audit(field, aType, false)) {
        rep.fieldFailures.add(field);
      }
    }

    return rep;
  }

  global Fls queue(Schema.SObjectField field) {
    Utils.requireNonNull(field, 'Field cannot be null');

    fields.add(field);

    return this;
  }

  global Fls queue(Set<Schema.SObjectField> fields) {
    Utils.requireNonNull(fields, 'Fields cannot be null');

    fields.addAll(fields);

    return this;
  }

  global static Boolean audit(Schema.SObjectField field, AccessType aType) {
    return audit(field, aType, true);
  }

  global static Boolean audit(
    Schema.SObjectField field,
    AccessType aType,
    Boolean throwExceptionIfUnauthorized
  ) {
    Utils.requireNonNull(field, 'Field cannot be null');
    Utils.requireNonNull(aType, 'Access type cannot be null');
    Utils.requireNonNull(throwExceptionIfUnauthorized, 'Throw exception cannot be null');

    Boolean result;

    final DescribeFieldResult dfr = Describer.getInstance().getFieldDescribe(field);

    switch on (aType) {
      when CREATABLE {
        result = dfr.isCreateable();
      }
      when READABLE {
        result = dfr.isAccessible();
      }
      when UPDATABLE {
        result = dfr.isUpdateable();
      }
      when UPSERTABLE {
        result = dfr.isCreateable() && dfr.isUpdateable();
      }
      when else {
        throw new UnsupportedOperationException(aType.name());
      }
    }

    if (!result && throwExceptionIfUnauthorized) {
      throw new AuditException(field, aType);
    }

    return result;
  }

  global static Boolean audit(Schema.SObjectType sType, AccessType aType) {
    return audit(sType, aType, true);
  }

  global static Boolean audit(
    Schema.SObjectType sType,
    AccessType aType,
    Boolean throwExceptionIfUnauthorized
  ) {
    Utils.requireNonNull(sType, 'SObject type cannot be null');
    Utils.requireNonNull(aType, 'Access type cannot be null');
    Utils.requireNonNull(throwExceptionIfUnauthorized, 'Throw exception cannot be null');

    Boolean result;

    final DescribeSObjectResult dsr = Describer.getInstance().getObjectDescribe(sType);

    switch on (aType) {
      when CREATABLE {
        result = dsr.isCreateable();
      }
      when DELETABLE {
        result = dsr.isDeletable();
      }
      when READABLE {
        result = dsr.isAccessible();
      }
      when UPDATABLE {
        result = dsr.isUpdateable();
      }
      when UPSERTABLE {
        result = dsr.isCreateable() && dsr.isUpdateable();
      }
      when else {
        throw new UnsupportedOperationException(aType.name());
      }
    }

    if (!result && throwExceptionIfUnauthorized) {
      throw new AuditException(sType, aType);
    }

    return result;
  }

  global static Report audit(SObject record, AccessType aType) {
    Utils.requireNonNull(record, 'Record cannot be null');

    final Fls instance = new Fls(record.getSObjectType(), aType);

    Map<String, SObjectField> fields = Describer.getInstance().getObjectFieldMap(instance.sType);

    for (String field : record.getPopulatedFieldsAsMap().keySet()) {
      instance.queue(fields.get(field));
    }

    return instance.audit();
  }

  global static OpRes deleteOne(SObject record, OpReq o) {
    Utils.requireNonNull(record, 'Record cannot be null');

    return deleteMany(new List<SObject>{ record }, o);
  }

  global static OpRes deleteMany(List<SObject> records, OpReq o) {
    Utils.requireNonNull(records, 'Records cannot be null');
    Utils.requireNonNull(o, 'Operation request cannot be null');

    if (records.isEmpty()) {
      return new OpRes(records);
    }

    if (o.eif != null) {
      throw new UnsupportedOperationException(
        'External Id Field can be specified only for upsert operations'
      );
    }
    
    if (!audit(records[0].getSObjectType(), AccessType.DELETABLE)) {
      if (!o.silent) {
        throw new AuditException(records[0].getSObjectType(), AccessType.DELETABLE);
      }

      return new OpRes(records, new List<Database.DeleteResult>());
    }

    return new OpRes(records, Database.delete(records, o.allOrNone));
  }

  global static OpRes insertOne(SObject record, OpReq o) {
    Utils.requireNonNull(record, 'Record cannot be null');

    return insertMany(new List<SObject>{ record }, o);
  }

  global static OpRes insertMany(List<SObject> records, OpReq o) {
    Utils.requireNonNull(records, 'Records cannot be null');
    Utils.requireNonNull(o, 'Operation request cannot be null');

    if (records.isEmpty()) {
      return new OpRes(records);
    }

    if (o.eif != null) {
      throw new UnsupportedOperationException(
        'External Id Field can be specified only for upsert operations'
      );
    }

    final Report rep = audit(records[0], AccessType.CREATABLE);

    if (!o.silent) {
      rep.throwExceptionIfUnauthorized();
    }

    if (!rep.isAuthorized()) {
      return new OpRes(records, new List<Database.SaveResult>());
    }

    return new OpRes(records, Database.insert(records, o.allOrNone));
  }

  global static OpRes updateOne(SObject record, OpReq o) {
    Utils.requireNonNull(record, 'Record cannot be null');

    return updateMany(new List<SObject>{ record }, o);
  }

  global static OpRes updateMany(List<SObject> records, OpReq o) {
    Utils.requireNonNull(records, 'Records cannot be null');
    Utils.requireNonNull(o, 'Operation request cannot be null');

    if (records.isEmpty()) {
      return new OpRes(records);
    }

    if (o.eif != null) {
      throw new UnsupportedOperationException(
        'External Id Field can be specified only for upsert operations'
      );
    }

    final Report rep = audit(records[0], AccessType.UPDATABLE);

    if (!o.silent) {
      rep.throwExceptionIfUnauthorized();
    }

    if (!rep.isAuthorized()) {
      return new OpRes(records, new List<Database.SaveResult>());
    }

    return new OpRes(records, Database.update(records, o.allOrNone));
  }

  global static OpRes upsertOne(SObject record, OpReq o) {
    Utils.requireNonNull(record, 'Record cannot be null');

    return upsertMany(new List<SObject>{ record }, o);
  }

  global static OpRes upsertMany(List<SObject> records, OpReq o) {
    Utils.requireNonNull(records, 'Records cannot be null');
    Utils.requireNonNull(o, 'Operation request cannot be null');

    if (records.isEmpty()) {
      return new OpRes(records);
    }

    final Report rep = audit(records[0], AccessType.UPSERTABLE);

    if (!o.silent) {
      rep.throwExceptionIfUnauthorized();
    }

    if (!rep.isAuthorized()) {
      return new OpRes(records, new List<Database.UpsertResult>());
    }

    if (o.eif != null) {
      return new OpRes(records, Database.upsert(records, o.eif, o.allOrNone));
    }

    return new OpRes(records, Database.upsert(records, o.allOrNone));
  }
}
