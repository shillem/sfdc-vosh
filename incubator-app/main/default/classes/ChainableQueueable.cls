/**
 * @description An abstract extension of <code>Chainable</code> for implementation of
 * <code>Database.Batchable&lt;Object&gt;</code>.
 *
 * @since 1.1
 */
public abstract class ChainableQueueable extends Chainable implements Database.AllowsCallouts, System.Queueable {
  /**
   * @description The method containing the logic.
   *
   * @param context the context wrapper for the <code>System.Queueable</code>
   * @since 1.1
   */
  protected abstract void execute(Chainable.Context context);

  public void execute(QueueableContext context) {
    execute(new Chainable.Context(context));

    executeNext();
  }

  protected override void executeAsynchronously() {
    System.enqueueJob(this);
  }

  protected override void executeSynchronously(Chainable.Context context) {
    execute(context);
  }
}
