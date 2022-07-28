/**
 * An implementation of <code>Database.Batchable&lt:SObject&gt;</code> for deleting
 * records en masse.
 *
 * @since 1.0.15
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class BatchableDeletable implements Database.Batchable<SObject> {
  private final Boolean emptyRecycleBin;
  private final String q;

  /**
   * It creates an instance taht will delete records returned by the specified query.
   *
   * @param q the query
   * @see #BatchableDeletable(String, Boolean)
   * @since 1.0.15
   */
  global BatchableDeletable(String q) {
    this(q, false);
  }

  /**
   * It creates an instance taht will delete records returned by the specified query.
   *
   * @param q the query
   * @param emptyRecycleBin the option for emptying the recycle bin after deletion
   * @see #BatchableDeletable(String)
   * @since 1.0.15
   */
  global BatchableDeletable(String q, Boolean emptyRecycleBin) {
    Utils.requireNonNull(q, 'Query cannot be null');
    Utils.requireNonNull(emptyRecycleBin, 'Empty recycle bin option cannot be null');

    this.q = q;
    this.emptyRecycleBin = emptyRecycleBin;
  }

  global void execute(Database.BatchableContext context, List<SObject> records) {
    delete records;

    if (emptyRecycleBin) {
      Database.emptyRecycleBin(records);
    }
  }

  @SuppressWarnings('PMD.EmptyStatementBlock')
  global void finish(Database.BatchableContext context) {
  }

  global Database.QueryLocator start(Database.BatchableContext context) {
    return Database.getQueryLocator(q);
  }
}
