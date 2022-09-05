public inherited sharing class QueueableLink extends ChainableQueueable implements Logger.AllowFlushes {
  private static final Logger.Instance LOG = Logger.getInstance(QueueableLink.class);

  private final String name;

  public QueueableLink(String name) {
    this.name = name;
  }

  public override void execute(Chainable.Context context) {
    LOG.info('executeInner() executing ' + name);
    
    final Soqler soql = new Soqler(Schema.Account.SObjectType);
    soql.fields().add(Schema.Account.Id);
    soql.setMaxCount(1);
    soql.queryToString();

    LOG.flush();
  }
}
