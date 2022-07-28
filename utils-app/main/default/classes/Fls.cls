@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class Fls {
  global class AuditException extends Exception {
    private AuditException(Object value, System.AccessType aType) {
      setMessage(aType + ' is not allowed on ' + value);
    }
  }

  global class Report {
    private final Schema.SObjectType sType;
    private final System.AccessType aType;

    private Boolean objectFailure;
    private Set<Schema.SObjectField> fieldFailures;

    private Report(Fls fls) {
      sType = fls.sType;
      aType = fls.aType;

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
  private final System.AccessType aType;
  private final Set<Schema.SObjectField> fields;

  global Fls(Schema.SObjectType sType, System.AccessType aType) {
    Utils.requireNonNull(sType, 'SObject sType cannot be null');
    Utils.requireNonNull(aType, 'Access sType cannot be null');

    this.sType = sType;
    this.aType = aType;
    this.fields = new Set<Schema.SObjectField>();
  }

  global Report audit() {
    Report rep = new Report(this);

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

  global static Boolean audit(Schema.SObjectField field, System.AccessType aType) {
    return audit(field, aType, true);
  }

  global static Boolean audit(
    Schema.SObjectField field,
    System.AccessType aType,
    Boolean throwExceptionIfUnauthorized
  ) {
    Boolean result;

    DescribeFieldResult dfr = Describer.getInstance().getFieldDescribe(field);

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
      when else {
        throw new UnsupportedOperationException(aType.name());
      }
    }

    if (!result && throwExceptionIfUnauthorized) {
      throw new AuditException(field, aType);
    }

    return result;
  }

  global static Boolean audit(Schema.SObjectType sType, System.AccessType aType) {
    return audit(sType, aType, true);
  }

  global static Boolean audit(
    Schema.SObjectType sType,
    System.AccessType aType,
    Boolean throwExceptionIfUnauthorized
  ) {
    Utils.requireNonNull(sType, 'SObject type cannot be null');
    Utils.requireNonNull(aType, 'Access type cannot be null');
    Utils.requireNonNull(throwExceptionIfUnauthorized, 'Throw exception cannot be null');

    Boolean result;

    DescribeSObjectResult dsr = Describer.getInstance().getObjectDescribe(sType);

    switch on (aType) {
      when CREATABLE {
        result = dsr.isCreateable();
      }
      when READABLE {
        result = dsr.isAccessible();
      }
      when UPDATABLE {
        result = dsr.isUpdateable();
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

  global static Report audit(SObject record, System.AccessType aType) {
    Utils.requireNonNull(record, 'Record cannot be null');

    Fls instance = new Fls(record.getSObjectType(), aType);

    Map<String, SObjectField> fields = Describer.getInstance().getObjectFieldMap(instance.sType);

    for (String field : record.getPopulatedFieldsAsMap().keySet()) {
      instance.queue(fields.get(field));
    }

    return instance.audit();
  }
}
