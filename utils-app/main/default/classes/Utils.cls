@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.StdCyclomaticComplexity')
global inherited sharing class Utils {
  /**
   * A wrapper for <code>Decimal</code> that makes it easy to perform common math computations.
   *
   * @since 1.0.20
   */
  global class EasyDecimal {
    private Decimal value;

    /**
     * It creates an instance with the provided <code>Decimal</code> value.
     *
     * @param value the value, not null
     * @since 1.0.20
     */
    global EasyDecimal(Decimal value) {
      requireNonNull(value, 'Value cannot be null');

      this.value = value;
    }

    /**
     * It creates a new instance whose value equals to the original value
     * plus the calculated percentage value.
     *
     * @param percentage the percentage, not null
     * @return the new instance
     * @since 1.0.20
     */
    global EasyDecimal addPct(Decimal percentage) {
      requireNonNull(percentage, 'Percentage cannot be null');

      return new EasyDecimal(value + (value / 100 * percentage));
    }

    /**
     * It returns a clone instance.
     *
     * @return the <code>Decimal</code> value
     * @since 1.0.20
     */
    global EasyDecimal copy() {
      return new EasyDecimal(value);
    }

    /**
     * It returns the <code>Decimal</code> value associated with the instance.
     *
     * @return the <code>Decimal</code> value
     * @since 1.0.20
     */
    global Decimal decimalValue() {
      return value;
    }

    /**
     * It creates a new instance whose value equals to the original value
     * divided by the provided factor.
     *
     * @param factor the factor, not null
     * @return the new instance
     * @since 1.0.20
     */
    global EasyDecimal divide(Decimal factor) {
      requireNonNull(factor, 'Factor cannot be null');

      return new EasyDecimal(value / factor);
    }

    /**
     * @see Object#equals(Object) equals
     * @since 1.0.20
     */
    global Boolean equals(Object instance) {
      if (instance instanceof EasyDecimal) {
        return value == ((EasyDecimal) instance).value;
      }

      return false;
    }

    /**
     * @see Object#hashCode() hashCode
     * @since 1.0.20
     */
    global Integer hashCode() {
      return 31 * 7 + String.valueOf(value).hashCode();
    }

    /**
     * It creates a new instance whose value equals to the original value
     * minus the provided value.
     *
     * @param value the value, not null
     * @return the new instance
     * @see #minus(EasyDecimal) minus
     * @since 1.0.20
     */
    global EasyDecimal minus(Decimal value) {
      requireNonNull(value, 'Value cannot be null');

      return new EasyDecimal(this.value - value);
    }

    /**
     * It creates a new instance whose value equals to the original value
     * minus the provided value.
     *
     * @param value the value, not null
     * @return the new instance
     * @see #minus(Decimal) minus
     * @since 1.0.20
     */
    global EasyDecimal minus(EasyDecimal value) {
      requireNonNull(value, 'Value cannot be null');

      return new EasyDecimal(this.value - value.value);
    }

    /**
     * It creates a new instance whose value equals to the original value
     * multiplied by the provided factor.
     *
     * @param factor the factor, not null
     * @return the new instance
     * @since 1.0.20
     */
    global EasyDecimal multiply(Decimal factor) {
      requireNonNull(factor, 'Factor cannot be null');

      return new EasyDecimal(value * factor);
    }

    /**
     * It returns the value in percentage of the provided value in the instance value.
     *
     * @param value the value, not null
     * @return the value
     * @since 1.0.20
     */
    global Decimal rightPctOf(Decimal value) {
      requireNonNull(value, 'Value cannot be null');

      return value / this.value * 100;
    }

    /**
     * It creates a new instance whose value equals to the calculated percentage value
     * of the instance value.
     *
     * @param percentage the percentage, not null
     * @return the new instance
     * @since 1.0.20
     */
    global EasyDecimal pct(Decimal percentage) {
      requireNonNull(percentage, 'Percentage cannot be null');

      return new EasyDecimal(value / 100 * percentage);
    }

    /**
     * It returns the value in percentage of the instance value in the provided value.
     *
     * @param value the value, not null
     * @return the value
     * @since 1.0.20
     */
    global Decimal pctOf(Decimal value) {
      requireNonNull(value, 'Value cannot be null');

      return this.value / value * 100;
    }

    /**
     * It creates a new instance whose value equals to the original value
     * plus the provided factor.
     *
     * @param value the value, not null
     * @return the new instance
     * @see #plus(EasyDecimal) plus
     * @since 1.0.20
     */
    global EasyDecimal plus(Decimal value) {
      requireNonNull(value, 'Value cannot be null');

      return new EasyDecimal(this.value + value);
    }

    /**
     * It creates a new instance whose value equals to the original value
     * minus the provided value.
     *
     * @param value the value, not null
     * @return the new instance
     * @see #plus(Decimal) plus
     * @since 1.0.20
     */
    global EasyDecimal plus(EasyDecimal value) {
      requireNonNull(value, 'Value cannot be null');

      return new EasyDecimal(this.value + value.value);
    }

    global override String toString() {
      return String.valueOf(value);
    }
  }

  /**
   * An object that holds a key-value pair.
   * The objects implements <code>Comparable</code> on the key value for sorting purposes.
   *
   * @since 1.0.1
   */
  @JsonAccess(serializable='always' deserializable='always')
  global virtual class Entry implements Comparable {
    private final String label;
    private final Object value;

    /**
     * It creates an instance with a key value corresponding
     * to the <code>String.valueOf</code> of the value.
     *
     * @param value the value
     * @since 1.0.1
     */
    global Entry(Object value) {
      this(value, String.valueOf(value));
    }

    /**
     * It creates an instance with a key value and a value.
     *
     * @param value the value
     * @param label the label
     * @since 1.0.1
     */
    global Entry(Object value, String label) {
      this.value = value;
      this.label = label;
    }

    /**
     * @see Comparable#compareTo(Object) compareTo
     * @since 1.0.1
     */
    global Integer compareTo(Object instance) {
      Entry other = (Entry) instance;

      String val1 = String.isEmpty(label) ? String.valueOf(value) : label;
      String val2 = String.isEmpty(other.label) ? String.valueOf(other.value) : other.label;

      if (val1 == null) {
        return val2 == null ? 0 : -1;
      }

      if (val2 == null) {
        return 1;
      }

      return val1.compareTo(val2);
    }

    /**
     * @see Object#equals(Object) equals
     * @since 1.0.1
     */
    global Boolean equals(Object instance) {
      if (instance instanceof Entry) {
        Object val1 = value;
        Object val2 = ((Entry) instance).value;

        return (val1 == null && val1 == val2) || val1.equals(val2);
      }

      return false;
    }

    /**
     * It returns the label.
     *
     * @return the label
     * @since 1.0.1
     */
    global String getLabel() {
      return label;
    }

    /**
     * It returns the value.
     *
     * @return the value
     * @since 1.0.1
     */
    global Object getValue() {
      return value;
    }

    /**
     * @see Object#hashCode() hashCode
     * @since 1.0.1
     */
    global Integer hashCode() {
      Integer result = 5;

      Integer c = value != null ? value.hashCode() : 0;

      return 31 * result + c;
    }
  }

  /**
   * A class that hashes values using an algorithm
   *
   * @since 1.0.1
   */
  global class Hasher {
    private final String algorithm;

    /**
     * It creates an instance that will use MD5 as hashink algorithm.
     *
     * @see Hasher(String)
     * @since 1.0.1
     */
    global Hasher() {
      this('MD5');
    }

    /**
     * It creates an instance that will use a given hashing algorithm.
     *
     * @param algorithm the hashing algorithm to be used
     * @throws UnsupportedOperationException if the algorithm is not 'MD5', 'SHA1', 'SHA-256' or 'SHA-512'
     * @since 1.0.1
     */
    global Hasher(String algorithm) {
      if (algorithm == null || !Pattern.matches('MD5|SHA1|SHA-256|SHA-512', algorithm)) {
        throw new UnsupportedOperationException('Algorithm must be MD5, SHA1, SHA-256 or SHA-512');
      }

      this.algorithm = algorithm;
    }

    /**
     * It hashes a given value.
     *
     * @param value the value to be hashed, not null
     * @return the hashed value
     * @since 1.0.1
     */
    global String hash(Blob value) {
      requireNonNull(value, 'Value cannot be null');

      Blob digest = Crypto.generateDigest(algorithm, value);

      return EncodingUtil.convertToHex(digest);
    }

    /**
     * @see #hash(Blob) hash
     * @since 1.0.1
     */
    global String hash(String value) {
      requireNonNull(value, 'Value cannot be null');

      return hash(Blob.valueOf(value));
    }
  }

  /**
   * An helper object to navigate a given map with less typing and casting.
   *
   * @since 1.0.1
   */
  global class Mapper {
    private final Map<String, Object> values;

    /**
     * It creates an instance wrapping a given map.
     *
     * @param values the map to wrap, not null
     * @since 1.0.1
     */
    global Mapper(Map<String, Object> values) {
      requireNonNull(values, 'Values cannot be null');

      this.values = values;
    }

    /**
     * It checks whether the map contains the given key.
     *
     * @param key the key
     * @return true if the key is present, otherwise false
     * @since 1.0.1
     */
    global Boolean containsKey(String key) {
      return values.containsKey(key);
    }

    /**
     * It returns the map value cast as <code>Boolean</code>.
     *
     * @param key the key
     * @throws TypeException if the value associated with the key is not <code>Boolean</code>
     * @return the <code>Boolean</code> value associated with the key if present, otherwise null
     * @since 1.0.1
     */
    global Boolean getBoolean(String key) {
      return (Boolean) getObject(key);
    }

    /**
     * It returns the map value cast as <code>Integer</code>.
     *
     * @param key the key
     * @throws TypeException if the value associated with the key is not <code>Integer</code>
     * @return the <code>Integer</code> value associated with the key if present, otherwise null
     * @since 1.0.1
     */
    global Integer getInteger(String key) {
      return (Integer) getObject(key);
    }

    /**
     * It returns the map value cast as <code>Map&lt;String, Object&gt;</code>.
     *
     * @param key the key
     * @throws TypeException if the value associated with the key is not <code>Map&lt;String, Object&gt;</code>
     * @return the <code>Map&lt;String, Object&gt;</code> value associated with the key if present, otherwise null
     * @since 1.0.1
     */
    global Map<String, Object> getMap(String key) {
      return (Map<String, Object>) getObject(key);
    }

    /**
     * It returns the map value cast as <code>List&lt;Map&lt;String, Object&gt;&gt;</code>.
     *
     * @param key the key
     * @throws TypeException if the value associated with the key is not <code>List&lt;Map&lt;String, Object&gt;&gt;</code>
     * @return the <code>List&lt;Map&lt;String, Object&gt;&gt;</code> value associated with the key if present, otherwise null
     * @since 1.0.1
     */
    global List<Map<String, Object>> getMapList(String key) {
      List<Map<String, Object>> values = new List<Map<String, Object>>();

      for (Object o : getObjectList(key)) {
        values.add((Map<String, Object>) o);
      }

      return values;
    }

    /**
     * It returns the map value.
     *
     * @param key the key
     * @return the value associated with the key if present, otherwise null
     * @since 1.0.1
     */
    global Object getObject(String key) {
      return values.get(key);
    }

    /**
     * It returns a new mapper instance
     * wrapping the map value cast as <code>Map&lt;String, Object&gt;</code>.
     *
     * @param key the key
     * @throws TypeException if the value associated with the key is not <code>Map&lt;String, Object&gt;</code>
     * @return the <code>Mapper</code> associated with the key if present, otherwise null
     * @since 1.0.1
     */
    global Mapper getObjectAsMapper(String key) {
      return new Mapper(getMap(key));
    }

    /**
     * It returns the map value cast as <code>List&lt;Object&gt;</code>.
     *
     * @param key the key
     * @throws TypeException if the value associated with the key is not <code>List&lt;Object&gt;</code>
     * @return the <code>List&lt;Object&gt;</code> associated with the key if present, otherwise null
     * @since 1.0.1
     */
    global List<Object> getObjectList(String key) {
      return (List<Object>) getObject(key);
    }

    /**
     * It returns the map value cast as <code>String</code>.
     *
     * @param key the key
     * @throws TypeException if the value associated with the key is not <code>String</code>
     * @return the <code>String</code> value associated with the key if present, otherwise null
     * @since 1.0.1
     */
    global String getString(String key) {
      return (String) getObject(key);
    }

    /**
     * It returns the map value cast as <code>List&lt;String&gt;</code>.
     *
     * @param key the key
     * @throws TypeException if the value associated with the key is not <code>List&lt;String&gt;</code>
     * @return the <code>List&lt;String&gt;</code> associated with the key if present, otherwise null
     * @since 1.0.1
     */
    global List<String> getStringList(String key) {
      List<String> values = new List<String>();

      for (Object o : getObjectList(key)) {
        values.add((String) o);
      }

      return values;
    }
  }

  /**
   * A wrapper for <code>Set</code>.
   * The idea is to implement this interface to provide helper methods
   * to work with the <code>Set</code>.
   *
   * @since 1.0.1
   */
  global interface Uniquifier {
    /**
     * It returns the set of values the class is managing
     *
     * @return the set of values
     * @since 1.0.1
     */
    Set<Object> getValues();
  }

  /**
   * An implementation of <code>Uniquifier</code> for <code>SObject</code> field values.
   *
   * @since 1.0.1
   * @see Utils.Uniquifier
   */
  global class RecordValueUniquifier implements Uniquifier {
    private final Schema.SObjectField field;
    private final Map<Object, SObject> values;

    /**
     * It creates a <code>Uniquifier</code> that is bound
     * to a specific <code>SObject</code> field.
     *
     * @param field the <code>SObject</code> field to use as basis
     */
    global RecordValueUniquifier(Schema.SObjectField field) {
      requireNonNull(field, 'Field cannot be null');

      this.field = field;
      this.values = new Map<Object, SObject>();
    }

    /**
     * It adds the record field value of a given record to the set if it's not already present.
     *
     * @param record the record the field value will be read from
     * @return true if the record field value is present in the set, otherwise false
     * @since 1.0.1
     */
    global Boolean addRecordValue(SObject record) {
      Object value = getRecordValue(record);

      if (values.containsKey(value)) {
        return false;
      }

      values.put(value, record);

      return true;
    }

    /**
     * It adds the record field values of a given record list to the set if it's not already present.
     *
     * @param records the record list the field value will be read from
     * @since 1.0.23
     */
    global void addRecordValues(List<SObject> records) {
      requireNonNull(records, 'Records cannot be null');

      for (SObject record : records) {
        values.put(getRecordValue(record), record);
      }
    }

    /**
     * It returns the record associated with the given value if present in the set.
     *
     * @param record the record the field value will be read from
     * @return the record if the value is present in the set, otherwise null
     * @since 1.0.1
     */
    global SObject getRecord(Object value) {
      return values.get(value);
    }

    /**
     * It returns the record field value for a given record.
     *
     * @param record the record the field value will be read from
     * @return the record field value
     * @since 1.0.1
     */
    global Object getRecordValue(SObject record) {
      return record.get(field);
    }

    /**
     * It returns the set of records the class is managing.
     *
     * @return the set of records
     * @see Utils.Uniquifier#getValues() getValues
     * @since 1.0.23
     */
    global List<SObject> getRecords() {
      return values.values();
    }

    /**
     * It returns the set of values the class is managing.
     *
     * @return the set of values
     * @see Utils.Uniquifier#getValues() getValues
     * @since 1.0.1
     */
    global Set<Object> getValues() {
      return values.keySet();
    }
  }

  /**
   * An implementation of <code>Uniquifier</code>.
   *
   * @since 1.0.1
   * @see Utils.Uniquifier
   */
  global class ValueUniquifier implements Uniquifier {
    private final Set<Object> values;

    global ValueUniquifier() {
      this.values = new Set<Object>();
    }

    /**
     * It adds a value to the set if it's not already present.
     *
     * @param value the value to add to the set
     * @return true if the value was not present in the set, otherwise false
     * @since 1.0.1
     */
    global Boolean addValue(Object value) {
      if (values.contains(value)) {
        return false;
      }

      values.add(value);

      return true;
    }

    /**
     * It returns the set of values the class is managing.
     *
     * @return the set of values
     * @see Utils.Uniquifier#getValues() getValues
     * @since 1.0.1
     */
    global Set<Object> getValues() {
      return values;
    }
  }

  /**
   * An object that creates a URL query.
   *
   * @since 1.0.4
   */
  global class UrlQuery {
    private final Map<String, Object> values;

    /**
     * It creates an empty instance of what will make the query.
     *
     * @since 1.0.4
     */
    global UrlQuery() {
      this(new Map<String, Object>());
    }

    /**
     * It creates an instance of the passed values that will make the query.
     *
     * @param values the query values, not null
     * @since 1.0.4
     */
    global UrlQuery(Map<String, Object> values) {
      requireNonNull(values, 'Parameters cannot be null');

      this.values = values;
    }

    private String encode(Object value) {
      return EncodingUtil.urlEncode(String.valueOf(value), 'UTF-8');
    }

    /**
     * It adds a query parameter.
     *
     * @param name the parameter name, not null
     * @param value the parameter value
     * @throws UnsupportedOperationException if the parameter name is empty
     * @since 1.0.4
     */
    global UrlQuery put(String name, Object value) {
      if (String.isEmpty(name)) {
        throw new UnsupportedOperationException('Label cannot be empty');
      }

      values.put(name, value);

      return this;
    }

    global override String toString() {
      if (values.isEmpty()) {
        return '';
      }

      String value = '';

      for (String param : values.keySet()) {
        value += '&' + encode(param) + '=' + encode(values.get(param));
      }

      return '?' + value.substring(1);
    }
  }

  /**
   * It deserializes a map-representing JSON string wrapped in a <code>Utils.Mapper</code> object.
   *
   * @param value the JSON string representing a map, not null
   * @return the <code>Utils.Mapper</code> object wrapping the map
   * @see Utils.Mapper
   * @since 1.0.1
   */
  global static Mapper deserializeToMapper(String value) {
    return new Mapper((Map<String, Object>) JSON.deserializeUntyped(value));
  }

  /**
   * It returns the class name of a given object.
   *
   * @param obj the object, not null
   * @return the class name of the object
   * @since 1.0.3
   */
  @SuppressWarnings('PMD.CyclomaticComplexity, PMD.StdCyclomaticComplexity')
  global static String getClassName(Object obj) {
    requireNonNull(obj, 'Object cannot be null');

    if (obj instanceof Blob) {
      return 'Blob';
    }
    if (obj instanceof Boolean) {
      return 'Boolean';
    }
    if (obj instanceof Date) {
      return 'Date';
    }
    if (obj instanceof Datetime) {
      return 'Datetime';
    }
    if (obj instanceof Decimal) {
      return 'Decimal';
    }
    if (obj instanceof Double) {
      return 'Double';
    }
    if (obj instanceof Id) {
      return 'Id';
    }
    if (obj instanceof Integer) {
      return 'Integer';
    }
    if (obj instanceof List<Object>) {
      return 'List';
    }
    if (obj instanceof Long) {
      return 'Long';
    }
    if (obj instanceof SObject) {
      return String.valueOf(obj);
    }
    if (obj instanceof String) {
      return 'String';
    }
    if (obj instanceof Time) {
      return 'Time';
    }

    String name = String.valueOf(obj);
    Integer index = name.indexOf(':');

    return index > 0 ? name.substring(0, index) : name;
  }

  /**
   * It fetches the record types of a given <code>SObject</code>.
   * The map keys are the "Developer Name" value for the record type
   * while the map values are their ids.
   *
   * @param type the SObject type, not null
   * @return a map containing the SObject record type names and ids
   * @since 1.0.1
   */
  global static Map<String, Id> getRecordTypeNames(Schema.SObjectType type) {
    requireNonNull(type, 'SObject type cannot be null');

    List<Schema.RecordTypeInfo> infos = Describer.getInstance()
      .getObjectDescribe(type)
      .getRecordTypeInfosByDeveloperName()
      .values();

    Map<String, Id> names = new Map<String, Id>();

    for (Schema.RecordTypeInfo info : infos) {
      names.put(info.getDeveloperName(), info.getRecordTypeId());
    }

    return names;
  }

  /**
   * It returns the first value if not null, otherwise the alternative.
   *
   * @param value the value
   * @param alternative the alternative
   * @return the value if not null otherwise the alternative
   * @since 1.0.23
   */
  global static Boolean optBooleanOrElse(Boolean value, Boolean alternative) {
    return value != null ? value : alternative;
  }

  /**
   * It returns the first value if not null, otherwise the alternative.
   *
   * @param value the value
   * @param alternative the alternative
   * @return the value if not null otherwise the alternative
   * @since 1.0.23
   */
  global static Decimal optDecimalOrElse(Decimal value, Decimal alternative) {
    return value != null ? value : alternative;
  }

  /**
   * It returns the first value if not null, otherwise the alternative.
   *
   * @param value the value
   * @param alternative the alternative
   * @return the value if not null otherwise the alternative
   * @since 1.0.23
   */
  global static Integer optIntegerOrElse(Decimal value, Integer alternative) {
    return value != null ? value.intValue() : alternative;
  }

  /**
   * It returns the first value if not null, otherwise the alternative.
   *
   * @param value the value
   * @param alternative the alternative
   * @return the value if not null otherwise the alternative
   * @since 1.0.23
   */
  global static Integer optIntegerOrElse(Integer value, Integer alternative) {
    return value != null ? value : alternative;
  }

  /**
   * It returns the first value if not null, otherwise the alternative.
   *
   * @param value the value
   * @param alternative the alternative
   * @return the value if not null otherwise the alternative
   * @since 1.0.23
   */
  global static String optStringOrElse(String value, String alternative) {
    return value != null ? value : alternative;
  }

  /**
   * It checks whether the passed object is null or not.
   * If the object is null it throws a <code>NullPointerException</code> with the provided message.
   *
   * @param obj the object to check for nullness
   * @param message the message to use in the <code>NullPointerException</code> if the object is null
   * @throws NullPointerException if the object is null
   * @since 1.0.1
   */
  global static void requireNonNull(Object obj, String message) {
    if (obj != null) {
      return;
    }

    System.Exception e = new System.NullPointerException();

    e.setMessage(message);

    throw e;
  }

  /**
   * It pauses the code execution for a given number of seconds
   *
   * @param seconds the seconds the code execution will sleep for
   * @throws UnsupportedOperationException if seconds are lower than 1 or greater than 10
   * @since 1.0.1
   */
  global static void sleep(Integer seconds) {
    if (seconds == null || seconds < 1 || seconds > 10) {
      throw new System.UnsupportedOperationException(
        'Seconds cannot be null and must be comprised between 1 and 10'
      );
    }

    Long start = System.currentTimeMillis();
    Long stop = start + (seconds * 1000);

    while (start <= stop) {
      start = System.currentTimeMillis();
    }
  }
}
