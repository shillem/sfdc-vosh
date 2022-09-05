/**
 * @description An abstract extension of <code>Chainable</code> for implementation of
 * <code>Database.Batchable&lt;SObject&gt;</code>.
 *
 * @since 1.1
 */
public abstract class ChainableBatchableSObject extends Chainable implements Database.AllowsCallouts, Database.Batchable<SObject>, Database.Stateful {
  /**
   * @description The arbitrary value of the batch size.
   *
   * @return the batch size
   * @since 1.1
   */
  public abstract Integer batchSize();

  /**
   * @description The method containing the logic.
   *
   * @param context the context wrapper for the <code>Database.Batchable</code>
   * @param scope the batch to be processed
   * @since 1.1
   */
  public abstract void execute(Chainable.Context context, List<SObject> scope);

  public void execute(Database.BatchableContext context, List<SObject> scope) {
    execute(new Chainable.Context(context), scope);
  }

  protected override void executeAsynchronously() {
    Database.executeBatch(this, batchSize());
  }

  protected override void executeSynchronously(Chainable.Context context) {
    List<SObject> fullScope = Database.query(start(context).getQuery());

    if (!fullScope.isEmpty()) {
      execute(context, fullScope);
    }

    finish(context);
  }

  /**
   * @description The method invoked after all the batches have been processed.
   *
   * @param context the context wrapper for the <code>Database.Batchable</code>
   * @since 1.1
   */
  public abstract void finish(Chainable.Context context);

  public void finish(Database.BatchableContext context) {
    finish(new Chainable.Context(context));

    executeNext();
  }

  /**
   * @description The method invoked to start the <code>Database.Batchable</code> off.
   *
   * @param context the context wrapper for the <code>Database.Batchable</code>
   * @return the iterable used by the framework to prepare the batches
   * @since 1.1
   */
  public abstract Database.QueryLocator start(Chainable.Context context);

  public Database.QueryLocator start(Database.BatchableContext context) {
    return start(new Chainable.Context(context));
  }
}
