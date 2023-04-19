@isTest(isParallel=true)
public class SoqlerTest {
  @testSetup
  static void init() {
    Id minimumProfileId = TestUtils.getMinimumAccessProfileId();

    // Generating user
    Schema.User minimumUser = (Schema.User) new TestUtils.UserMaker()
      .setProfileId(minimumProfileId != null ? minimumProfileId : UserInfo.getProfileId())
      .setLastName('Insufficient')
      .setCount(1)
      .setAutoInsert(false)
      .enumerate(Schema.User.LastName)
      .make()
      .get(0);

    System.runAs(TestUtils.getUser()) {
      insert minimumUser;
    }

    // Generating accounts
    List<SObject> accts = new TestUtils.AccountMaker()
      .setName('Account')
      .set(Schema.Account.BillingCity, 'Rome')
      .setCount(3)
      .enumerate(Schema.Account.Name)
      .make();

    // Generating contacts
    List<SObject> cnts = new TestUtils.ContactMaker().setLastName('Dummy').setCount(3).make();

    // Generating events
    List<SObject> evts = new TestUtils.EventMaker()
      .setEntryTime(0, Datetime.now().addMinutes(10), Datetime.now().addMinutes(20))
      .setEntryTime(1, Datetime.now().addMinutes(30), Datetime.now().addMinutes(40))
      .setEntryTime(2, Datetime.now().addMinutes(50), Datetime.now().addMinutes(60))
      .setWhatId(accts[0].Id)
      .setOwnerId(minimumUser.Id)
      .setCount(3)
      .make();
  }

  private static Schema.User getMinimumUser() {
    return [SELECT Id, ProfileId FROM User WHERE LastName = 'Insufficient0' LIMIT 1];
  }

  @isTest
  static void duplicateFieldAvoidance() {
    final Soqler query = new Soqler(Schema.Account.SObjectType);

    query.fields().add(Schema.Account.Name).add(Schema.Account.Name);

    System.assertEquals('SELECT Name FROM Account', query.queryToString());
  }

  @isTest
  static void queryAccounts() {
    Soqler query = new Soqler(Schema.Account.SObjectType);

    try {
      query.query();

      System.assert(false, 'Query should have thrown an exception due to missing fields');
    } catch (QueryException e) {
      query.fields().add(Account.Name);
    }

    Set<Id> ownerIds = new Set<Id>();

    try {
      query.wheres().addAnd(new Soqler.IWhereName(Account.OwnerId, 'IN', ownerIds));

      System.assert(false, 'Query where value should have been List<?>');
    } catch (UnsupportedOperationException e) {
      System.assert(e.getMessage().contains('Set<?>'), e.getMessage());
    }

    ownerIds.add(UserInfo.getUserId());

    query.wheres().addAnd(new Soqler.IWhereName(Account.OwnerId, 'IN', new List<Id>(ownerIds)));

    query.setMaxCount(2);

    List<Account> accounts = (List<Account>) query.query();

    System.assertEquals(2, accounts.size(), 'Query should have returned 2 accounts');

    query.setMaxCount(null);

    System.assertEquals(3, query.queryCount());
  }

  @isTest
  static void queryAccountsAggregates() {
    Soqler query = new Soqler(Schema.Account.SObjectType);
    Soqler.IFieldName col = new Soqler.IFieldName(Schema.Account.Id);

    try {
      query.fields().add(col.withFunction('COUNT(Id)'));

      System.assert(false, 'Query should have thrown an exception due to function invalid syntax');
    } catch (UnsupportedOperationException e) {
      query.fields().add(col.withFunction('COUNT({0})'));
    }

    AggregateResult[] results = query.queryAggregates();

    System.assertEquals(3, results[0].get('expr0'), 'Query should have counted 3 accounts');

    query = new Soqler(Schema.Account.SObjectType);
    query.fields().add(Schema.Account.BillingCity);
    query.groups().add(Schema.Account.BillingCity);

    results = query.queryAggregates();

    System.assertEquals(1, results.size(), 'Query should have counted 1 unique BillingCity match');

    for (AggregateResult result : results) {
      System.assertEquals('Rome', result.get(String.valueOf(Schema.Account.BillingCity)));
    }
  }

