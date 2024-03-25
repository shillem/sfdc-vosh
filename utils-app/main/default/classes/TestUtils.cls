/**
 * @description A helper methods to write tests with less code.
 *
 * @since 1.0.4
 */
@isTest
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessivePublicCount')
global class TestUtils {
  /**
   * @description
   *
   * @since 1.0.4
   */
  global class HttpCalloutMock implements System.HttpCalloutMock {
    private final List<HttpResponseMock> responses;

    /**
     * @description
     *
     * @since 1.0.4
     */
    global HttpCalloutMock() {
      responses = new List<HttpResponseMock>();
    }

    /**
     * @description
     *
     * @since 1.0.4
     */
    global HttpCalloutMock addResponse(HttpResponseMock value) {
      responses.add(value);

      return this;
    }

    /**
     * @description
     *
     * @since 1.1
     */
    global List<HttpResponseMock> getResponses() {
      return responses;
    }

    /**
     * @description
     *
     * @since 1.1
     */
    global Boolean isEmpty() {
      return responses.isEmpty();
    }

    /**
     * @description
     *
     * @since 1.0.4
     */
    global System.HTTPResponse respond(System.HTTPRequest req) {
      for (HttpResponseMock res : responses) {
        if (res.matches(req)) {
          return res.respond(req);
        }
      }

      throw new UnsupportedOperationException(
        String.format(
          'No response implementation for [{0}] {1}',
          new List<Object>{ req.getMethod(), req.getEndpoint() }
        )
      );
    }
  }

  /**
   * @description
   *
   * @since 1.0.4
   */
  global class HttpResponseMock {
    private final System.Pattern rule;
    private final Map<String, HttpResponseMockCombo> combos;

    /**
     * @description
     *
     * @since 1.0.4
     */
    global HttpResponseMock(System.Pattern rule) {
      this.rule = rule;
      this.combos = new Map<String, HttpResponseMockCombo>();
    }

    /**
     * @description
     *
     * @since 1.1
     */
    global HttpResponseMock add(String method) {
      return add(method, 200);
    }

    /**
     * @description
     *
     * @since 1.1
     */
    global HttpResponseMock add(String method, Integer statusCode) {
      return add(method, statusCode, null);
    }

    /**
     * @description
     *
     * @since 1.1
     */
    global HttpResponseMock add(String method, Integer statusCode, Object body) {
      combos.put(method, new HttpResponseMockCombo(method, statusCode, body));

      return this;
    }

    /**
     * @description
     *
     * @since 1.1
     */
    global Integer getInvocations() {
      Integer value = 0;

      for (HttpResponseMockCombo combo : combos.values()) {
        value += combo.invocations;
      }

      return value;
    }

    global Boolean matches(System.HttpRequest req) {
      return rule.matcher(req.getEndpoint()).matches() && combos.containsKey(req.getMethod());
    }

    /**
     * @description
     *
     * @since 1.0.4
     */
    global System.HTTPResponse respond(System.HttpRequest req) {
      return combos.get(req.getMethod()).respond();
    }
  }

  private class HttpResponseMockCombo {
    private final String method;
    private final Integer statusCode;
    private final Object body;

    private Integer invocations;

    private HttpResponseMockCombo(String method, Integer statusCode, Object body) {
      this.method = method;
      this.statusCode = statusCode;
      this.body = treatBody(body);

      this.invocations = 0;
    }

    private System.HttpResponse respond() {
      final System.HttpResponse res = new System.HttpResponse();

      res.setStatusCode(statusCode);

      if (body instanceof Blob) {
        res.setBodyAsBlob((Blob) body);
      } else if (body instanceof String) {
        res.setBody((String) body);
      }

      invocations++;

      return res;
    }

    private Object treatBody(Object body) {
      if (body instanceof Blob || body instanceof String) {
        return body;
      }

      if (!(body instanceof HttpResponseMockStaticResourceBody)) {
        return null;
      }

      final HttpResponseMockStaticResourceBody req = (HttpResponseMockStaticResourceBody) body;

      String result = SchemaUtils.getStaticResourceBody(req.name);

      if (req.key != null) {
        result = JSON.serialize(Utils.deserializeToMapper(result).getObject(req.key));
      }

      if (req.variables != null) {
        for (Integer i = 0; i < req.variables.size(); i++) {
          result = ((String) result).replace('{' + i + '}', req.variables.get(i));
        }
      }

      return result;
    }
  }

  /**
   * @description
   *
   * @since 1.1
   */
  public class HttpResponseMockStaticResourceBody {
    private final String name;

    private String key;
    private List<String> variables;

    public HttpResponseMockStaticResourceBody(String name) {
      Utils.requireNonNull(name, 'Name cannot be null');

      this.name = name;
    }

    public HttpResponseMockStaticResourceBody withKey(String value) {
      key = value;
      return this;
    }

    public HttpResponseMockStaticResourceBody withVariables(List<String> values) {
      variables = values;
      return this;
    }
  }

  /**
   * @description A builder that lays the foundation to generate any number of SObject records
   *
   * @since 1.0.4
   */
  global virtual class SObjectMaker {
    private final Schema.SObjectType type;
    private final Map<Schema.SObjectField, Object> defaults;
    private final List<Schema.SObjectField> enumerables;
    private final Map<Integer, Map<Schema.SObjectField, Object>> specifics;

    private Boolean autoInsert;
    private Integer count;
    private Id ownerId;

    /**
     * @description It creates an instance that will generate <code>SObject</code> records
     * of the provided <code>SObjectType</code>.
     *
     * @param type the <code>SObjectType</code>
     * @since 1.0.4
     */
    global SObjectMaker(Schema.SObjectType type) {
      this.type = type;
      this.defaults = new Map<Schema.SObjectField, Object>();
      this.enumerables = new List<Schema.SObjectField>();
      this.specifics = new Map<Integer, Map<Schema.SObjectField, Object>>();

      this.autoInsert = true;
    }

    /**
     * @description It flags the given field to append an index enumeration to the value provided.
     * The enumeration will be applied once the <code>make()</code> is invoked.
     *
     * @param field the field
     * @return the maker instance
     * @since 1.0.18
     */
    global SObjectMaker enumerate(Schema.SObjectField field) {
      enumerables.add(field);
      return this;
    }

    /**
     * @description It generates all the <code>SObject</code> records according to the currently set options.
     * By default the records will be automatically inserted. To prevent this behaviour disable
     * auto-insert.
     *
     * @since 1.0.4
     */
    global List<SObject> make() {
      List<SObject> records = new List<SObject>();

      for (Integer i = 0; i < count; i++) {
        records.add(makeOne(i));
      }

      if (autoInsert) {
        insert records;
      }

      return records;
    }

    protected virtual SObject makeOne(Integer index) {
      SObject instance = type.newSObject();

      if (ownerId != null) {
        instance.put('OwnerId', ownerId);
      }

      for (Schema.SObjectField field : defaults.keySet()) {
        instance.put(
          field,
          enumerables.contains(field) ? (String) defaults.get(field) + index : defaults.get(field)
        );
      }

      Map<Schema.SObjectField, Object> specs = specifics.get(index);

      if (specs != null) {
        for (Schema.SObjectField field : specs.keySet()) {
          instance.put(field, specs.get(field));
        }
      }

      return instance;
    }

    /**
     * @description It registers a default field value that will be set
     * for each generated record once the <code>make()</code> is invoked.
     *
     * @param field the field
     * @param value the value
     * @return the maker instance
     * @since 1.0.18
     */
    global SObjectMaker set(Schema.SObjectField field, Object value) {
      defaults.put(field, value);

      return this;
    }

    /**
     * @description It registers a default field value that will be set
     * for an index-specific generated record once the <code>make()</code> is invoked.
     *
     * @param index the index
     * @param field the field
     * @param value the value
     * @return the maker instance
     * @since 1.0.18
     */
    global SObjectMaker setEntry(Integer index, Schema.SObjectField field, Object value) {
      Map<Schema.SObjectField, Object> values = specifics.get(index);

      if (values == null) {
        values = new Map<Schema.SObjectField, Object>();

        specifics.put(index, values);
      }

      values.put(field, value);

      return this;
    }

    /**
     * @description It sets the auto-insert options that controls whether the <code>make()</code> method
     * will insert the records or not.
     *
     * @param value the toggle
     * @return the maker instance
     * @since 1.0.4
     */
    global SObjectMaker setAutoInsert(Boolean value) {
      autoInsert = value;
      return this;
    }

    /**
     * @description It sets the number of records the <code>make()</code> method will create.
     *
     * @param value the count
     * @return the maker instance
     * @since 1.0.4
     */
    global SObjectMaker setCount(Integer value) {
      count = value;
      return this;
    }

    /**
     * @description It sets the <code>OwnerId</code> field for any record that will be generated
     * by the <code>make()</code> method.
     *
     * @param value the owner id
     * @return the maker instance
     * @since 1.0.4
     */
    global SObjectMaker setOwnerId(Id value) {
      ownerId = value;
      return this;
    }
  }

  global class AccountMaker extends SObjectMaker {
    private String name;

    global AccountMaker() {
      super(Schema.Account.SObjectType);
    }

    global AccountMaker setName(String value) {
      return (AccountMaker) set(Schema.Account.Name, value);
    }
  }

  global class ContactMaker extends SObjectMaker {
    global ContactMaker() {
      super(Schema.Contact.SObjectType);
    }

    global ContactMaker setFirstName(String value) {
      return (ContactMaker) set(Schema.Contact.FirstName, value);
    }

    global ContactMaker setLastName(String value) {
      return (ContactMaker) set(Schema.Contact.LastName, value);
    }
  }

  global class EventMaker extends SObjectMaker {
    global EventMaker() {
      super(Schema.Event.SObjectType);
    }

    global EventMaker setEntryTime(Integer index, Datetime startTime, Datetime endTime) {
      setEntry(index, Schema.Event.StartDateTime, startTime);
      setEntry(index, Schema.Event.EndDateTime, endTime);

      return this;
    }

    global EventMaker setSubject(Id value) {
      return (EventMaker) set(Schema.Event.Subject, value);
    }

    global EventMaker setTime(Datetime startTime, Datetime endTime) {
      set(Schema.Event.StartDateTime, startTime);
      set(Schema.Event.EndDateTime, endTime);

      return this;
    }

    global EventMaker setWhatId(Id value) {
      return (EventMaker) set(Schema.Event.WhatId, value);
    }

    global EventMaker setWhoId(Id value) {
      return (EventMaker) set(Schema.Event.WhoId, value);
    }
  }

  global class LeadMaker extends SObjectMaker {
    global LeadMaker() {
      super(Schema.Lead.SObjectType);
    }

    global LeadMaker setCompany(String value) {
      return (LeadMaker) set(Schema.Lead.Company, value);
    }

    global LeadMaker setFirstName(String value) {
      return (LeadMaker) set(Schema.Lead.FirstName, value);
    }

    global LeadMaker setLastName(String value) {
      return (LeadMaker) set(Schema.Lead.LastName, value);
    }
  }

  global class OpportunityMaker extends SObjectMaker {
    global OpportunityMaker() {
      super(Schema.Opportunity.SObjectType);
    }

    global OpportunityMaker setAccountId(Id value) {
      return (OpportunityMaker) set(Schema.Opportunity.AccountId, value);
    }

    global OpportunityMaker setActiveStageName() {
      List<Schema.PicklistEntry> stageNames = Describer.getInstance()
        .getFieldDescribe(Schema.Opportunity.StageName)
        .getPicklistValues();

      for (Schema.PicklistEntry entry : stageNames) {
        if (entry.isActive()) {
          return (OpportunityMaker) setStageName(entry.getValue());
        }
      }

      return this;
    }

    global OpportunityMaker setCloseDate(Date value) {
      return (OpportunityMaker) set(Schema.Opportunity.CloseDate, value);
    }

    global OpportunityMaker setName(String value) {
      return (OpportunityMaker) set(Schema.Opportunity.Name, value);
    }

    global OpportunityMaker setStageName(String value) {
      return (OpportunityMaker) set(Schema.Opportunity.StageName, value);
    }
  }

  global class ProductPriceMaker {
    private SObjectMaker pricebookEntryMaker;
    private SObjectMaker productMaker;

    global ProductPriceMaker() {
      pricebookEntryMaker = new SObjectMaker(Schema.PricebookEntry.SObjectType);
      productMaker = new SObjectMaker(Schema.Product2.SObjectType);
    }

    global List<ProductPricePair> make() {
      List<Schema.Product2> products = (List<Schema.Product2>) productMaker.make();

      for (Integer index = 0; index < products.size(); index++) {
        pricebookEntryMaker.setEntry(
          index,
          Schema.PricebookEntry.Product2Id,
          products.get(index).Id
        );
      }

      List<Schema.PricebookEntry> prices = (List<Schema.PricebookEntry>) pricebookEntryMaker.make();

      List<ProductPricePair> pairs = new List<ProductPricePair>();

      for (Integer index = 0; index < products.size(); index++) {
        Schema.Product2 pro = products.get(index);

        pairs.add(new ProductPricePair(pro, prices.get(index)));
      }

      return pairs;
    }

    global ProductPriceMaker setActive(Boolean value) {
      pricebookEntryMaker.set(Schema.PricebookEntry.IsActive, value);
      return this;
    }

    global ProductPriceMaker setCount(Integer value) {
      pricebookEntryMaker.setCount(value);
      productMaker.setCount(value);
      return this;
    }

    global ProductPriceMaker setName(String value) {
      productMaker.set(Schema.Product2.Name, value);
      return this;
    }

    global ProductPriceMaker setFamily(String value) {
      productMaker.set(Schema.Product2.Family, value);
      return this;
    }

    global ProductPriceMaker setPricebookEntry(
      Integer index,
      Schema.SObjectField field,
      Object value
    ) {
      pricebookEntryMaker.setEntry(index, field, value);
      return this;
    }

    global ProductPriceMaker setPricebookId(Id value) {
      pricebookEntryMaker.set(Schema.PricebookEntry.Pricebook2Id, value);
      return this;
    }

    global ProductPriceMaker setProductEntry(
      Integer index,
      Schema.SObjectField field,
      Object value
    ) {
      productMaker.setEntry(index, field, value);
      return this;
    }

    global ProductPriceMaker setUnitPrice(Decimal value) {
      pricebookEntryMaker.set(Schema.PricebookEntry.UnitPrice, value);
      return this;
    }
  }

  global class ProductPricePair {
    global final Schema.PricebookEntry price;
    global final Schema.Product2 product;

    private ProductPricePair(Schema.Product2 product, Schema.PricebookEntry price) {
      this.price = price;
      this.product = product;
    }
  }

  global class UserMaker extends SObjectMaker {
    private String firstName;
    private String lastName;
    private Id profileId;
    private String randomain;

    global UserMaker() {
      super(Schema.User.SObjectType);

      randomain = new Randomizer.Builder()
        .setLength(8)
        .setOptions(
          new Set<Randomizer.Option>{
            Randomizer.Option.INCLUDE_LETTER,
            Randomizer.Option.INCLUDE_NUMBER
          }
        )
        .build()
        .generate();
    }

    protected override SObject makeOne(Integer index) {
      Schema.User obj = (Schema.User) super.makeOne(index);
      obj.EmailEncodingKey = 'UTF-8';
      obj.LanguageLocaleKey = 'en_US';
      obj.TimeZoneSidKey = 'Europe/Rome';

      obj.Alias = obj.LastName.toLowerCase().right(8);
      obj.Email = obj.LastName.toLowerCase() + '@' + randomain + '.rnd';
      obj.LocaleSidKey = obj.LanguageLocaleKey;

      obj.Username = obj.Email;
      obj.CommunityNickname = obj.Alias + '.' + randomain;
      return obj;
    }

    global UserMaker setFirstName(String value) {
      return (UserMaker) set(Schema.User.FirstName, value);
    }

    global UserMaker setLastName(String value) {
      return (UserMaker) set(Schema.User.LastName, value);
    }

    global UserMaker setProfileId(Id value) {
      return (UserMaker) set(Schema.User.ProfileId, value);
    }
  }

  /**
   * @description It activates the standard Pricebook.
   *
   * @param userId the standard pricebook id
   * @since 1.0.18
   */
  global static Id activateStandardPricebook() {
    Schema.Pricebook2 pricebook = new Schema.Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );

    update pricebook;

    return pricebook.Id;
  }

  /**
   * @description It returns the chatter profile id.
   *
   * @return the profile id
   * @since 1.1
   */
  global static Id getChatterProfileId() {
    List<Schema.Profile> records = [SELECT Id FROM Profile WHERE UserType = 'CsnOnly' LIMIT 1];

    return records[0]?.Id;
  }

  /**
   * @description It returns the most limited access profile id.
   *
   * @return the profile id
   * @since 1.1
   */
  global static Id getMinimumAccessProfileId() {
    return SchemaUtils.getProfileId('Minimum Access - Salesforce');
  }

  /**
   * @description It returns the current user <code>User</code> SObject exclusively containing the record id.
   * <p>
   * This method can be useful when running <code>System.runAs()</code>.
   *
   * @return the <code>User</code> SObject
   * @see #getUser(Id) getUser
   * @since 1.0.4
   */
  global static Schema.User getUser() {
    return getUser(UserInfo.getUserId());
  }

  /**
   * @description @param value the user id
   * @return the <code>User</code> SObject
   * @see #getUser() getUser
   * @since 1.0.4
   */
  global static Schema.User getUser(Id value) {
    return [SELECT Id FROM User WHERE Id = :value];
  }
}
