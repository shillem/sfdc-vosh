global with sharing class Utils {
    global class Describer {
        private Map<String, Schema.SObjectType> globalDescriber;
        private Map<Schema.SObjectType, Schema.DescribeSObjectResult> objectDescribers;
        private Map<Schema.SObjectField, Schema.DescribeFieldResult> fieldDescribers;

        private Describer() {
        }

        global Map<String, SObjectType> getGlobal() {
            if (globalDescriber == null) {
                globalDescriber = Schema.getGlobalDescribe();
            }

            return globalDescriber;
        }

        global Schema.DescribeFieldResult getFieldDescribe(Schema.SObjectField field) {
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

        global Schema.DescribeSObjectResult getObjectDescribe(String name) {
            return getObjectDescribe(getGlobal().get(name));
        }

        global Schema.DescribeSObjectResult getObjectDescribe(Schema.SObjectType type) {
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

        global Map<String, SObjectField> getObjectFieldMap(Schema.SObjectType type) {
            return getObjectDescribe(type).fields.getMap();
        }

        global Schema.SObjectField fieldValueOf(String pointer) {
            List<String> mapping = pointer.split('\\.');

            return getObjectFieldMap(getGlobal().get(mapping[0])).get(mapping[1]);
        }
    }

    global virtual class Entry implements Comparable {
        private final String label;
        private final Object value;

        global Entry(Object value) {
            this(value, String.valueOf(value));
        }

        global Entry(Object value, String label) {
            this.value = value;
            this.label = label;
        }

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

        global Boolean equals(Object instance) {
            if (instance instanceof Entry) {
                Object val1 = value;
                Object val2 = ((Entry) instance).value;

                return (val1 == null && val1 == val2) || val1.equals(val2);
            }

            return false;
        }

        global String getLabel() {
            return label;
        }

        global Object getValue() {
            return value;
        }

        global Integer hashCode() {
            Integer result = 5;

            Integer c = value != null ? value.hashCode() : 0;

            return 31 * result + c;
        }
    }

    global class Hasher {
        private final String algorithm;

        global Hasher() {
            this('MD5');
        }

        global Hasher(String algorithm) {
            if (algorithm == null || !Pattern.matches('MD5|SHA1|SHA-256|SHA-512', algorithm)) {
                throw new UnsupportedOperationException(
                    'Algorithm must be MD5, SHA1, SHA-256 or SHA-512'
                );
            }

            this.algorithm = algorithm;
        }

        global String hash(Blob value) {
            requireNonNull(value, 'Value cannot be null');

            Blob digest = Crypto.generateDigest(algorithm, value);

            return EncodingUtil.convertToHex(digest);
        }

        global String hash(String value) {
            requireNonNull(value, 'Value cannot be null');

            return hash(Blob.valueOf(value));
        }
    }

    global class Mapper {
        private final Map<String, Object> values;

        global Mapper(Map<String, Object> values) {
            requireNonNull(values, 'Values cannot be null');

            this.values = values;
        }

        global Boolean containsKey(String key) {
            return values.containsKey(key);
        }

        global Boolean getBoolean(String key) {
            return (Boolean) getObject(key);
        }

        global Integer getInteger(String key) {
            return (Integer) getObject(key);
        }

        global Map<String, Object> getMap(String key) {
            return (Map<String, Object>) getObject(key);
        }

        global List<Map<String, Object>> getMapList(String key) {
            List<Map<String, Object>> values = new List<Map<String, Object>>();

            for (Object o : getObjectList(key)) {
                values.add((Map<String, Object>) o);
            }

            return values;
        }

        global Object getObject(String key) {
            return values.get(key);
        }

        global Mapper getObjectAsMapper(String key) {
            return new Mapper(getMap(key));
        }

        global List<Object> getObjectList(String key) {
            return (List<Object>) getObject(key);
        }

        global String getString(String key) {
            return (String) getObject(key);
        }

        global List<String> getStringList(String key) {
            List<String> values = new List<String>();

            for (Object o : getObjectList(key)) {
                values.add((String) o);
            }

            return values;
        }
    }

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

    global class RandomizerBuilder {
        private Boolean currentTimeMillis;
        private Integer length;
        private String prefix;
        private Set<RandomizerPreference> prefs;

        global RandomizerBuilder setCurrentTimeMillis(Boolean flag) {
            currentTimeMillis = flag != null && flag;

            return this;
        }

        global RandomizerBuilder setPreferences(Set<RandomizerPreference> values) {
            prefs = values;

            return this;
        }

        global RandomizerBuilder setPrefix(String value) {
            prefix = value;

            return this;
        }

        global RandomizerBuilder setLength(Integer value) {
            length = value;

            return this;
        }

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

    global enum RandomizerPreference {
        INCLUDE_LETTER,
        INCLUDE_NUMBER
    }

    global interface Uniquifier {
        Set<Object> getValues();
    }

    global class ValueUniquifier implements Uniquifier {
        private final Set<Object> values;

        global ValueUniquifier() {
            this.values = new Set<Object>();
        }

        global Boolean addValue(Object value) {
            if (values.contains(value)) {
                return false;
            }

            values.add(value);

            return true;
        }

        global Set<Object> getValues() {
            return values;
        }
    }

    global class RecordValueUniquifier implements Uniquifier {
        private final Schema.SObjectField field;
        private final Map<Object, SObject> values;

        global RecordValueUniquifier(Schema.SObjectField field) {
            requireNonNull(field, 'Field cannot be null');

            this.field = field;

            this.values = new Map<Object, SObject>();
        }

        global Boolean addRecordValue(SObject record) {
            Object value = getRecordValue(record);

            if (values.containsKey(value)) {
                return false;
            }

            values.put(value, record);

            return true;
        }

        global SObject getRecord(Object value) {
            return values.get(value);
        }

        global Object getRecordValue(SObject record) {
            return record.get(field);
        }

        global Set<Object> getValues() {
            return values.keySet();
        }
    }

    private static Map<Id, Describer> DESCRIBER_INSTANCE;

    global static Mapper deserializeToMapper(String value) {
        return new Mapper((Map<String, Object>) JSON.deserializeUntyped(value));
    }

    global static String getClassName(Object obj) {
        requireNonNull(obj, 'Object cannot be null');

        String name = String.valueOf(obj);
        Integer index = name.indexOf(':');

        return index > 0 ? name.substring(0, index) : name;
    }

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

    global static void requireNonNull(Object o, String message) {
        if (o != null) {
            return;
        }

        System.Exception e = new System.NullPointerException();

        e.setMessage(message);

        throw e;
    }

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
