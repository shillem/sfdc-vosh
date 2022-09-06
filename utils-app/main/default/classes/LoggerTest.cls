@isTest
public class LoggerTest implements Logger.AllowFlushes {
  private static final List<String> ALL_APPENDERS = new List<String>{
    Logger.ConsoleAppender.class.getName(),
    Logger.PlatformEventAppender.class.getName()
  };

  @isTest
  static void catchAll() {
    insert new Schema.Cs_Logger__c(
      Appenders__c = String.join(ALL_APPENDERS, ','),
      Name = '*',
      Threshold__c = 'INFO'
    );

    Test.startTest();

    Logger.Instance log = Logger.getInstance(LoggerTest.class);

    log.info('Info');
    log.debug('Debug');

    Map<String, List<Logger.Entry>> entries = log.pullEntries();

    Test.stopTest();

    System.assert(entries.containsKey(Logger.PlatformEventAppender.class.getName()));
    System.assertEquals(1, entries.get(Logger.PlatformEventAppender.class.getName()).size());
  }

  @isTest
  static void catchAllAndSpecific() {
    insert new List<Schema.Cs_Logger__c>{
      new Schema.Cs_Logger__c(
        Appenders__c = String.join(ALL_APPENDERS, ','),
        Name = '*',
        Threshold__c = 'INFO'
      ),
      new Schema.Cs_Logger__c(
        Appenders__c = String.join(ALL_APPENDERS, ','),
        Class_Names__c = Soqler.class.getName(),
        Name = 'Soqler',
        Threshold__c = 'DEBUG'
      )
    };

    Test.startTest();

    Logger.Instance log = Logger.getInstance(LoggerTest.class);

    log.debug('Debug');
    log.error(new IllegalArgumentException('Invalid argument'));
    log.error('Description', new IllegalArgumentException('Invalid argument'));

    Soqler soql = new Soqler(Schema.Account.SObjectType);
    soql.fields().add(Schema.Account.Id);
    soql.queryToString();

    Test.stopTest();

    List<Logger.Entry> entries = log.pullEntries()
      .get(Logger.PlatformEventAppender.class.getName());

    System.assertEquals(3, entries.size());
    System.assert(((String) entries[0].v).contains('Invalid argument'));
    System.assert(((String) entries[1].v).startsWith('Description'));
    System.assert(((String) entries[2].v).contains('SELECT'));
  }

  @isTest
  static void fineAndDiscarded() {
    insert new List<Schema.Cs_Logger__c>{
      new Schema.Cs_Logger__c(
        Appenders__c = String.join(ALL_APPENDERS, ','),
        Name = '*',
        Threshold__c = 'FINEST'
      ),
      new Schema.Cs_Logger__c(
        Appenders__c = String.join(ALL_APPENDERS, ','),
        Class_Names__c = Soqler.class.getName(),
        Is_Disabled__c = true,
        Name = 'Soqler',
        Threshold__c = 'INFO'
      )
    };

    Test.startTest();

    Logger.Instance log = Logger.getInstance(LoggerTest.class);

    for (Integer i = 0; i < 250; i++) {
      log.finest(i);
    }

    Soqler soql = new Soqler(Schema.Account.SObjectType);
    soql.fields().add(Schema.Account.Id);
    soql.queryToString();

    Test.stopTest();

    List<Logger.Entry> entries = log.pullEntries()
      .get(Logger.PlatformEventAppender.class.getName());

    System.assertEquals(200, entries.size());
    System.assertEquals(249, ((Integer) entries[198].v));
    System.assert(((String) entries[199].v).contains('SELECT'));
  }

