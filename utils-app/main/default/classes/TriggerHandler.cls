@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class TriggerHandler {
  /**
   * @description The abstract class to create a SObject trigger logic from.
   * The class provides methods that will be be invoked depending on the trigger's operation type.
   * Any of those methods can be overridden by the extending class to implement the needed logic.
   * <p>
   * This class is meant to be used exclusively in the <code>Trigger</code> context because
   * it relies on its <a href="https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_triggers_context_variables.htm">specific variables</a>.
   *
   * @see TriggerHandler#enable(System.Type) enable
   * @since 1.0.1
   */
  global abstract class Routine {
    private Map<String, Object> options;
    private Map<Id, String> recordTypeIds;
    private Map<String, Id> recordTypeDeveloperNames;

    /**
     * @description It can be overridden to performs operations on the record passed
     * when the trigger operation is <code>AFTER_DELETE</code>.
     *
     * @param record the record passed by the trigger
     * @since 1.0.1
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    global virtual void afterDelete(SObject record) {
    }

    /**
     * @description It can be overridden to performs operations on the record passed
     * when the trigger operation is <code>AFTER_DELETE</code>.
     *
     * @param record the record passed by the trigger
     * @since 1.0.1
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    global virtual void afterInsert(SObject record) {
    }

    /**
     * @description It can be overridden to performs operations on the record passed
     * when the trigger operation is <code>AFTER_UNDELETE</code>.
     *
     * @param record the record passed by the trigger
     * @since 1.0.1
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    global virtual void afterUndelete(SObject record) {
    }

    /**
     * @description It can be overridden to performs operations on the record passed
     * when the trigger operation is <code>AFTER_UPDATE</code>.
     *
     * @param record the record passed by the trigger
     * @since 1.0.1
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    global virtual void afterUpdate(SObject stored, SObject memory) {
    }

    /**
     * @description It can be overridden to performs operations on the record passed
     * when the trigger operation is <code>BEFORE_DELETE</code>.
     *
     * @param record the record passed by the trigger
     * @since 1.0.1
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    global virtual void beforeDelete(SObject record) {
    }

    /**
     * @description It can be overridden to performs operations on the record passed
     * when the trigger operation is <code>BEFORE_INSERT</code>.
     *
     * @param record the record passed by the trigger
     * @since 1.0.1
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    global virtual void beforeInsert(SObject record) {
    }

    /**
     * @description It can be overridden to performs operations on the record passed
     * when the trigger operation is <code>BEFORE_UPDATE</code>.
     *
     * @param record the record passed by the trigger
     * @since 1.0.1
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    global virtual void beforeUpdate(SObject stored, SObject memory) {
    }

    /**
     * @description It checks whether all value for the given fields differ between 2 records.
     *
     * @param record1 the first record to check
     * @param record2 the second record to check
     * @param fields the fields to check upon
     * @return true if all the field values differ between the records, otherwise false
     * @since 1.1
     */
    global Boolean allDiffer(SObject record1, SObject record2, List<Schema.SObjectField> fields) {
      for (Schema.SObjectField f : fields) {
        if (record1.get(f) == record2.get(f)) {
          return false;
        }
      }

      return true;
    }

    /**
     * @description It checks whether any value for the given fields differ between 2 records.
     *
     * @param record1 the first record to check
     * @param record2 the second record to check
     * @param fields the fields to check upon
     * @return true if any of the field values differ between the records, otherwise false
     * @since 1.1
     */
    global Boolean anyDiffer(SObject record1, SObject record2, List<Schema.SObjectField> fields) {
      for (Schema.SObjectField f : fields) {
        if (record1.get(f) != record2.get(f)) {
          return true;
        }
      }

      return false;
    }

    /**
     * @description It executes the implemented logic on the records passed
     * in the <code>Trigger</code> context.
     *
     * @since 1.0.1
     */
    global virtual void execute() {
      pre();

      switch on (getOperationType()) {
        when BEFORE_INSERT {
          for (Integer i = 0, size = Trigger.new.size(); i < size; i++) {
            beforeInsert(Trigger.new[i]);
          }
        }
        when BEFORE_UPDATE {
          for (Integer i = 0, size = Trigger.old.size(); i < size; i++) {
            beforeUpdate(Trigger.old[i], Trigger.new[i]);
          }
        }
        when BEFORE_DELETE {
          for (Integer i = 0, size = Trigger.old.size(); i < size; i++) {
            beforeDelete(Trigger.old[i]);
          }
        }
        when AFTER_INSERT {
          for (Integer i = 0, size = Trigger.new.size(); i < size; i++) {
            afterInsert(Trigger.new[i]);
          }
        }
        when AFTER_UPDATE {
          for (Integer i = 0, size = Trigger.old.size(); i < size; i++) {
            afterUpdate(Trigger.old[i], Trigger.new[i]);
          }
        }
        when AFTER_DELETE {
          for (Integer i = 0, size = Trigger.old.size(); i < size; i++) {
            afterDelete(Trigger.old[i]);
          }
        }
        when AFTER_UNDELETE {
          for (Integer i = 0, size = Trigger.new.size(); i < size; i++) {
            afterUndelete(Trigger.new[i]);
          }
        }
      }

      post();
    }

    /**
     * @description It returns the trigger operation type.
     *
     * @return the operation type
     * @since 1.0.24
     */
    global System.TriggerOperation getOperationType() {
      return Trigger.operationType;
    }

    /**
     * @descriptions It returns the option value for the given option name.
     * If the option name is not found, it returns null.
     * <p>
     * Options are read from the corresponding <code>Cs_TriggerHandlerRoutine__c</code>
     * custom setting record.
     *
     * @param value the option name
     * @return the option value
     * @since 1.1
     */
    global Object getOption(String name) {
      return options.get(name);
    }

    /**
     * @description It returns the record type <code>Id</code> of a record type developer name.
     *
     * @param value the record type developer name
     * @return the <code>Id</code> associated with the record type developer name
     * @since 1.0.16
     */
    global Id getRecordTypeId(String value) {
      return getRecordTypeDeveloperNames().get(value);
    }

    private Map<Id, String> getRecordTypeIds() {
      if (recordTypeIds == null) {
        getRecordTypeDeveloperNames();

        recordTypeIds = new Map<Id, String>();

        for (String developerName : recordTypeDeveloperNames.keySet()) {
          recordTypeIds.put(recordTypeDeveloperNames.get(developerName), developerName);
        }
      }

      return recordTypeIds;
    }

    /**
     * @description It returns the record type developer name of a record type <code>Id</code>.
     *
     * @param value the record type <code>Id</code>
     * @return the record type developer name associated with the <code>Id</code>
     * @since 1.0.16
     */
    global String getRecordTypeDeveloperName(Id value) {
      return getRecordTypeIds().get(value);
    }

    private Map<String, Id> getRecordTypeDeveloperNames() {
      if (recordTypeDeveloperNames == null) {
        recordTypeDeveloperNames = SchemaUtils.getRecordTypeNames(getSObjectType());
      }

      return recordTypeDeveloperNames;
    }

    /**
     * @description It must be overridden to state the <code>SObject</code> type the trigger logic handles.
     *
     * @return the <code>SObject</code> type
     * @since 1.0.1
     */
    global abstract Schema.SObjectType getSObjectType();

    /**
     * @description It returns a set of record ids that have been tagged under the given key.
     *
     * @param key an arbitrary key string
     * @return the set containing the tagged ids
     * @see #isTagged(Id, String) isTagged
     * @see #tag(Id, String) tag
     * @since 1.0.8
     */
    global Set<Id> getTaggedIds(String key) {
      Set<Id> values = TAGS.get(key);

      if (values == null) {
        values = new Set<Id>();

        TAGS.put(key, values);
      }

      return values;
    }

    /**
     * @description It checks whether a given record id has been tagged.
     * <p>
     * Trigger logic can be tricky to write. A trigger might be invoked multiple times
     * on the same record depending on what the implementing class or other triggers do.
     * To prevent a trigger to be run on a previously processed record it's possible to tag said
     * record id and later check for its presence in order to skip reprocessing it.
     *
     * @param recordId the record id to check
     * @param key an arbitrary key string to file the id under
     * @return true if the record is tagged, otherwise false
     * @see #tag(Id, String) tag
     * @see #untag(Id, String) tag
     * @since 1.0.3
     */
    global Boolean isTagged(Id recordId, String key) {
      return getTaggedIds(key).contains(recordId);
    }

    /**
     * @description It checks whether the value of a given field matches between 2 records.
     *
     * @param record1 the first record check
     * @param record2 the second record check
     * @param field the field to check upon
     * @return true if the field value is the same for both records, otherwise false
     * @since 1.0.18
     */
    global Boolean match(SObject record1, SObject record2, Schema.SObjectField field) {
      return record1.get(field) == record2.get(field);
    }

    /**
     * @description It can be overridden to execute arbitrary logic
     * before the <code>Trigger</code> record looping takes place.
     *
     * @since 1.0.1
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    global virtual void pre() {
    }

    /**
     * @description It can be overridden to execute arbitrary logic
     * after the <code>Trigger</code> record has taken place.
     *
     * @since 1.0.1
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    global virtual void post() {
    }

    /**
     * @description It tags a given record id.
     *
     * @param recordId the record id to check
     * @param key an arbitrary key string to file the id under
     * @see #isTagged(Id, String) isTagged
     * @see #tag(Id, String) tag
     * @since 1.0.3
     */
    global void tag(Id recordId, String key) {
      getTaggedIds(key).add(recordId);
    }

    /**
     * @description It untags a given record id.
     *
     * @param recordId the record id to check
     * @param key an arbitrary key string to file the id under
     * @see #isTagged(Id, String) isTagged
     * @see #untag(Id, String) untag
     * @since 1.0.3
     */
    global void untag(Id recordId, String key) {
      getTaggedIds(key).remove(recordId);
    }
  }

  global class Spec {
    private final System.Type t;

    private Boolean disabled;
    private Map<String, Object> options;
    private Decimal order;
    private Schema.Cs_TriggerHandlerRoutine__c record;

    global Spec(System.Type value) {
      Utils.requireNonNull(value, 'Type cannot be null');

      t = value;
    }

    private Schema.Cs_TriggerHandlerRoutine__c enable() {
      if (record == null) {
        record = new Schema.Cs_TriggerHandlerRoutine__c();
      }

      record.ClassName__c = t.getName();
      record.Name = new Utils.Hasher().hash(t.getName());
      record.Is_Disabled__c = false;
      record.SObjectType__c = String.valueOf(((Routine) t.newInstance()).getSObjectType());

      if (options != null) {
        record.Json_Options__c = JSON.serialize(options);
      }

      if (order != null) {
        record.Sort_Order__c = order;
      }

      return record;
    }

    global System.Type getType() {
      return t;
    }

    global Boolean isDisabled() {
      return disabled;
    }

    global Object getOption(String name) {
      return options != null ? options.get(name) : null;
    }

    global Decimal getOrder() {
      return order;
    }

    global Spec setOptions(Map<String, Object> value) {
      options = value;

      return this;
    }

    global Spec setOrder(Decimal value) {
      order = value;

      return this;
    }
  }

  private static final Map<String, Set<Id>> TAGS = new Map<String, Set<Id>>();

  /**
   * @description Invokes any <code>TriggerHandler.Routine</code> extending classes that have been enabled,
   * for the SObject. The enabled classes will be retrieved by querying
   * all the <code>Cs_TriggerHandlerRoutine__c</code> custom setting records
   * that match the SObject type parameter.
   *
   * @param value the <code>SObjectType</code> that will be used collect all the <code>TriggerHandler.Routine</code>, not null
   * @see #enable(System.Type) enable
   * @since 1.0.3
   */
  @SuppressWarnings('PMD.ApexCRUDViolation')
  global static void execute(Schema.SObjectType value) {
    Utils.requireNonNull(value, 'SObjectType cannot be null');

    for (Schema.Cs_TriggerHandlerRoutine__c rtn : [
      SELECT ClassName__c, Json_Options__c
      FROM Cs_TriggerHandlerRoutine__c
      WHERE SObjectType__c = :String.valueOf(value) AND Is_Disabled__c = FALSE
      ORDER BY Sort_Order__c, ClassName__c
    ]) {
      final System.Type t = System.Type.forName(rtn.ClassName__c);

      if (t == null || !Routine.class.isAssignableFrom(t)) {
        continue;
      }

      final Routine instance = ((Routine) t.newInstance());

      instance.options = (Map<String, Object>) JSON.deserializeUntyped(
        rtn.Json_Options__c != null && rtn.Json_Options__c.startsWith('{')
          ? rtn.Json_Options__c
          : '{}'
      );

      instance.execute();
    }
  }

  /**
   * @description Disables a <code>TriggerHandler.Routine</code> extending class that,
   * when matching the SObject of reference, will be invoked when the coupling trigger is fired.
   * The method ticks as disabled a corresponding <code>Cs_TriggerHandlerRoutine__c</code>
   * custom setting record that bears the class' name if it exists.
   *
   * @param value the .class extending the abstract class <code>TriggerHandler.Routine</code>, not null
   * @see #disable(Set<System.Type>) disable
   * @since 1.0.3
   */
  global static void disable(System.Type value) {
    disable(new Set<System.Type>{ value });
  }

  /**
   * @description Disables <code>TriggerHandler.Routine</code> extending classes that,
   * when matching the SObject of reference, will be invoked when the coupling trigger is fired.
   * The method ticks as disabled the corresponding <code>Cs_TriggerHandlerRoutine__c</code>
   * custom setting records that bear the class' name if it exists.
   *
   * @param values the list containing classes extending the abstract class <code>TriggerHandler.Routine</code>, not null
   * @see #enable(System.Type) enable
   * @see #enable(Map<System.Type, Decimal>) enable
   * @since 1.0.12
   */
  @SuppressWarnings('PMD.ApexCRUDViolation')
  global static void disable(Set<System.Type> values) {
    Utils.requireNonNull(values, 'Types cannot be null');

    if (values.isEmpty()) {
      return;
    }

    final Set<String> typeNames = new Set<String>();

    for (System.Type t : values) {
      typeNames.add(t.getName());
    }

    final List<Schema.Cs_TriggerHandlerRoutine__c> records = [
      SELECT ClassName__c
      FROM Cs_TriggerHandlerRoutine__c
      WHERE ClassName__c IN :typeNames AND Is_Disabled__c = FALSE
    ];

    for (Schema.Cs_TriggerHandlerRoutine__c r : records) {
      r.Is_Disabled__c = true;
    }

    update records;
  }

  /**
   * @description Enables a <code>TriggerHandler.Routine</code> extending class that,
   * when matching the SObject of reference, will be invoked when the coupling trigger is fired.
   * The coupling trigger will have to call <code>TriggerHandler.execute</code>
   * for the class to be invoked.
   * <p>
   * The method creates - if it doesn't exist, or ticks as enabled, a corresponding
   * <code>Cs_TriggerHandlerRoutine__c</code> custom setting record that bears the class' name.
   *
   * @param value the class extending the abstract class <code>TriggerHandler.Routine</code>, not null
   * @throws UnsupportedOperationException if the type doesn't extend <code>TriggerHandler.Routine</code>
   * @see #enable(Map<System.Type, Integer>) enable
   * @since 1.0.3
   */
  global static void enable(System.Type value) {
    enable(new List<Spec>{ new Spec(value) });
  }

  /**
   * @description Enables <code>TriggerHandler.Routine</code> extending classes that,
   * when matching the SObject of reference, will be invoked when the coupling trigger is fired.
   * The coupling trigger will have to call <code>TriggerHandler.execute</code>
   * for the classes to be invoked.
   * <p>
   * The method creates - if they don't exist, or ticks as enabled, the corresponding
   * <code>Cs_TriggerHandlerRoutine__c</code> custom setting record that bears the class' name.
   *
   * @param values the specification list of the triggers extending the abstract class <code>TriggerHandler.Routine</code> to enable, not null
   * @throws UnsupportedOperationException if the type of any of the specification doesn't extend <code>TriggerHandler.Routine</code>
   * @see #execute(Schema.SObjectType) execute
   * @since 1.0.12
   */
  @SuppressWarnings('PMD.ApexCRUDViolation')
  global static void enable(List<Spec> values) {
    Utils.requireNonNull(values, 'Specs cannot be null');

    if (values.isEmpty()) {
      return;
    }

    final Map<String, Spec> tms = new Map<String, Spec>();

    for (Spec d : values) {
      final String name = d.t.getName();

      if (!Routine.class.isAssignableFrom(d.t)) {
        throw new System.UnsupportedOperationException(
          'Cannot enable ' + name + ' because it does not extend vosh.TriggerHandler.Routine class'
        );
      }

      tms.put(name, d);
    }

    for (Schema.Cs_TriggerHandlerRoutine__c r : [
      SELECT ClassName__c
      FROM Cs_TriggerHandlerRoutine__c
      WHERE ClassName__c IN :tms.keySet()
    ]) {
      tms.get(r.ClassName__c).record = r;
    }

    final List<Schema.Cs_TriggerHandlerRoutine__c> records = new List<Schema.Cs_TriggerHandlerRoutine__c>();

    for (Spec d : values) {
      records.add(d.enable());
    }

    upsert records;
  }

  @SuppressWarnings('PMD.ApexCRUDViolation')
  global static Map<System.Type, Spec> fetch(Set<System.Type> values) {
    Utils.requireNonNull(values, 'Types cannot be null');

    final Map<String, System.Type> typeNames = new Map<String, System.Type>();

    for (System.Type t : values) {
      typeNames.put(t.getName(), t);
    }

    final Map<System.Type, Spec> result = new Map<System.Type, Spec>();

    for (Schema.Cs_TriggerHandlerRoutine__c r : [
      SELECT ClassName__c, Is_Disabled__c, Json_Options__c, Sort_Order__c
      FROM Cs_TriggerHandlerRoutine__c
      WHERE ClassName__c IN :typeNames.keySet()
    ]) {
      final System.Type t = typeNames.get(r.ClassName__c);
      final Spec s = new Spec(t);

      s.disabled = r.Is_Disabled__c;

      if (r.Json_Options__c != null && r.Json_Options__c.startsWith('{')) {
        s.options = (Map<String, Object>) JSON.deserializeUntyped(r.Json_Options__c);
      }

      if (r.Sort_Order__c != null) {
        s.order = r.Sort_Order__c;
      }

      result.put(t, s);
    }

    return result;
  }
}
