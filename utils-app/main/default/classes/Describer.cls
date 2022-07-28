/**
 * A helper class that for <code>SObjectType</code> objects and what revolves around them:
 * <code>DescribeSObjectResult, DescribeFieldResult</code>.
 * <p>
 * This class is meant to be used through a static instance since it wants to leverage cache
 * for reuse as opposed to calling Salesforce methods directly which would become time-expensive.
 *
 * @see Describer#getInstance() getInstance
 * @since 1.0.1
 */
global class Describer {
  /**
   * A result class for <code>Describer.traverse</code> that keeps track of cross-referencing traversing.
   *
   * @see Describer#traverse(Schema.SObjectType, String) traverse
   * @since 1.0.23
   */
  global class Hop {
    private Schema.SObjectType type;
    private Schema.SObjectField field;

    private Hop(Schema.SObjectType t, Schema.SObjectField f) {
      type = t;
      field = f;
    }

    global Schema.SObjectField getField() {
      return field;
    }

    global Schema.SObjectType getType() {
      return type;
    }
  }

  private static Map<Id, Describer> INSTANCES;

  private Map<String, Schema.SObjectType> globalDescriber;
  private Map<Schema.SObjectType, Schema.DescribeSObjectResult> objectDescribers;
  private Map<Schema.SObjectType, Map<Schema.SObjectType, String>> objectRelationshipNames;
  private Map<Schema.SObjectField, Schema.DescribeFieldResult> fieldDescribers;

  @SuppressWarnings('PMD.EmptyStatementBlock')
  private Describer() {
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
    Utils.requireNonNull(value, 'Value cannot be null');

    List<String> mapping = value.split('\\.');

    List<Hop> results = traverse(getGlobal().get(mapping[0]), value.removeStart(mapping[0] + '.'));

    return results.get(results.size() - 1).getField();
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
   * It returns the <a href="https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_methods_system_sobject_describe.htm#apex_methods_system_sobject_describe">DescribeSObjectResult</a>
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
   * @param type the <code>SObject</code> type, not null
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
      throw new UnsupportedOperationException(parent + ' does not have relationship with ' + child);
    }

    return value;
  }

  /**
   * It returns the <code>SObject</code> nested in a given <code>SObject</code>
   * by resolving cross-reference syntax.
   *
   * @param syntax the string representing the <code>SObjectField</code>, not null
   * @return the field value
   * @throws System.Exception if the field was not fetched for the object
   * @since 1.0.23
   */
  global SObject getRelatedObject(SObject so, String syntax) {
    Utils.requireNonNull(so, 'SObject cannot be null');
    Utils.requireNonNull(syntax, 'syntax cannot be null');

    Queue q = new Queue();
    q.addAll(syntax.split('\\.'));
    SObject drill = so;

    while (!q.isEmpty()) {
      String ref = (String) q.poll();

      if (q.isEmpty()) {
        return drill;
      }

      drill = drill.getSObject(ref);
    }

    throw new IllegalArgumentException(
      'Unable to resolve syntax "' +
      syntax +
      ' for ' +
      so.getSObjectType()
    );
  }

  /**
   * It returns the field value for a given nested <code>SObject</code>
   * by resolving cross-reference syntax.
   *
   * @param syntax the string representing the <code>SObjectField</code>, not null
   * @return the field value
   * @throws System.Exception if the field was not fetched for the object
   * @since 1.0.23
   */
  global Object getRelatedObjectValue(SObject so, String syntax) {
    SObject child = getRelatedObject(so, syntax);

    List<String> levels = syntax.split('\\.');

    return child.get(levels[levels.size() - 1]);
  }

  /**
   * It traverses the <code>SObjectField</code> reference tracking each hop with a helper
   * object that contains relative <code>SObjectType</code> and <code>SObjectField</code>.
   *
   * @param type the <code>SObjectType</code>, not null
   * @param reference the cross reference, not null
   * @return the list of hops
   * @since 1.0.23
   */
  global List<Hop> traverse(Schema.SObjectType type, String reference) {
    Utils.requireNonNull(type, 'SObjectType type cannot be null');
    Utils.requireNonNull(reference, 'Reference cannot be null');

    List<Hop> results = new List<Hop>{ new Hop(type, null) };
    List<String> breakdown = reference.split('\\.');

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
            '"{0}" in "{1}" is not a valid reference field name for {2}',
            new List<Object>{ fieldName, reference, currentResult.getType() }
          )
        );
      }

      List<Schema.SObjectType> references = getFieldDescribe(currentField).getReferenceTo();

      if (references.isEmpty()) {
        if (breakdown.isEmpty()) {
          currentResult.field = currentField;

          break;
        }

        throw new IllegalArgumentException(
          String.format(
            'Invalid cross reference "{0}" for "{1}"',
            new List<Object>{ reference, currentResult.getType() }
          )
        );
      }

      results.add(new Hop(references[0], currentField));
    }

    return results;
  }

  /**
   * It returns the static instance of <code>Describer</code>.
   *
   * @return the static instance of <code>Describer</code>
   * @see Describer
   * @since 1.0.1
   */
  global static Describer getInstance() {
    if (INSTANCES == null) {
      INSTANCES = new Map<Id, Describer>();
    }

    Id userId = UserInfo.getUserId();
    Describer describ = INSTANCES.get(userId);

    if (describ == null) {
      describ = new Describer();

      INSTANCES.put(userId, describ);
    }

    return describ;
  }
}
