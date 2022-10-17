/**
 * @description An abstract extension of <code>Chainable</code> for implementation of
 * <code>System.Schedulable</code>.
 *
 * @since 1.1
 */
public abstract class ChainableSchedulable extends Chainable implements Database.AllowsCallouts, System.Schedulable {
  protected abstract String cronExpression();

  /**
   * @description The method containing the logic.
   *
   * @param context the context wrapper for the <code>System.Schedulable</code>
   * @since 1.1
   */
  protected abstract void execute(Chainable.Context context);

  public void execute(SchedulableContext context) {
    execute(new Chainable.Context(context));

    executeNext();
  }

  protected override void executeAsynchronously() {
    System.schedule(name(), cronExpression(), this);
  }

  protected override void executeSynchronously(Chainable.Context context) {
    execute(context);
  }

  protected abstract String name();
}
