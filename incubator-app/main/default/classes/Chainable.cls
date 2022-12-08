/**
 * @description An object that enables the execution of <code>Batchable</code> or <code>Queueable</code>
 * in a predetermined sequence. Also by means of <code>Chainable</code> the following other benefits are achieved:
 *
 *   - No need to hardcode successor batch in finish() method
 *   - Sharing and passing of variables between chain members
 *
 * @since 1.1
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
public abstract class Chainable {
  /**
   * @description A shared wrapper object to hold either
   * <code>BatchableContext</code> or <code>QueueableContext</code>.
   *
   * @since 1.1
   */
  public class Context {
    private final Object context;

    /**
     * @description The parameterless constructor.
     *
     * @since 1.1
     */
    public Context() {
      context = null;
    }

    /**
     * @description The constructor for <code>Chainable</code> extending <code>Batchable</code>.
     *
     * @param value the context as received in the <code>Batchable.start()</code> method
     * @since 1.1
     */
    public Context(Database.BatchableContext value) {
      context = value;
    }

    /**
     * @description The constructor for <code>Chainable</code> extending <code>Queueable</code>.
     *
     * @param value the context as received in the <code>Queueable.execute()</code> method
     * @since 1.1
     */
    public Context(QueueableContext value) {
      context = value;
    }

    /**
     * @description The constructor for <code>Chainable</code> extending <code>Schedulable</code>.
     *
     * @param value the context as received in the <code>Queueable.execute()</code> method
     * @since 1.1
     */
    public Context(SchedulableContext value) {
      context = value;
    }

    /**
     * @description It returns the current <code>Batchable</code> or <code>Queueable</code>
     * underlying context.
     *
     * @return the context
     * @since 1.1
     */
    public Object get() {
      return context;
    }
  }

  private Chainable next;
  private Chainable previous;
  private Map<String, Object> variables;

  public Chainable() {
    variables = new Map<String, Object>();
  }

  /**
   * @description It aborts the execution of the next and any subsequent chain link.
   *
   * @since 1.1
   */
  public void abort() {
    next = null;
  }

  /**
   * @description It sets off the whole constructed chain.
   * Depending on the context the execution could be run asynchronously or synchronously:
   * when in test mode it will be synchronous, otherwise asynchronous.
   * <p>
   * Depending on the implementation class this method will eventually call:
   *
   *   - <code>Database.executeBatch</code> for <code>Batchable</code>
   *   - <code>System.enqueueJob</code> for <code>Queueable</code>
   *
   * @return this CHAINABLE instance
   * @since 1.1
   */
  public Chainable execute() {
    if (Test.isRunningTest()) {
      executeSynchronously(new Context());
      executeNext();
    } else {
      executeAsynchronously();
    }

    return this;
  }

  protected abstract void executeAsynchronously();

  protected void executeNext() {
    if (next != null) {
      next.execute();
    }
  }

  protected abstract void executeSynchronously(Context context);

  /**
   * @description It returns a previously set variable shared and accessible across all the
   * defined <code>Chainable</code> objects.
   *
   * @param key the variable name
   * @return the variable value
   * @see Chainable#setVariable(String, Object) setVariable
   * @since 1.1
   */
  public Object getVariable(String key) {
    return variables.get(key);
  }

  /**
   * @description It sets a variable that will be shared and accessible across all the
   * defined <code>Chainable</code> objects.
   *
   * @param key the variable name
   * @param value the variable value
   * @return this CHAINABLE instance
   * @see Chainable#getVariable(String) getVariable
   * @since 1.1
   */
  public Chainable setVariable(String key, Object value) {
    if (variables == null) {
      variables = new Map<String, Object>();
    }

    variables.put(key, value);

    return this;
  }

  /**
   * @description It appends a chainable to the current instance
   * that will be executed after the current one terminates.
   *
   * @param successor the next chainable that will be executed
   * @return this CHAINABLE instance
   * @since 1.1
   */
  public Chainable then(Chainable successor) {
    if (next != null) {
      next.then(successor);
    } else {
      next = successor;
      next.previous = this;
      next.variables = variables;
    }

    return this;
  }
}
