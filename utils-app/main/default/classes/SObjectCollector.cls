/**
 * @description A record organizer for <code>SObject</code>.
 * It outputs a map having a key based on the specified criteria
 * and subsequent <code>SObject</code> record falling under that key.
 *
 * @see SObjectCollector.Criteria
 * @since 1.0.13
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class SObjectCollector {
  /**
   * @description The criteria object used by a <code>SObjectCollector</code>
   * to organize <code>SObject</code> records.
   *
   * @see SObjectCollector
   * @since 1.0.13
   */
  global interface Criteria {
    /**
     * @description It returns the value that will be used as key
     * by the <code>SObjectCollector</code>.
     *
     * @param record the record
     * @return the key value
     * @since 1.0.13
     */
    Object getKey(SObject record);

    /**
     * @description It returns the value that will be used as key
     * by the <code>SObjectCollector</code>.
     *
     * @param record the record
     * @return true if the record matches
     * @since 1.0.13
     */
    Boolean matches(SObject record);
  }

  /**
   * @description An implementation of <code>SObjectCollector.Criteria</code>
   * based on <code>Schema.SObjectField</code>.
   *
   * @see SObjectCollector
   * @see SObjectCollector.Criteria
   * @since 1.0.13
   */
  global class FieldCriteria implements Criteria {
    private final Schema.SObjectField field;

    /**
     * @description It creates a criteria that will use the specified field
     * to read the key value for any given record.
     *
     * @param field the field
     * @since 1.0.13
     */
    global FieldCriteria(Schema.SObjectField field) {
      Utils.requireNonNull(field, 'Field cannot be null');

      this.field = field;
    }

    /**
     * @description It reads the record value.
     *
     * @param record the record
     * @return the value
     * @since 1.0.13
     */
    global Object getKey(SObject record) {
      return record.get(field);
    }

    /**
     * @description It checks whether the record can be included.
     *
     * @param record the record
     * @return true if the record matches
     * @since 1.0.13
     */
    global Boolean matches(SObject record) {
      return getKey(record) != null;
    }
  }

  private final Set<SObject> records = new Set<SObject>();

  /**
   * @description It add the record to the list of records that will be evaluated
   * by the criteria organizing them.
   *
   * @param record the record
   * @since 1.0.13
   */
  global void add(SObject record) {
    records.add(record);
  }

  /**
   * @description It add the record to the list of records that will be evaluated
   * by the criteria organizing them.
   *
   * @param records the records
   * @since 1.0.13
   */
  global void addAll(List<SObject> records) {
    this.records.addAll(records);
  }

  /**
   * @description It returns whether the collection is empty or not.
   *
   * @param records the records
   * @return true if the collection is empty
   * @since 1.0.19
   */
  global Boolean isEmpty() {
    return records.isEmpty();
  }

  /**
   * @description It creates an id map of <code>SObject</code> lists based on the criteria.
   * The criteria key value must support casting to the <code>Id</code> type.
   *
   * @param value the criteria, not null
   * @return the map of <code>SObject</code> record lists as organized by the criteria
   * @since 1.0.14
   */
  global Map<Id, List<SObject>> makeIdMapOfLists(Criteria value) {
    Utils.requireNonNull(value, 'Criteria cannot be null');

    Map<Id, List<SObject>> values = new Map<Id, List<SObject>>();

    for (SObject record : records) {
      if (value.matches(record)) {
        Id key = (Id) value.getKey(record);
        List<SObject> l = values.get(key);

        if (l == null) {
          l = new List<SObject>();
          values.put(key, l);
        }

        l.add(record);
      }
    }

    return values;
  }

  /**
   * @description It creates an id map of <code>SObject</code> maps based on the criteria.
   * The criteria key value must support casting to the <code>Id</code> type.
   *
   * @param value the criteria, not null
   * @return the map of <code>SObject</code> record maps as organized by the criteria
   * @since 1.0.14
   */
  global Map<Id, Map<Id, SObject>> makeIdMapOfMaps(Criteria value) {
    Utils.requireNonNull(value, 'Criteria cannot be null');

    Map<Id, Map<Id, SObject>> values = new Map<Id, Map<Id, SObject>>();

    for (SObject record : records) {
      if (record.Id != null && value.matches(record)) {
        Id key = (Id) value.getKey(record);
        Map<Id, SObject> m = values.get(key);

        if (m == null) {
          m = new Map<Id, SObject>();
          values.put(key, m);
        }

        m.put(record.Id, record);
      }
    }

    return values;
  }

  /**
   * @description It returns a map of the records based on their id.
   *
   * @return a map of the records
   * @since 1.0.19
   */
  global Map<Id, SObject> makeMap() {
    return new Map<Id, SObject>(new List<SObject>(records));
  }

  /**
   * @description It creates a map of <code>SObject</code> lists based on the criteria.
   *
   * @param value the criteria, not null
   * @return the map of <code>SObject</code> record lists as organized by the criteria
   * @since 1.0.13
   */
  global Map<Object, List<SObject>> makeMapOfLists(Criteria value) {
    Utils.requireNonNull(value, 'Criteria cannot be null');

    Map<Object, List<SObject>> values = new Map<Object, List<SObject>>();

    for (SObject record : records) {
      if (value.matches(record)) {
        Object key = value.getKey(record);
        List<SObject> l = values.get(key);

        if (l == null) {
          l = new List<SObject>();
          values.put(key, l);
        }

        l.add(record);
      }
    }

    return values;
  }

  /**
   * @description It creates a map of <code>SObject</code> maps based on the criteria.
   *
   * @param value the criteria, not null
   * @return the map of <code>SObject</code> record maps as organized by the criteria
   * @since 1.0.13
   */
  global Map<Object, Map<Id, SObject>> makeMapOfMaps(Criteria value) {
    Utils.requireNonNull(value, 'Criteria cannot be null');

    Map<Object, Map<Id, SObject>> values = new Map<Object, Map<Id, SObject>>();

    for (SObject record : records) {
      if (record.Id != null && value.matches(record)) {
        Object key = value.getKey(record);
        Map<Id, SObject> m = values.get(key);

        if (m == null) {
          m = new Map<Id, SObject>();
          values.put(key, m);
        }

        m.put(record.Id, record);
      }
    }

    return values;
  }

  /**
   * @description It returns the current set of records.
   *
   * @return the set records
   * @since 1.0.19
   */
  global Set<SObject> values() {
    return records;
  }

  /**
   * @description It creates a map of <code>SObject</code> lists
   * organized by unique record field values.
   *
   * @param f the field, not null
   * @param records the records, not null
   * @return the records organized by field values
   * @see SObjectCollector#makeMapOfLists
   * @since 1.1
   */
  global static Map<Object, List<SObject>> collectBy(Schema.SObjectField f, List<SObject> records) {
    Utils.requireNonNull(f, 'Field cannot be null');
    Utils.requireNonNull(records, 'Records cannot be null');

    final SObjectCollector coll = new SObjectCollector();

    coll.addAll(records);

    return coll.makeMapOfLists(new FieldCriteria(f));
  }
}
