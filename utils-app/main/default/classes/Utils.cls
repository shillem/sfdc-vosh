global inherited sharing class Utils {
    /**
     * A helper class that for <code>SObjectType</code> objects and what revolves around them:
     * <code>DescribeSObjectResult, DescribeFieldResult</code>.
     * <p>
     * This class is meant to be used through a static instance since it wants to leverage cache
     * for reuse as opposed to calling Salesforce methods directly which would become time-expensive.
     *
     * @see Utils#getDescriber() getDescriber
     * @since 1.0.1
     */
    global class Describer {
        private Map<String, Schema.SObjectType> globalDescriber;
        private Map<Schema.SObjectType, Schema.DescribeSObjectResult> objectDescribers;
        private Map<Schema.SObjectType, Map<Schema.SObjectType, String>> objectRelationshipNames;
        private Map<Schema.SObjectField, Schema.DescribeFieldResult> fieldDescribers;

        private Describer() {
        }

        /**
         * It returns the <a href="https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_dynamic_global_describe.htm">global describe</a>.
         *
         * @return the global describe
         * @since 1.0.1
         */
        global Map<String, SObjectType> getGlobal() {
            if (globalDescriber == null) {
                globalDescriber = Schema.getGlobalDescribe();
            }

            return globalDescriber;
        }

        /**
         * It returns the <a href="https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_methods_system_fields_describe.htm">DescribeFieldResult</a>
         * of a given <code>SObjectField</code> field.
         *
         * @param field the field, not null
         * @return the field describe result
         * @since 1.0.1
         */
        global Schema.DescribeFieldResult getFieldDescribe(Schema.SObjectField field) {
            requireNonNull(field, 'Field cannot be null');

            if (fieldDescribers == null) {
                fieldDescribers = new Map<Schema.SObjectField, Schema.DescribeFieldResult>();
            }

            Schema.DescribeFieldResult value = fieldDescribers.get(field);

            if (value == null) {
                value = field.getDescribe();

                fieldDescribers.put(field, value);
            }

            return value;
        }

        /**
         * It returns the <a href="https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_methods_system_sobject_describe.htm#apex_methods_system_sobject_describe">DescribeSObjectResult</a>
         * of a given <code>SObject</code>.
         *
         * @param name the <code>SObject</code> name, not null
         * @return the <code>SObject</code> describe result
         * @see #getObjectDescribe(Schema.SObjectType) getObjectDescribe
         * @since 1.0.1
         */
        global Schema.DescribeSObjectResult getObjectDescribe(String name) {
            requireNonNull(name, 'Name cannot be null');

            return getObjectDescribe(getGlobal().get(name));
        }

        /**
         * @param type the <code>SObject</code> type, not null
         * @return the <code>SObject</code> describe result
         * @see #getObjectDescribe(String) getObjectDescribe
         * @since 1.0.1
         */
        global Schema.DescribeSObjectResult getObjectDescribe(Schema.SObjectType type) {
            requireNonNull(type, 'Type cannot be null');

            if (objectDescribers == null) {
                objectDescribers = new Map<Schema.SObjectType, Schema.DescribeSObjectResult>();
            }

            Schema.DescribeSObjectResult result = objectDescribers.get(type);

            if (result == null) {
                result = type.getDescribe();

                objectDescribers.put(type, result);
            }

            return result;
        }

        /**
         * It returns a map of all the fields defined for a given <code>SObject</code>.
         * The map keys represent the field names
         * while the values are the <code>SObjectField</code> objects.
         *
         * @param type the <code>SObject</code> type, not null
         * @return the map containing all the fields defined for the <code>SObject</code>
         * @since 1.0.1
         */
        global Map<String, SObjectField> getObjectFieldMap(Schema.SObjectType type) {
            return getObjectDescribe(type).fields.getMap();
        }

        /**
         * It returns the relationship name between two <code>SObjectType</code> objects.
         *
         * @param parent the parent <code>SObject</code> type, not null
         * @param child the child <code>SObject</code> type, not null
         * @return the relationship name between parent and child
         * @since 1.0.4
         */
        global String getObjectRelationshipName(
            Schema.SObjectType parent,
            Schema.SObjectType child
        ) {
            requireNonNull(parent, 'Parent SObject type cannot be null');
            requireNonNull(child, 'Child SObject type cannot be null');

            if (objectRelationshipNames == null) {
                objectRelationshipNames = new Map<Schema.SObjectType, Map<Schema.SObjectType, String>>();
            }

            Map<Schema.SObjectType, String> children = objectRelationshipNames.get(parent);

            if (children == null) {
                children = new Map<Schema.SObjectType, String>();

                for (
                    Schema.ChildRelationship rel : getObjectDescribe(parent).getChildRelationships()
                ) {
                    children.put(rel.getChildSObject(), rel.getRelationshipName());
                }

                objectRelationshipNames.put(parent, children);
            }

            String value = children.get(child);

            if (value == null) {
                throw new UnsupportedOperationException(
                    parent +
                    ' does not have relationship with ' +
                    child
                );
            }

            return value;
        }

        /**
         * It returns the <code>SObjectField</code> object representation of a given field name.
         * The value must be represented as <code>SObject.SObjectField</code> (e.g.: <code>Account.Name</code>).
         *
         * @param value the string representing the <code>SObjectField</code>, not null
         * @return the <code>SObjectField</code> represented by the String or null if the field doesn't exist
         * @since 1.0.1
         */
        global Schema.SObjectField fieldValueOf(String value) {
            requireNonNull(value, 'Value cannot be null');

            List<String> mapping = value.split('\\.');

            return getObjectFieldMap(getGlobal().get(mapping[0])).get(mapping[1]);
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
                throw new UnsupportedOperationException(
                    'Algorithm must be MD5, SHA1, SHA-256 or SHA-512'
                );
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
     * An object that creates rule-based random string values.
     * The object must be created through <code>Utils.RandomizerBuilder</code>.
     *
     * @see Utils.RandomizerBuilder
     * @since 1.0.1
     */
    global class Randomizer {
        private final Boolean currentTimeMillis;
        private final Integer length;
        private final String prefix;
        private final Set<RandomizerPreference> prefs;

        private Randomizer(RandomizerBuilder builder) {
            currentTimeMillis = builder.currentTimeMillis;
            prefix = builder.prefix;
            prefs = builder.prefs;
            length = builder.length;
        }

        /**
         * It generates the random string value based on the rules defined in the object.
         *
         * @return the randomly generated string value
         * @since 1.0.1
         */
        global String generate() {
            String value = prefix != null && prefix.length() > 0 ? prefix + '-' : '';

            Iterator<RandomizerPreference> iter = prefs.iterator();

            for (Integer i = 0; i < length; i++) {
                if (!iter.hasNext()) {
                    iter = prefs.iterator();
                }

                RandomizerPreference pref = iter.next();

                switch on pref {
                    when INCLUDE_LETTER {
                        value += getRandomLetter();
                    }
                    when INCLUDE_NUMBER {
                        value += getRandomNumber();
                    }
                }
            }

            if (currentTimeMillis != null && currentTimeMillis) {
                value += '-' + System.currentTimeMillis();
            }

            return value;
        }

        private String getRandomLetter() {
            return String.fromCharArray(new List<Integer>{ getRandomNumber(0, 25) + 65 });
        }

        private Integer getRandomNumber() {
            return getRandomNumber(0, 9);
        }

        private Integer getRandomNumber(Integer min, Integer max) {
            return (Integer) ((Math.random() * ((max - min) + 1)) + min);
        }
    }

    /**
     * A builder for <code>Randomizer</code>.
     * It defines the rules that object will use to create a random string.
     *
     * @see Utils.Randomizer
     * @since 1.0.1
     */
    global class RandomizerBuilder {
        private Boolean currentTimeMillis;
        private Integer length;
        private String prefix;
        private Set<RandomizerPreference> prefs;

        /**
         * It toggles the inclusion of current time in millisecs
         * in the string that will be generated.
         *
         * @param flag the toggle
         * @see Utils.Randomizer
         * @return the builder instance
         * @since 1.0.1
         */
        global RandomizerBuilder setCurrentTimeMillis(Boolean flag) {
            currentTimeMillis = flag != null && flag;

            return this;
        }

        /**
         * It sets the preferences used in the string that will be generated.
         *
         * @param values the preferences
         * @see Utils.RandomizerPreference
         * @return the builder instance
         * @since 1.0.1
         */
        global RandomizerBuilder setPreferences(Set<RandomizerPreference> values) {
            prefs = values;

            return this;
        }

        /**
         * It sets the use a prefix in the string that will be generated.
         * If the value is null no prefix will be added.
         *
         * @param value the prefix value
         * @return the builder instance
         * @since 1.0.1
         */
        global RandomizerBuilder setPrefix(String value) {
            prefix = value;

            return this;
        }

        /**
         * It sets the length of the string that will be generated.
         *
         * @param value the length of the string
         * @return the builder instance
         * @since 1.0.1
         */
        global RandomizerBuilder setLength(Integer value) {
            length = value;

            return this;
        }

        /**
         * It builds a <code>Randomizer</code> instance using the rules currently set.
         *
         * @throws UnsupportedOperationException if not <code>RandomizerPreference</code> was not set or the length was not set or it is lower than 3 or greater than 16
         * @return the <code>Randomizer</code> instance
         * @since 1.0.1
         */
        global Randomizer build() {
            if (prefs == null) {
                throw new System.UnsupportedOperationException(
                    'Preferences cannot be null or empty'
                );
            }

            if (length == null || length < 3 || length > 16) {
                throw new System.UnsupportedOperationException(
                    'Length cannot be null and must be comprised between 3 and 16'
                );
            }

            return new Randomizer(this);
        }
    }

    /**
     * It defines the preferences used by <code>RandomizerBuilder</code>.
     * in the string that will be generated.
     *
     * @see Utils.RandomizerBuilder
     * @since 1.0.1
     */
    global enum RandomizerPreference {
        INCLUDE_LETTER,
        INCLUDE_NUMBER
    }

    /**
     * A record organizer for <code>SObject</code>.
     * It outputs a map having a key based on the specified criteria
     * and subsequent <code>SObject</code> record falling under that key.
     *
     * @see Utils.SObjectCollectorCriteria
     * @since 1.0.13
     */
    global class SObjectCollector {
        private final Set<SObject> records = new Set<SObject>();

        /**
         * It add the record to the list of records that will be evaluated
         * by the criteria organizing them.
         *
         * @param record the record
         * @since 1.0.13
         */
        global void add(SObject record) {
            records.add(record);
        }

        /**
         * It add the record to the list of records that will be evaluated
         * by the criteria organizing them.
         *
         * @param records the records
         * @since 1.0.13
         */
        global void addAll(List<SObject> records) {
            this.records.addAll(records);
        }

        /**
         * It creates an id map of <code>SObject</code> lists based on the criteria.
         * The criteria key value must support casting to the <code>Id</code> type.
         *
         * @param criteria the criteria, not null
         * @return the map of <code>SObject</code> record lists as organized by the criteria
         * @since 1.0.14
         */
        global Map<Id, List<SObject>> makeIdMapOfLists(SObjectCollectorCriteria criteria) {
            requireNonNull(criteria, 'Criteria cannot be null');

            Map<Id, List<SObject>> values = new Map<Id, List<SObject>>();

            for (SObject record : records) {
                if (criteria.matches(record)) {
                    Id key = (Id) criteria.getKey(record);
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
         * It creates an id map of <code>SObject</code> maps based on the criteria.
         * The criteria key value must support casting to the <code>Id</code> type.
         *
         * @param criteria the criteria, not null
         * @return the map of <code>SObject</code> record maps as organized by the criteria
         * @since 1.0.14
         */
        global Map<Id, Map<Id, SObject>> makeIdMapOfMaps(SObjectCollectorCriteria criteria) {
            requireNonNull(criteria, 'Criteria cannot be null');

            Map<Id, Map<Id, SObject>> values = new Map<Id, Map<Id, SObject>>();

            for (SObject record : records) {
                if (record.Id != null && criteria.matches(record)) {
                    Id key = (Id) criteria.getKey(record);
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
         * It creates a map of <code>SObject</code> lists based on the criteria.
         *
         * @param criteria the criteria, not null
         * @return the map of <code>SObject</code> record lists as organized by the criteria
         * @since 1.0.13
         */
        global Map<Object, List<SObject>> makeMapOfLists(SObjectCollectorCriteria criteria) {
            requireNonNull(criteria, 'Criteria cannot be null');

            Map<Object, List<SObject>> values = new Map<Object, List<SObject>>();

            for (SObject record : records) {
                if (criteria.matches(record)) {
                    Object key = criteria.getKey(record);
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
         * It creates a map of <code>SObject</code> maps based on the criteria.
         *
         * @param criteria the criteria, not null
         * @return the map of <code>SObject</code> record maps as organized by the criteria
         * @since 1.0.13
         */
        global Map<Object, Map<Id, SObject>> makeMapOfMaps(SObjectCollectorCriteria criteria) {
            requireNonNull(criteria, 'Criteria cannot be null');

            Map<Object, Map<Id, SObject>> values = new Map<Object, Map<Id, SObject>>();

            for (SObject record : records) {
                if (record.Id != null && criteria.matches(record)) {
                    Object key = criteria.getKey(record);
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
    }

    /**
     * The criteria object used by a <code>Utils.SObjectCollector</code>
     * to organize <code>SObject</code> records.
     *
     * @see Utils.SObjectCollector
     * @since 1.0.13
     */
    global interface SObjectCollectorCriteria {
        /**
         * It returns the value that will be used as key
         * by the <code>Utils.SObjectCollector</code>.
         *
         * @param record the record
         * @return the key value
         * @since 1.0.13
         */
        Object getKey(SObject record);

        /**
         * It returns the value that will be used as key
         * by the <code>Utils.SObjectCollector</code>.
         *
         * @param record the record
         * @return true if the record matches
         * @since 1.0.13
         */
        Boolean matches(SObject record);
    }

    /**
     * An implementation of <code>Utils.SObjectCollectorCriteria</code>
     * based on <code>Schema.SObjectField</code>.
     *
     * @see Utils.SObjectCollector
     * @see Utils.SObjectCollectorCriteria
     * @since 1.0.13
     */
    global class SoccField implements SObjectCollectorCriteria {
        private final Schema.SObjectField field;

        /**
         * It creates a criteria that will use the specified field
         * to read the key value for any given record.
         *
         * @param field the field
         * @since 1.0.13
         */
        global SoccField(Schema.SObjectField field) {
            requireNonNull(field, 'Field cannot be null');

            this.field = field;
        }

        /**
         * It reads the record value.
         *
         * @param record the record
         * @return the value
         * @since 1.0.13
         */
        global Object getKey(SObject record) {
            return record.get(field);
        }

        /**
         * It checks whether the record can be included.
         *
         * @param record the record
         * @return true if the record matches
         * @since 1.0.13
         */
        global Boolean matches(SObject record) {
            return record.get(field) != null;
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

    private static Map<Id, Describer> DESCRIBER_INSTANCE;

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
    global static String getClassName(Object obj) {
        requireNonNull(obj, 'Object cannot be null');

        if (obj instanceof Blob)
            return 'Blob';
        if (obj instanceof Boolean)
            return 'Boolean';
        if (obj instanceof Date)
            return 'Date';
        if (obj instanceof Datetime)
            return 'Datetime';
        if (obj instanceof Decimal)
            return 'Decimal';
        if (obj instanceof Double)
            return 'Double';
        if (obj instanceof Id)
            return 'Id';
        if (obj instanceof Integer)
            return 'Integer';
        if (obj instanceof List<Object>)
            return 'List';
        if (obj instanceof Long)
            return 'Long';
        if (obj instanceof SObject)
            return String.valueOf(obj);
        if (obj instanceof String)
            return 'String';
        if (obj instanceof Time)
            return 'Time';

        String name = String.valueOf(obj);
        Integer index = name.indexOf(':');

        return index > 0 ? name.substring(0, index) : name;
    }

    /**
     * It returns the static instance of <code>Describer</code>.
     *
     * @return the static instance of <code>Describer</code>
     * @see Utils.Describer
     * @since 1.0.1
     */
    global static Describer getDescriber() {
        if (DESCRIBER_INSTANCE == null) {
            DESCRIBER_INSTANCE = new Map<Id, Describer>();
        }

        Id userId = UserInfo.getUserId();
        Describer describ = DESCRIBER_INSTANCE.get(userId);

        if (describ == null) {
            describ = new Describer();

            DESCRIBER_INSTANCE.put(userId, describ);
        }

        return describ;
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

        List<Schema.RecordTypeInfo> infos = getDescriber()
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
