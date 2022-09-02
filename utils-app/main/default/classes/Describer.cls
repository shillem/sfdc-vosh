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
global class Describer {
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

  private static Map<Id, Describer> instances;

  private Map<String, Schema.SObjectType> globalDescriber;
  private Map<Schema.SObjectType, Schema.DescribeSObjectResult> objectDescribers;
  private Map<Schema.SObjectType, Map<Schema.SObjectType, String>> objectRelationshipNames;
  private Map<Schema.SObjectField, Schema.DescribeFieldResult> fieldDescribers;

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
   * @description It traverses the <code>SObjectField</code> reference tracking each hop with a helper
   * object that contains relative <code>SObjectType</code> and <code>SObjectField</code>.
   *
   * @param syntax the cross-reference syntax, not null
   * @return the list of hops
   * @throws System.IllegalArgumentException if the cross-reference syntax is invalid
   * @see Describer#traverse(Schema.SObjectType, String) traverse
   * @since 1.0.27
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
      when ENCRYPTEDSTRING, ID, PHONE, REFERENCE, STRING, TEXTAREA, URL {
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
