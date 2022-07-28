/**
 * A helper methods to write tests with less code.
 *
 * @since 1.0.4
 */
@isTest
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessivePublicCount')
global class TestUtils {
  /**
   * @since 1.0.4
   */
  global class HttpCalloutMock implements System.HttpCalloutMock {
    private final List<HttpResponseMock> responses;

    /**
     * @since 1.0.4
     */
    global HttpCalloutMock() {
      responses = new List<HttpResponseMock>();
    }

    /**
     * @since 1.0.4
     */
    global HttpCalloutMock addResponse(HttpResponseMock value) {
      responses.add(value);

      return this;
    }

    /**
     * @since 1.0.4
     */
    global System.HTTPResponse respond(System.HTTPRequest req) {
      for (HttpResponseMock res : responses) {
        if (res.rule.matcher(req.getEndpoint()).matches()) {
          return res.respond();
        }
      }

      throw new UnsupportedOperationException(
        'No response implementation for ' + req.getEndpoint()
      );
    }
  }

  /**
   * @since 1.0.4
   */
  global class HttpResponseMock {
    private final System.Pattern rule;
    private final Integer statusCode;

    private Object body;

    /**
     * @since 1.0.4
     */
    global HttpResponseMock(System.Pattern rule) {
      this(rule, 200);
    }

    /**
     * @since 1.0.4
     */
    global HttpResponseMock(System.Pattern rule, Integer statusCode) {
      this.rule = rule;
      this.statusCode = statusCode;
    }

    /**
     * @since 1.0.4
     */
    global System.HTTPResponse respond() {
      System.HttpResponse res = new System.HttpResponse();

      res.setStatusCode(statusCode);

      if (body instanceof Blob) {
        res.setBodyAsBlob((Blob) body);
      } else if (body instanceof String) {
        res.setBody((String) body);
      }

      return res;
    }

    /**
     * @since 1.0.4
     */
    global HttpResponseMock setBody(Blob value) {
      body = value;

      return this;
    }

    /**
     * @since 1.0.4
     */
    global HttpResponseMock setBody(String value) {
      body = value;

      return this;
    }

    /**
     * @since 1.0.4
     */
    global HttpResponseMock setStaticResourceBody(String name) {
      return setStaticResourceBody(name, null);
    }

    /**
     * @since 1.0.4
     */
    global HttpResponseMock setStaticResourceBody(String name, String key) {
      return setStaticResourceBody(name, key, new List<String>());
    }

    /**
     * @since 1.0.4
     */
    global HttpResponseMock setStaticResourceBody(String name, String key, List<String> variables) {
      Schema.StaticResource resource = [SELECT Body FROM StaticResource WHERE Name = :name LIMIT 1];

      body = resource.Body.toString();

      if (key != null) {
        body = JSON.serialize(Utils.deserializeToMapper((String) body).getObject(key));
      }

      for (Integer i = 0; i < variables.size(); i++) {
        body = ((String) body).replace('{' + i + '}', variables.get(i));
      }

      return this;
    }
  }

  /**
   * A builder that lays the foundation to generate any number of SObject records
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
     * It creates an instance that will generate <code>SObject</code> records
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
     * It flags the given field to append an index enumeration to the value provided.
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
     * It generates all the <code>SObject</code> records according to the currently set options.
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

    virtual SObject makeOne(Integer index) {
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
     * It registers a default field value that will be set
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
     * It registers a default field value that will be set
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
     * It sets the auto-insert options that controls whether the <code>make()</code> method
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
     * It sets the number of records the <code>make()</code> method will create.
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
     * It sets the <code>OwnerId</code> field for any record that will be generated
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

      randomain = new Utils.RandomizerBuilder()
        .setLength(8)
        .setPreferences(
          new Set<Utils.RandomizerPreference>{
            Utils.RandomizerPreference.INCLUDE_LETTER,
            Utils.RandomizerPreference.INCLUDE_NUMBER
          }
        )
        .build()
        .generate();
    }

    override SObject makeOne(Integer index) {
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
   * It activates the standard Pricebook.
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
   * It assigns the user the permission set provided.
   *
   * @param name the permission name
   * @param userId the user id
   * @since 1.0.9
   */
  global static void assignPermission(String name, Id userId) {
    Schema.PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = :name];

    insert new Schema.PermissionSetAssignment(AssigneeId = userId, PermissionSetId = ps.Id);
  }

  /**
   * It returns the profile id of the profile name provided.
   *
   * @param name the profile name
   * @return the profile id
   * @since 1.0.4
   */
  global static Id getProfileId(String name) {
    return getProfileIds(new Set<String>{ name }).get(name);
  }

  /**
   * It returns a map of profile names and respective ids for the names provided.
   *
   * @param names the profile names
   * @return the map with names and ids
   * @since 1.0.4
   */
  global static Map<String, Id> getProfileIds(Set<String> names) {
    Map<String, Id> profiles = new Map<String, Id>();

    for (Schema.Profile record : [SELECT Id, Name FROM Profile WHERE Name IN :names]) {
      profiles.put(record.Name, record.Id);
    }

    return profiles;
  }

  /**
   * It returns the current user <code>User</code> SObject exclusively containing the record id.
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
   * @param value the user id
   * @return the <code>User</code> SObject
   * @see #getUser() getUser
   * @since 1.0.4
   */
  global static Schema.User getUser(Id value) {
    return [SELECT Id FROM User WHERE Id = :value];
  }
}