  @isTest
  static void queryEvents() {
    Soqler query = new Soqler(Schema.Event.SObjectType);

    query.fields()
      .add(new Soqler.IFieldName(Schema.Event.Id))
      .add(
        new Soqler.IFieldTypeOf('What')
          .when(Schema.Account.SObjectType, new Set<Schema.SObjectField>{ Schema.Account.Name })
      )
      .add(
        new Soqler.IFieldTypeOf('Who')
          .when(Schema.Lead.SObjectType, new Set<Schema.SObjectField>{ Schema.Lead.Name })
      );

    Soqler.IWhereGroup grp = new Soqler.IWhereGroup();
    grp.wheres()
      .addOr(
        new Soqler.IWhereTypeOf(
          'What',
          'IN',
          new Set<Schema.SObjectType>{ Schema.Account.SObjectType }
        )
      )
      .addOr(
        new Soqler.IWhereTypeOf('Who', 'IN', new Set<Schema.SObjectType>{ Schema.Lead.SObjectType })
      );

    query.wheres()
      .addAnd(grp)
      .addAnd(
        new Soqler.IWhereName(Schema.Event.CreatedDate, '=', Date.today().year())
          .withFunction('CALENDAR_YEAR({0})')
      );

    List<Schema.Event> events = (List<Schema.Event>) query.query();

    System.assertEquals(3, events.size());
  }

  @isTest
  static void querySec() {
    Schema.User minimumUser = getMinimumUser();

    if (minimumUser.ProfileId == UserInfo.getProfileId()) {
      // What a shame, couldn't find an minimum profile id to test FLS

      return;
    }

    Test.startTest();

    System.runAs(minimumUser) {
      Soqler query = new Soqler(Schema.Contact.SObjectType);
      Schema.SObjectField forbiddenField = Schema.Contact.Name;

      query.fields().add(Schema.Contact.Name);

      try {
        query.query();

        System.assert(false, 'Query should have thrown a AuditException');
      } catch (Sec.AuditException e) {
        System.assert(e.getMessage().contains(String.valueOf(forbiddenField)), e.getMessage());
      }
    }

    Test.stopTest();
  }

