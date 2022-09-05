public inherited sharing class BatchableLink extends ChainableBatchableSObject implements Logger.AllowFlushes {
  private static final Logger.Instance LOG = Logger.getInstance(BatchableLink.class);

  private final String name;

  private Map<String, List<Logger.Entry>> logEntries;

  public BatchableLink(String name) {
    this.name = name;
  }

  public override Integer batchSize() {
    return 200;
  }

  public override void execute(Chainable.Context context, List<SObject> records) {
    LOG.pushEntries(logEntries);

    LOG.debug('execute() The record batch is ' + records.size());

    // Utils.sleep(5);

    logEntries = LOG.pullEntries();
  }

  public override void finish(Chainable.Context context) {
    LOG.pushEntries(logEntries);

    LOG.info('finish() finished link ' + name);

    LOG.flush();
  }

  public override Database.QueryLocator start(Chainable.Context context) {
    LOG.info('start() getting accounts');

    logEntries = LOG.pullEntries();

    return Database.getQueryLocator('SELECT Id FROM Account');
  }
}
