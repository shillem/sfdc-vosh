public with sharing class Utils {
    public class Describer {
        private Map<String, Schema.SObjectType> globalDescriber;
        private Map<Schema.SObjectType, Schema.DescribeSObjectResult> objectDescribers;
        private Map<Schema.SObjectField, Schema.DescribeFieldResult> fieldDescribers;

        private Describer() {
        }

        public Map<String, SObjectType> getGlobal() {
            if (globalDescriber == null) {
                globalDescriber = Schema.getGlobalDescribe();
            }

            return globalDescriber;
        }

        public Schema.DescribeFieldResult getFieldDescribe(Schema.SObjectField field) {
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

        public Schema.DescribeSObjectResult getObjectDescribe(String name) {
            return getObjectDescribe(getGlobal().get(name));
        }

        public Schema.DescribeSObjectResult getObjectDescribe(Schema.SObjectType type) {
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

        public Map<String, SObjectField> getObjectFieldMap(Schema.SObjectType type) {
            return getObjectDescribe(type).fields.getMap();
        }

        public Schema.SObjectField fieldValueOf(String pointer) {
            List<String> mapping = pointer.split('\\.');

            return getObjectFieldMap(getGlobal().get(mapping[0])).get(mapping[1]);
        }
    }

    public virtual class Entry implements Comparable {
        private final String label;
        private final Object value;

        public Entry(Object value) {
            this(value, String.valueOf(value));
        }

        public Entry(Object value, String label) {
            this.value = value;
            this.label = label;
        }

        public Integer compareTo(Object instance) {
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

        public Boolean equals(Object instance) {
            if (instance instanceof Entry) {
                Object val1 = value;
                Object val2 = ((Entry) instance).value;

                return (val1 == null && val1 == val2) || val1.equals(val2);
            }

            return false;
        }

        public String getLabel() {
            return label;
        }

        public Object getValue() {
            return value;
        }

        public Integer hashCode() {
            Integer result = 5;

            Integer c = value != null ? value.hashCode() : 0;

            return 31 * result + c;
        }
    }

    public class Mapper {
        private final Map<String, Object> values;

        public Mapper(Map<String, Object> values) {
            requireNonNull(values, 'Values cannot be null');

            this.values = values;
        }

        public Boolean containsKey(String key) {
            return values.containsKey(key);
        }

        public Boolean getBoolean(String key) {
            return (Boolean) getObject(key);
        }

        public Integer getInteger(String key) {
            return (Integer) getObject(key);
        }

        public Map<String, Object> getMap(String key) {
            return (Map<String, Object>) getObject(key);
        }

        public List<Map<String, Object>> getMapList(String key) {
            List<Map<String, Object>> values = new List<Map<String, Object>>();

            for (Object o : getObjectList(key)) {
                values.add((Map<String, Object>) o);
            }

            return values;
        }

        public Object getObject(String key) {
            return values.get(key);
        }

        public Mapper getObjectAsMapper(String key) {
            return new Mapper(getMap(key));
        }

        public List<Object> getObjectList(String key) {
            return (List<Object>) getObject(key);
        }

        public String getString(String key) {
            return (String) getObject(key);
        }

        public List<String> getStringList(String key) {
            List<String> values = new List<String>();

            for (Object o : getObjectList(key)) {
                values.add((String) o);
            }

            return values;
        }
    }

    public class Randomizer {
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

        public String generate() {
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

    public class RandomizerBuilder {
        private Boolean currentTimeMillis;
        private Integer length;
        private String prefix;
        private Set<RandomizerPreference> prefs;

        public RandomizerBuilder setCurrentTimeMillis(Boolean flag) {
            currentTimeMillis = flag != null && flag;

            return this;
        }

        public RandomizerBuilder setPreferences(Set<RandomizerPreference> values) {
            prefs = values;

            return this;
        }

        public RandomizerBuilder setPrefix(String value) {
            prefix = value;

            return this;
        }

        public RandomizerBuilder setLength(Integer value) {
            length = value;

            return this;
        }

        public Randomizer build() {
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

    public enum RandomizerPreference {
        INCLUDE_LETTER,
        INCLUDE_NUMBER
    }

    public interface Uniquifier {
        Set<Object> getValues();
    }

    public class ValueUniquifier implements Uniquifier {
        private final Set<Object> values;

        public ValueUniquifier() {
            this.values = new Set<Object>();
        }

        public Boolean addValue(Object value) {
            if (values.contains(value)) {
                return false;
            }

            values.add(value);

            return true;
        }

        public Set<Object> getValues() {
            return values;
        }
    }

    public class RecordValueUniquifier implements Uniquifier {
        private final Schema.SObjectField field;
        private final Map<Object, SObject> values;

        public RecordValueUniquifier(Schema.SObjectField field) {
            requireNonNull(field, 'Field cannot be null');

            this.field = field;

            this.values = new Map<Object, SObject>();
        }

        public Boolean addRecordValue(SObject record) {
            Object value = getRecordValue(record);

            if (values.containsKey(value)) {
                return false;
            }

            values.put(value, record);

            return true;
        }

        public SObject getRecord(Object value) {
            return values.get(value);
        }

        public Object getRecordValue(SObject record) {
            return record.get(field);
        }

        public Set<Object> getValues() {
            return values.keySet();
        }
    }

    private static Map<Id, Describer> DESCRIBER_INSTANCE;

    public static Mapper deserializeToMapper(String value) {
        return new Mapper((Map<String, Object>) JSON.deserializeUntyped(value));
    }

    public static Describer getDescriber() {
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

    public static Map<String, Id> getRecordTypeNames(Schema.SObjectType type) {
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

    public static void requireNonNull(Object o, String message) {
        if (o != null) {
            return;
        }

        System.Exception e = new System.NullPointerException();

        e.setMessage(message);

        throw e;
    }

    public static void sleep(Integer seconds) {
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
