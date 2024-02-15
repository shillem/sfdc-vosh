@SuppressWarnings('PMD.AvoidGlobalModifier')
global class UI {
  @JsonAccess(serializable='always' deserializable='always')
  global virtual class Field {
    // Description
    private final String label;
    private final String name;
    private final String type;

    private String help;
    private Integer length;
    private Boolean multiValue;
    private Set<Utils.Entry> options;
    private Boolean restrictedPicklist;

    // Validation
    private Boolean required;
    private Boolean readonly;

    // Value
    protected Object value;

    global Field(String name, String label, String type) {
      Utils.requireNonNull(name, 'Name cannot be null');

      this.name = name;
      this.label = label != null ? label : name;

      Utils.requireNonNull(type, 'Type cannot be null');

      this.type = type;
    }

    global Field addOption(Utils.Entry entry) {
      getOptions().add(entry);

      return this;
    }

    global Field addOptions(Set<Utils.Entry> entries) {
      getOptions().addAll(entries);

      return this;
    }

    global String getHelp() {
      return help;
    }

    global String getLabel() {
      return label;
    }

    global Integer getLength() {
      return length;
    }

    global String getName() {
      return name;
    }

    global Set<Utils.Entry> getOptions() {
      if (options == null) {
        options = new Set<Utils.Entry>();
      }

      return options;
    }

    global Boolean isMultiValue() {
      return multiValue != null && multiValue;
    }

    global Boolean isReadonly() {
      return readonly != null && readonly;
    }

    global Boolean isRequired() {
      return required != null && required;
    }

    global Boolean isRestrictedPicklist() {
      return restrictedPicklist != null && restrictedPicklist;
    }

    global String getType() {
      return type;
    }

    global Object getValue() {
      return value;
    }

    global Field setHelp(String value) {
      help = value;

      return this;
    }

    global Field setMultiValue(Boolean flag) {
      multiValue = flag;

      return this;
    }

    global Field setLength(Integer value) {
      length = value;

      return this;
    }

    global Field setReadonly(Boolean flag) {
      readonly = flag;

      return this;
    }

    global Field setRequired(Boolean required) {
      this.required = required;

      return this;
    }

    global Field setRestrictedPicklist(Boolean flag) {
      restrictedPicklist = flag;

      return this;
    }

    global Field setValue(Object value) {
      this.value = value;

      return this;
    }

    global Field sortOptions() {
      if (options != null) {
        List<Utils.Entry> tempList = new List<Utils.Entry>(options);

        tempList.sort();

        options = new Set<Utils.Entry>(tempList);
      }

      return this;
    }
  }

  @JsonAccess(serializable='always' deserializable='always')
  global class FieldSObject extends Field {
    private transient Schema.SObjectField field;
    private transient Schema.DescribeFieldResult result;

    global FieldSObject(Schema.SObjectField field) {
      this(field, Describer.getInstance().getFieldDescribe(field));
    }

    private FieldSObject(Schema.SObjectField field, Schema.DescribeFieldResult result) {
      super(result.getName(), result.getLabel(), result.getType().name());

      setHelp(result.getInlineHelpText());
      setLength(result.getLength());
      setRequired(!result.isNillable());
      setRestrictedPicklist(result.isRestrictedPicklist());

      this.field = field;
      this.result = result;
    }

    global FieldSObject addPicklistOptions() {
      if (type.containsIgnoreCase('picklist')) {
        for (Schema.PicklistEntry entry : result.getPicklistValues()) {
          addOption(new Utils.Entry(entry.getValue(), entry.getLabel()));
        }
      }

      return this;
    }
  }

  @JsonAccess(serializable='always' deserializable='always')
  global class ListboxItem extends Utils.Entry implements Comparable {
    private Boolean disabled;
    private String icon;
    private String meta;

    global ListboxItem(String value) {
      super(value);
    }

    global ListboxItem(String value, String label) {
      super(value, label);
    }

    global Boolean getDisabled() {
      return disabled;
    }

    global String getIcon() {
      return icon;
    }

    global String getMeta() {
      return meta;
    }

    global ListboxItem setDisabled(Boolean value) {
      disabled = value;

      return this;
    }

    global ListboxItem setIcon(String value) {
      icon = value;

      return this;
    }

    global ListboxItem setMeta(String value) {
      meta = value;

      return this;
    }
  }

  @JsonAccess(serializable='always' deserializable='always')
  global class SObjectDescriptor {
    private final String label;
    private final String labelPlural;
    private final String name;
    private final Map<String, Field> fieldMap;

    private List<String> preferredFieldOrder;

    global SObjectDescriptor(Schema.SObjectType type) {
      this(type, null);
    }

    global SObjectDescriptor(Schema.SObjectType type, Set<Schema.SObjectField> fields) {
      final Describer describer = Describer.getInstance();
      final Schema.DescribeSObjectResult typeRes = describer.getObjectDescribe(type);

      label = typeRes.getLabel();
      labelPlural = typeRes.getLabelPlural();
      name = String.valueOf(type);
      fieldMap = new Map<String, Field>();

      if (fields == null) {
        fields = new Set<Schema.SObjectField>(describer.getObjectFieldMap(type).values());
      }

      for (Schema.SObjectField field : fields) {
        fieldMap.put(String.valueOf(field), new FieldSObject(field).addPicklistOptions());
      }
    }

    global String getLabel() {
      return label;
    }

    global String getLabelPlural() {
      return labelPlural;
    }

    global String getName() {
      return name;
    }

    global Field getField(Schema.SObjectField field) {
      return getField(String.valueOf(field));
    }

    global Field getField(String name) {
      return fieldMap.get(name);
    }

    global Map<String, Field> getFieldMap() {
      return fieldMap;
    }

    global void setValues(SObject record) {
      for (String fieldName : fieldMap.keySet()) {
        fieldMap.get(fieldName).setValue(record.get(fieldName));
      }
    }
  }
}
