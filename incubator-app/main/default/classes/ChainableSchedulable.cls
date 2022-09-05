public abstract class ChainableSchedulable extends Chainable implements Database.AllowsCallouts, Schedulable {
  protected abstract void execute(Context context);

  public void execute(SchedulableContext context) {
    execute(new Context(context));

    executeNext();
  }

  public override void executeAsynchronously() {
    System.schedule(name(), cronExpression(), this);
  }

  public override void executeSynchronously(Context context) {
    execute(context);
  }

  public virtual String cronExpression() {
    Datetime dt = Datetime.now().addMinutes(1);
    return dt.second() + ' ' + dt.minute() + ' ' + dt.hour() + ' * * ?';
  }

  public virtual String name() {
    // Note: This class name
    return String.valueOf(this).substring(0, String.valueOf(this).indexOf(':'));
  }
}
