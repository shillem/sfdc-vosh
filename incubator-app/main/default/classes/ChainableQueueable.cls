/**
 * @description An abstract extension of <code>Chainable</code> for implementation of
 * <code>System.Queueable</code>.
 *
 * @since 1.1
 */
public abstract class ChainableQueueable extends Chainable implements Database.AllowsCallouts, System.Queueable {
  private transient AsyncOptions options;

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
    if (options != null) {
      System.enqueueJob(this, options);
    } else {
      System.enqueueJob(this);
    }
  }

  protected override void executeSynchronously(Chainable.Context context) {
    execute(context);
  }

  protected AsyncOptions getOptions() {
    if (options == null) {
      options = new AsyncOptions();
    }

    return options;
  }
}