  @isTest
  static void firstCaller() {
    insert new List<Schema.Cs_Logger__c>{
      new Schema.Cs_Logger__c(
        Appenders__c = String.join(ALL_APPENDERS, ','),
        Name = '*',
        Threshold__c = 'INFO'
      ),
      new Schema.Cs_Logger__c(
        Appenders__c = String.join(ALL_APPENDERS, ','),
        Class_Names__c = LoggerTest.class.getName(),
        First_Caller_Override__c = true,
        Name = 'LoggerTest',
        Threshold__c = 'DEBUG'
      )
    };

    Test.startTest();

    Logger.Instance log = Logger.getInstance(LoggerTest.class);

    Soqler soql = new Soqler(Schema.Account.SObjectType);
    soql.fields().add(Schema.Account.Id);
    soql.queryToString();

    Test.stopTest();

    List<Logger.Entry> entries = log.pullEntries()
      .get(Logger.PlatformEventAppender.class.getName());

    System.assertEquals(1, entries.size());
    System.assert(((String) entries[0].v).contains('SELECT'));
  }

  @isTest
  static void none() {
    Logger.Instance log = Logger.getInstance(LoggerTest.class);

    System.assert(log.isLogging(System.LoggingLevel.NONE));
    System.assert(!log.isLogging(System.LoggingLevel.FINEST));
    System.assert(!log.isLogging(System.LoggingLevel.FINER));
    System.assert(!log.isLogging(System.LoggingLevel.FINE));
    System.assert(!log.isLogging(System.LoggingLevel.DEBUG));
    System.assert(!log.isLogging(System.LoggingLevel.INFO));
    System.assert(!log.isLogging(System.LoggingLevel.WARN));
    System.assert(!log.isLogging(System.LoggingLevel.ERROR));
  }

  @isTest
  static void pushPullAndFlush() {
    insert new Schema.Cs_Logger__c(
      Appenders__c = String.join(ALL_APPENDERS, ','),
      Class_Names__c = LoggerTest.class.getName(),
      Name = 'LoggerTest',
      Threshold__c = 'INFO'
    );

    Test.startTest();

    Logger.Instance log = Logger.getInstance(LoggerTest.class);

    log.info('Info');

    // Pulling info
    Map<String, List<Logger.Entry>> entries = log.pullEntries();
    System.assertEquals(1, entries.size());

    // Trying again, there's shouldn't be entries because they were cleared
    System.assertEquals(0, log.pullEntries().size(), JSON.serialize(log.pullEntries()));

    log.pushEntries(entries);

    System.assertEquals(0, System.Limits.getDmlRows());

    log.flush();

    Test.stopTest();

    System.assertEquals(1, System.Limits.getDmlRows());
  }

  @isTest
  static void user() {
    insert new Schema.Cs_Logger__c(
      Appenders__c = String.join(ALL_APPENDERS, ','),
      Class_Names__c = LoggerTest.class.getName(),
      Name = 'LoggerTest',
      Users__c = 'Anyone ButMe',
      Threshold__c = 'INFO'
    );

    Test.startTest();

    Logger.Instance log = Logger.getInstance(LoggerTest.class);

    log.finer('finer');
    log.fine('fine');
    log.info('Info');
    log.warn('Warn');

    Test.stopTest();

    System.assertEquals(0, log.pullEntries().size());
  }
  @isTest
  static void userAndLevels() {
    insert new Schema.Cs_Logger__c(
      Appenders__c = String.join(ALL_APPENDERS, ','),
      Class_Names__c = LoggerTest.class.getName(),
      Name = 'LoggerTest',
      Users__c = 'Anyone ButMe,' + UserInfo.getName(),
      Threshold__c = 'FINEST'
    );

    Test.startTest();

    Logger.Instance log = Logger.getInstance(LoggerTest.class);

    log.finest('Finest');
    log.finer('Finer');
    log.fine('Fine');
    log.debug('Debug');
    log.info('Info');
    log.warn('Warn');

    Test.stopTest();

    List<Logger.Entry> entries = log.pullEntries()
      .get(Logger.PlatformEventAppender.class.getName());

    System.assertEquals(6, entries.size());

    List<System.LoggingLevel> levels = new List<System.LoggingLevel>{
      System.LoggingLevel.FINEST,
      System.LoggingLevel.FINER,
      System.LoggingLevel.FINE,
      System.LoggingLevel.DEBUG,
      System.LoggingLevel.INFO,
      System.LoggingLevel.WARN
    };

    for (Integer i = 0; i < levels.size(); i++) {
      System.assertEquals(levels[i], entries[i].l);
    }
  }
}