  @isTest
  static void syntax() {
    // Composing SELECT
    Soqler query, subquery;

    // Composing COUNT()
    query = new Soqler(Schema.Organization.SObjectType);

    System.assertEquals('SELECT COUNT() FROM Organization', query.queryCountToString());

    // Adding all fields
    query = new Soqler(Schema.Organization.SObjectType);

    List<String> fieldNames = new List<String>(
      Describer.getInstance().getObjectFieldMap(query.getType()).keySet()
    );

    query.fields().addAll();

    // Protecting against the possibility of having 0 fields returned due to restricted API access
    System.assertEquals(
      ('SELECT ' +
        (fieldNames.isEmpty() ? null : String.join(fieldNames, ', ')) +
        ' FROM Organization')
        .toLowerCase(),
      query.queryToString().toLowerCase()
    );

    // Adding specific fields
    query = new Soqler(Schema.Account.SObjectType);

    System.assertEquals(Schema.Account.SObjectType, query.getType());

    query.fields()
      .add(new Soqler.IFieldName(Schema.Account.Name))
      .add(new Soqler.IFieldName(Schema.Account.Type).withFunction('toLabel({0})'))
      .add(new Soqler.IFieldName(Schema.Account.Phone).setDroppable(true))
      .add(new Soqler.IFieldName('Owner', Schema.User.Name));

    System.assertEquals(
      'SELECT Name, toLabel(Type), Phone, Owner.Name FROM Account',
      query.queryToString()
    );
    System.assertEquals(query.queryToString(), query.queryLocator().getQuery());

    subquery = new Soqler(Schema.Contact.SObjectType);

    subquery.fields().add(Schema.Contact.Name);

    query.fields().add(subquery);

    System.assertEquals(
      'SELECT Name, toLabel(Type), Phone, Owner.Name, (SELECT Name FROM Contacts) FROM Account',
      query.queryToString()
    );

    // Composing WHERE

    subquery = new Soqler(Contact.SObjectType);

    subquery.fields().add(Contact.AccountId);

    query.wheres()
      .addAnd(new Soqler.IWhereName(Schema.Account.Id, 'NOT IN', new List<String>{ 'FAKE_ID' }))
      .addAnd(new Soqler.IWhereName('Owner', Schema.Contact.Name, '!=', 'Test Test'))
      .addAnd(Schema.Account.Id, 'IN', subquery);

    System.assertEquals(
      'SELECT Name, toLabel(Type), Phone, Owner.Name, (SELECT Name FROM Contacts) FROM Account' +
        ' WHERE Id NOT IN (\'FAKE_ID\')' +
        ' AND Owner.Name != \'Test Test\'' +
        ' AND Id IN (SELECT AccountId FROM Contact)',
      query.queryToString()
    );

    query = new Soqler(Schema.Account.SObjectType);

    query.fields().add(Schema.Account.Id);

    Soqler.IWhereGroup grp = new Soqler.IWhereGroup();
    grp.wheres()
      .addOr(new Soqler.IWhereLocation(Schema.Account.BillingAddress, 45.0, 11.0, '<', 10.0))
      .addOr(new Soqler.IWhereName(Schema.Account.BillingCity, '=', 'Vicenza'));

    query.wheres()
      .addAnd(new Soqler.IWhereName(Schema.Account.CreatedDate, '>', Date.newInstance(2018, 1, 1)))
      .addAnd(new Soqler.IWhereName(Schema.Account.NumberOfEmployees, '>', 10))
      .addAnd(grp)
      .addAnd(new Soqler.IWhereVariable(Schema.Account.Type, 'IN', 'accountTypes'));

    System.assertEquals(
      'SELECT Id FROM Account' +
        ' WHERE DAY_ONLY(CreatedDate) > 2018-01-01' +
        ' AND NumberOfEmployees > 10' +
        ' AND (DISTANCE(BillingAddress, GEOLOCATION(45.0, 11.0), \'km\') < 10.0' +
        ' OR BillingCity = \'Vicenza\')' +
        ' AND Type IN :accountTypes',
      query.queryToString()
    );

    // Composing LIMIT, OFFSET, ORDER
    query = new Soqler(Schema.Account.SObjectType);

    query.fields().add(Schema.Account.Id);

    query.setMaxCount(1000).setOffset(90);

    query.orders()
      .add(new Soqler.IOrderLocation(Schema.Account.BillingAddress, 45.0, 11.0))
      .add(new Soqler.IOrderName(Schema.Account.Name))
      .add(new Soqler.IOrderName('Owner', Schema.User.Name))
      .add(new Soqler.IOrderName(Schema.Account.Phone, Soqler.OrderType.DESCENDING_NULLS_LAST));

    System.assertEquals(
      'SELECT Id FROM Account' +
        ' ORDER BY DISTANCE(BillingAddress, GEOLOCATION(45.0, 11.0), \'km\')' +
        ', Name' +
        ', Owner.Name' +
        ', Phone DESC NULLS LAST' +
        ' LIMIT 1000' +
        ' OFFSET 90',
      query.queryToString()
    );

    // Composing TypeOf
    query = new Soqler(Schema.Event.SObjectType);

    query.fields()
      .add(Schema.Event.Id)
      .add(
        new Soqler.IFieldTypeOf('What')
          .when(
            Schema.Account.SObjectType,
            new Map<Schema.SObjectField, Boolean>{ Schema.Account.Phone => true }
          )
          .when(
            Schema.Opportunity.SObjectType,
            new Map<Schema.SObjectField, Boolean>{ Schema.Opportunity.Amount => true }
          )
      );

    query.wheres()
      .addAnd(
        new Soqler.IWhereTypeOf(
          'What',
          'IN',
          new Set<Schema.SObjectType>{ Schema.Account.SObjectType, Schema.Opportunity.SObjectType }
        )
      );

    System.assertEquals(
      'SELECT Id,' +
        ' TYPEOF What WHEN Account THEN Phone WHEN Opportunity THEN Amount ELSE Id END' +
        ' FROM Event' +
        ' WHERE What.Type IN (\'Account\', \'Opportunity\')',
      query.queryToString()
    );

    // Composing Aggregates
    query = new Soqler(Schema.Event.SObjectType);
    query.fields()
      .add(Schema.Event.Subject)
      .add(new Soqler.IFieldName(Schema.Event.CreatedDate).withFunction('AVG(CALENDAR_YEAR({0}))'));
    query.groups().add(new Soqler.IGroupName('Owner', Schema.User.Name));

    System.assertEquals(
      'SELECT Subject,' +
        ' AVG(CALENDAR_YEAR(CreatedDate))' +
        ' FROM Event' +
        ' GROUP BY Owner.Name',
      query.queryToString()
    );

    // Composing Aggregates
    query = new Soqler(Schema.Contact.SObjectType);
    query.fields().add(Schema.Contact.AccountId);
    query.groups().add(new Soqler.IGroupName(Schema.Contact.AccountId));
    query.havings()
      .addAnd(new Soqler.IWhereName(Schema.Contact.AccountId, '>', 5).withFunction('COUNT({0})'));
    query.orders().add(new Soqler.IOrderName(Schema.Contact.AccountId).withFunction('COUNT({0})'));

    System.assertEquals(
      'SELECT AccountId' +
        ' FROM Contact' +
        ' GROUP BY AccountId' +
        ' HAVING COUNT(AccountId) > 5' +
        ' ORDER BY COUNT(AccountId)',
      query.queryToString()
    );
  }
}
