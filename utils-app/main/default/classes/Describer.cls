/**
 * @description A helper class that for <code>SObjectType</code> objects and what revolves around them:
 * <code>DescribeSObjectResult, DescribeFieldResult</code>.
 * <p>
 * This class is meant to be used through a static instance since it wants to leverage cache
 * for reuse as opposed to calling Salesforce methods directly which would become time-expensive.
 *
 * @see Describer#getInstance() getInstance
 * @since 1.0.1
 */
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.CyclomaticComplexity')
global inherited sharing class Describer {
  /**
   * @description An enumerator to classify <code>DisplayType</code> in broader terms.
   *
   * @since 1.0.25
   */
  global enum DisplayFamily {
    BOOL,
    COMPLEX,
    CHOICE,
    NUM,
    TEXT
  }

  /**
   * @description A result class for <code>Describer.traverse</code> that keeps track of cross-referencing traversing.
   *
   * @see Describer#traverse(Schema.SObjectType, String) traverse
   * @since 1.0.23
   */
  global class Hop {
    private final Schema.SObjectType type;

    private Schema.SObjectField field;

    private Hop(Schema.SObjectType t) {
      type = t;
    }

    global Schema.SObjectField getField() {
      return field;
    }

    global Schema.SObjectType getType() {
      return type;
    }
  }

  global abstract class SObjectFilter {
    private Set<String> contains;
    private Set<String> names;
    private String regex;
    private Boolean regexInvert;
    private transient System.Pattern regexPattern;

    protected Boolean matchesContains(String name) {
      if (contains == null) {
        return null;
      }

      for (String part : contains) {
        if (name.containsIgnoreCase(part)) {
          return true;
        }
      }

      return false;
    }

    protected Boolean matchesRegex(String name) {
      if (regex == null) {
        return null;
      }

      if (regexPattern == null) {
        regexPattern = System.Pattern.compile(regex);
      }

      Boolean matched = regexPattern.matcher(name).matches();

      return regexInvert ? !matched : matched;
    }

    global void setContains(Set<String> values) {
      contains = values;
    }

    global void setNames(Set<String> values) {
      names = values;
    }

    global void setRegex(String value) {
      setRegex(value, false);
    }

    global void setRegex(String value, Boolean invert) {
      regex = value;

      regexInvert = Utils.optBooleanOrElse(invert, false);
    }
  }

  /**
   * @description //TODO
   *
   * @since 1.1
   */
  global class SObjectFieldFilter extends SObjectFilter {
    // Storing objectName as a String instead of SObjectType to avoid serialization issues
    private final String objectName;

    private List<Schema.DisplayType> displayTypes;
    private Boolean editable;
    private List<DisplayFamily> families;
    private List<String> sensitivities;

    global SObjectFieldFilter(Schema.SObjectType t) {
      Utils.requireNonNull(t, 'SObjectType cannot be null');

      this.objectName = String.valueOf(t);
    }

    global SObjectFieldFilter(String objectName) {
      Utils.requireNonNull(objectName, 'Object name cannot be null');

      this.objectName = objectName;
    }

    global void setDisplayType(Schema.DisplayType value) {
      setDisplayTypes(new List<Schema.DisplayType>{ value });
    }

    global void setDisplayTypes(List<Schema.DisplayType> value) {
      displayTypes = value;
    }

    global void setEditable(Boolean value) {
      editable = value;
    }

    global void setFamily(DisplayFamily value) {
      setFamilies(new List<DisplayFamily>{ value });
    }

    global void setFamilies(List<DisplayFamily> value) {
      families = value;
    }

    global void setSensitivityLevel(String value) {
      setSensitivityLevels(new List<String>{ value });
    }

    global void setSensitivityLevels(List<String> value) {
      sensitivities = value;
    }

    global Boolean matches(Schema.SObjectField field, Describer describ) {
      final String name = String.valueOf(field);

      // 1st in evaluation order
      if (names != null && !names.contains(name)) {
        return false;
      }

      // 2nd in evaluation order
      final Boolean containsResult = matchesContains(name);

      if (containsResult != null && !containsResult) {
        return false;
      }

      // 3rd in evaluation order
      final Boolean regexResult = matchesRegex(name);

      if (regexResult != null && !regexResult) {
        return false;
      }

      final Schema.DescribeFieldResult result = describ.getFieldDescribe(field);

      if (editable != null) {
        if ((editable && result.isCalculated()) || (!editable && !result.isCalculated())) {
          return false;
        }
      }

      final Schema.DisplayType dt = result.getType();

      // 5th in evaluation order
      if (displayTypes != null && !displayTypes.contains(dt)) {
        return false;
      }

      // 6th in evaluation order
      if (families != null && !families.contains(getDisplayFamily(dt))) {
        return false;
      }

      // 7th in evaluation order
      if (
        sensitivities != null &&
        !sensitivities.contains(
          describ.getFieldSensitivities(describ.getGlobal().get(objectName)).get(name)
        )
      ) {
        return false;
      }

      return true;
    }
  }

  /**
   * @description //TODO
   *
   * @since 1.1
   */
  global class SObjectTypeFilter extends SObjectFilter {
    private Boolean customSettings;

    global Boolean matches(Schema.SObjectType type, Describer describ) {
      final String name = String.valueOf(type);

      if (name.endsWith('ChangeEvent') || name.endsWith('Share')) {
        return false;
      }

      // 1st in evaluation order
      if (customSettings != null) {
        Boolean isCustomSetting = describ.getObjectDescribe(type).isCustomSetting();

        if ((customSettings && !isCustomSetting) || (!customSettings && isCustomSetting)) {
          return false;
        }
      }

      // 2nd in evaluation order
      if (names != null && !names.contains(name)) {
        return false;
      }

      // 3rd in evaluation order
      final Boolean containsResult = matchesContains(name);

      if (containsResult != null && !containsResult) {
        return false;
      }

      // 4th in evaluation order
      final Boolean regexResult = matchesRegex(name);

      if (regexResult != null && !regexResult) {
        return false;
      }

      return true;
    }

    global void setCustomSettings(Boolean flag) {
      customSettings = flag;
    }
  }

  private static Map<Id, Describer> instances;

  private Map<String, Schema.SObjectType> globalDescriber;
  private Map<Schema.SObjectType, Schema.DescribeSObjectResult> objectDescribers;
  private Map<Schema.SObjectType, Map<Schema.SObjectType, String>> objectRelationshipNames;
  private Map<Schema.SObjectField, Schema.DescribeFieldResult> fieldDescribers;
  private Map<Schema.SObjectType, Map<String, String>> fieldSensitivities;

  @SuppressWarnings('PMD.EmptyStatementBlock')
  private Describer() {
  }

  /**
   * @description It returns the <code>SObjectField</code> object representation of a given field name.
   * The value must be represented as <code>SObject.SObjectField</code> (e.g.: <code>Account.Name</code>).
   *
   * @param value the string representing the <code>SObjectField</code>, not null
   * @return the <code>SObjectField</code> represented by the String or null if the field doesn't exist
   * @since 1.0.1
   */
  global Schema.SObjectField fieldValueOf(String value) {
    Utils.requireNonNull(value, 'Value cannot be null');

    List<String> mapping = value.split('\\.');

    List<Hop> results = traverse(getGlobal().get(mapping[0]), value.removeStart(mapping[0] + '.'));

    return results.get(results.size() - 1).getField();
  }

  /**
   * @description It returns the <a href="https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_dynamic_global_describe.htm">global describe</a>.
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
   * @description It returns the <a href="https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_methods_system_fields_describe.htm">DescribeFieldResult</a>
   * of a given <code>SObjectField</code> field.
   *
   * @param field the field, not null
   * @return the field describe result
   * @since 1.0.1
   */
  global Schema.DescribeFieldResult getFieldDescribe(Schema.SObjectField field) {
    Utils.requireNonNull(field, 'Field cannot be null');

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

  @SuppressWarnings('PMD.ApexCRUDViolation')
  global Map<String, String> getFieldSensitivities(Schema.SObjectType type) {
    Utils.requireNonNull(type, 'Type cannot be null');

    if (fieldSensitivities == null) {
      fieldSensitivities = new Map<Schema.SObjectType, Map<String, String>>();
    }

    Map<String, String> sub = fieldSensitivities.get(type);

    if (sub == null) {
      sub = new Map<String, String>();

      fieldSensitivities.put(type, sub);

      final String objectName = String.valueOf(type);

      for (Schema.FieldDefinition d : [
        SELECT QualifiedApiName, SecurityClassification
        FROM FieldDefinition
        WHERE EntityDefinition.QualifiedApiName = :objectName
      ]) {
        sub.put(d.QualifiedApiName, d.SecurityClassification);
      }
    }

    return sub;
  }

  /**
   * @description It returns the <a href="https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_methods_system_sobject_describe.htm#apex_methods_system_sobject_describe">DescribeSObjectResult</a>
   * of a given <code>SObject</code>.
   *
   * @param name the <code>SObject</code> name, not null
   * @return the <code>SObject</code> describe result or null if the name could not be found
   * @see #getObjectDescribe(Schema.SObjectType) getObjectDescribe
   * @since 1.0.1
   */
  global Schema.DescribeSObjectResult getObjectDescribe(String name) {
    Utils.requireNonNull(name, 'Name cannot be null');

    Schema.SObjectType t = getGlobal().get(name);

    return t != null ? getObjectDescribe(t) : null;
  }

  /**
   * @description @param type the <code>SObject</code> type, not null
   * @return the <code>SObject</code> describe result
   * @see #getObjectDescribe(String) getObjectDescribe
   * @since 1.0.1
   */
  global Schema.DescribeSObjectResult getObjectDescribe(Schema.SObjectType type) {
    Utils.requireNonNull(type, 'Type cannot be null');

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
   * @description It returns a map of all the fields defined for a given <code>SObject</code>.
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
   * @description It returns the relationship name between two <code>SObjectType</code> objects.
   *
   * @param parent the parent <code>SObject</code> type, not null
   * @param child the child <code>SObject</code> type, not null
   * @return the relationship name between parent and child
   * @throws System.IllegalArgumentException if the a relationship between the two <code>SObjectType</code> does not exist
   * @since 1.0.4
   */
  global String getObjectRelationshipName(Schema.SObjectType parent, Schema.SObjectType child) {
    Utils.requireNonNull(parent, 'Parent SObject type cannot be null');
    Utils.requireNonNull(child, 'Child SObject type cannot be null');

    if (objectRelationshipNames == null) {
      objectRelationshipNames = new Map<Schema.SObjectType, Map<Schema.SObjectType, String>>();
    }

    Map<Schema.SObjectType, String> children = objectRelationshipNames.get(parent);

    if (children == null) {
      children = new Map<Schema.SObjectType, String>();

      for (Schema.ChildRelationship rel : getObjectDescribe(parent).getChildRelationships()) {
        children.put(rel.getChildSObject(), rel.getRelationshipName());
      }

      objectRelationshipNames.put(parent, children);
    }

    String value = children.get(child);

    if (value == null) {
      throw new IllegalArgumentException(parent + ' does not have a relationship with ' + child);
    }

    return value;
  }

  /**
   * @description It returns the <code>SObject</code> nested in a given <code>SObject</code>
   * by resolving cross-reference syntax.
   *
   * @param syntax the string representing the <code>SObjectField</code>, not null
   * @return the field value
   * @throws System.IllegalArgumentException if the cross-reference syntax was invalid
   * @since 1.0.23
   */
  global SObject getRelatedObject(SObject so, String syntax) {
    Utils.requireNonNull(so, 'SObject cannot be null');
    Utils.requireNonNull(syntax, 'Syntax cannot be null');

    Queue q = new Queue();
    q.addAll(syntax.split('\\.'));
    SObject drill = so;

    while (!q.isEmpty()) {
      String ref = (String) q.poll();

      if (!q.isEmpty()) {
        drill = drill.getSObject(ref);
      }
    }

    return drill;
  }

  /**
   * @description It returns the field value for a given nested <code>SObject</code>
   * by resolving cross-reference syntax.
   *
   * @param syntax the string representing the <code>SObjectField</code>, not null
   * @return the field value
   * @throws System.IllegalArgumentException if the cross-reference syntax was invalid
   * @since 1.0.23
   */
  global Object getRelatedObjectValue(SObject so, String syntax) {
    SObject child = getRelatedObject(so, syntax);

    List<String> levels = syntax.split('\\.');

    return child.get(levels[levels.size() - 1]);
  }

  /**
   * @description It tells whether the org the code is running in has Person Accounts feature enabled.
   * For more info visit: https://help.salesforce.com/s/articleView?id=account_person.htm&language=en_US&type=0
   *
   * @return true if Person Accounts feature is enabled
   * @since 1.0.25
   */
  global Boolean isPersonAccountEnabled() {
    return getInstance()
      .getObjectFieldMap(Schema.Account.SObjectType)
      .containsKey('IsPersonAccount');
  }

  /**
   * @description It allows to query for and return any <code>SObjectField</code>
   * that matches the passed filter.
   *
   * @param filter the filter, not null
   * @return the list of matching fields
   * @throws System.IllegalArgumentException if <code>SObjectType</code> could not be found
   * @since 1.1
   */
  global List<Schema.SObjectField> querySObjectFields(SObjectFieldFilter filter) {
    Utils.requireNonNull(filter, 'Filter name cannot be null');

    final List<Schema.SObjectField> results = new List<Schema.SObjectField>();

    for (
      Schema.SObjectField field : getObjectFieldMap(getGlobal().get(filter.objectName)).values()
    ) {
      if (filter.matches(field, this)) {
        results.add(field);
      }
    }

    return results;
  }

  /**
   * @description It allows to query for and return any <code>SObjectType</code>
   * that matches the passed filter.
   *
   * @param filter the filter, not null
   * @return the list of matching types
   * @since 1.1
   */
  global List<Schema.SObjectType> querySObjectTypes(SObjectTypeFilter filter) {
    Utils.requireNonNull(filter, 'Filter name cannot be null');

    final Map<String, Schema.SObjectType> types = getGlobal();
    final List<Schema.SObjectType> results = new List<Schema.SObjectType>();

    for (Schema.SObjectType type : types.values()) {
      if (filter.matches(type, this)) {
        results.add(type);
      }
    }

    return results;
  }

  /**
   * @description It traverses the <code>SObjectField</code> reference tracking each hop with a helper
   * object that contains relative <code>SObjectType</code> and <code>SObjectField</code>.
   *
   * @param syntax the cross-reference syntax, not null
   * @return the list of hops
   * @throws System.IllegalArgumentException if the cross-reference syntax is invalid
   * @see Describer#traverse(Schema.SObjectType, String) traverse
   * @since 1.1
   */
  global List<Hop> traverse(String syntax) {
    List<String> breakdown = syntax.split('\\.');
    String objectName = breakdown.remove(0);

    Schema.SObjectType t = getGlobal().get(objectName);

    if (t == null) {
      throw new IllegalArgumentException(objectName + ' is not a valid SObject');
    }

    return traverse(t, String.join(breakdown, '.'));
  }

  /**
   * @description It traverses the <code>SObjectField</code> reference tracking each hop with a helper
   * object that contains relative <code>SObjectType</code> and <code>SObjectField</code>.
   *
   * @param type the <code>SObjectType</code>, not null
   * @param syntax the cross-reference syntax, not null
   * @return the list of hops
   * @throws System.IllegalArgumentException if the cross-reference syntax is invalid
   * @since 1.0.23
   */
  @SuppressWarnings('PMD.CyclomaticComplexity')
  global List<Hop> traverse(Schema.SObjectType type, String syntax) {
    Utils.requireNonNull(type, 'SObjectType type cannot be null');
    Utils.requireNonNull(syntax, 'Syntax cannot be null');

    List<Hop> results = new List<Hop>{ new Hop(type) };
    List<String> breakdown = syntax.split('\\.');

    while (!breakdown.isEmpty()) {
      String fieldName = breakdown.remove(0);

      if (fieldName.endsWithIgnoreCase('__r')) {
        fieldName = fieldName.removeEndIgnoreCase('r') + 'c';
      } else if (
        !fieldName.endsWithIgnoreCase('__c') &&
        !fieldName.endsWithIgnoreCase('Id') &&
        !breakdown.isEmpty()
      ) {
        fieldName += 'Id';
      }

      Hop currentResult = results.get(results.size() - 1);
      Schema.SObjectField currentField = getObjectFieldMap(currentResult.getType()).get(fieldName);

      if (currentField == null) {
        throw new IllegalArgumentException(
          String.format(
            '{0} is not a valid reference field name for {1}',
            new List<Object>{
              syntax.equals(fieldName) ? syntax : fieldName + ' in ' + syntax,
              currentResult.getType()
            }
          )
        );
      }

      currentResult.field = currentField;

      List<Schema.SObjectType> references = getFieldDescribe(currentField).getReferenceTo();

      if (references.isEmpty() && breakdown.isEmpty()) {
        currentResult.field = currentField;

        break;
      }

      results.add(new Hop(references[0]));
    }

    return results;
  }

  /**
   * @description It returns the <code>DisplayFamily</code> family which provides a broader name set
   * for the underlying <code>DisplayType</code>
   *
   * @param value the display type
   * @return true if the display type is number-like
   * @since 1.0.25
   */
  global static DisplayFamily getDisplayFamily(Schema.DisplayType value) {
    Utils.requireNonNull(value, 'Display type cannot be null');

    switch on (value) {
      when BOOLEAN {
        return DisplayFamily.BOOL;
      }
      when COMBOBOX, MULTIPICKLIST, PICKLIST {
        return DisplayFamily.CHOICE;
      }
      when CURRENCY, DOUBLE, INTEGER, LONG, PERCENT {
        return DisplayFamily.NUM;
      }
      when EMAIL, ENCRYPTEDSTRING, ID, PHONE, REFERENCE, STRING, TEXTAREA, URL {
        return DisplayFamily.TEXT;
      }
      when else {
        return DisplayFamily.COMPLEX;
      }
    }
  }

  /**
   * @description It returns the static instance of <code>Describer</code>.
   *
   * @return the static instance of <code>Describer</code>
   * @see Describer
   * @since 1.0.1
   */
  global static Describer getInstance() {
    if (instances == null) {
      instances = new Map<Id, Describer>();
    }

    Id userId = UserInfo.getUserId();
    Describer describ = instances.get(userId);

    if (describ == null) {
      describ = new Describer();

      instances.put(userId, describ);
    }

    return describ;
  }
}
