/**
 * @description A utility class that provides flexible logging capabilities for any code or application.
 * <p>
 * The class depends on <code>Cs_Logger__c</code> custom setting records to determine its behavior.
 * It can also publish <code>Pe_Logger__c</code> platform events and offer a way to subscribe to the logging generated.
 * <p>
 * The <code>Logger</code> will load its configuration as soon as the first <code>Logger.getInstance()</code> call is invoked.
 * The <code>Logger</code> will log as long as there's one valid <code>Appender</code> defined.
 * Multiple appenders can be defined and each one will receive the information subject to logging.
 * <p>
 * The custom setting records provide ample ways of configuring the logging. For example:
 *
 *   - all classes should be logged
 *   - all classes under a specific namespace should be logged
 *   - only specific classes should be logged
 *   - only code executions of specific users should be logged
 *   - one or more appenders will be invoked if classes/users are allowed to log
 *   - only a specific logging level or higher should be logged
 *
 * @since 1.1
 */
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.CyclomaticComplexity, PMD.StdCyclomaticComplexity')
global inherited sharing class Logger {
  /**
   * @description A marker interface to be implemented in any class entitled to call <code>Logger.Instance.flush()</code>.
   * If such marker interface is not implemented the <code>flush()</code> method won't do anything.
   * <p>
   * This mechanism is necessary to avoid any classes from arbitrary triggering a flushable appender
   * and breaking up the logger entry list into many separate transactions.
   *
   * @since 1.1
   */
  global interface AllowFlushes {
  }

  /**
   * @description The basic interface to implement to build an appender that can be used by the <code>Logger</code>.
   *
   * @since 1.1
   */
  global interface Appender {
    /**
     * @description It receives the information to be logged and consumes it.
     *
     * @param name the class name logging the information
     * @param threshold the logging level associated with the information
     * @param value the information to be logged
     * @since 1.1
     */
    void append(String name, System.LoggingLevel threshold, Object value);
  }

  /**
   * @description An extension to the basic interface <code>Appender</code>.
   * Its purpose is to temporarily store logged information rather than consuming it immediately.
   * All the logging entries will be released at once when <code>flush()</code> is invoked.
   *
   * @see Logger.Appender
   * @since 1.1
   */
  global interface AppenderFlushable extends Appender {
    /**
     * @description It processes all the queued entries and it afterward drops them.
     *
     * @since 1.1
     */
    void flush();

    /**
     * @description It pulls the currently queued entries
     * by returning a copy of the list and clearing the internal one.
     * <p>
     * This method is invoked by a <code>Logger.Instance</code>.
     *
     * @see Logger.AppenderFlushable#push() push
     * @see Logger.Instance#pullEntries() pullEntries
     * @since 1.1
     */
    List<Entry> pull();

    /**
     * @description It pushes the passed entries.
     * <p>
     * This method is invoked by a <code>Logger.Instance</code>.
     *
     * @see Logger.AppenderFlushable#pull() pull
     * @see Logger.Instance#pushEntries() pushEntries
     * @since 1.1
     */
    void push(List<Entry> pulled);
  }

  /**
   * @description Concrete implementation of the <code>Appender</code> interface.
   * This implementation is a wrapper for the <code>System.debug</code> method.
   *
   * @since 1.1
   */
  global class ConsoleAppender implements Appender {
    /**
     * @description It receives the information to be logged and consumes it.
     *
     * @see Appender#append(String, System.LoggingLevel, Object) append
     * @since 1.1
     */
    global void append(String name, System.LoggingLevel level, Object value) {
      if (value instanceof System.Exception) {
        System.Exception e = (System.Exception) value;

        System.debug(System.LoggingLevel.ERROR, e.getMessage() + '\n' + e.getStackTraceString());
      } else {
        System.debug(level, value);
      }
    }
  }

  /**
   * @description Concrete implementation of the <code>Appender</code> interface.
   * This implementation is a wrapper for the <code>System.debug</code> method.
   *
   * @since 1.1
   */
  global abstract class MessageAppender implements AppenderFlushable {
    protected final List<Entry> entries;

    protected Integer discarded;

    /**
     * @description The parameterless constructor
     * @since 1.1
     */
    global MessageAppender() {
      entries = new List<Entry>();
      discarded = 0;
    }

    /**
     * @description It receives the information to be logged and consumes it.
     *
     * @see Appender#append(String, System.LoggingLevel, Object) append
     * @since 1.1
     */
    global void append(String name, System.LoggingLevel level, Object value) {
      // Preventing hitting limits
      if (entries.size() > 199) {
        entries.remove(0);

        discarded++;
      }

      if (value instanceof System.Exception) {
        System.Exception e = (System.Exception) value;

        entries.add(new Entry(name, level, e.getMessage() + '\n' + e.getStackTraceString()));
      } else {
        entries.add(new Entry(name, level, value));
      }
    }

    /**
     * @description It processes all the queued entries and it afterward drops them.
     *
     * @see AppenderFlushable#flush() flush
     * @since 1.1
     */
    global virtual void flush() {
      entries.clear();
    }

    /**
     * @description It pulls the currently queued entries
     * by returning a copy of the list and clearing the internal one.
     *
     * @see AppenderFlushable#pull() pull
     * @since 1.1
     */
    global List<Entry> pull() {
      List<Entry> pulled = new List<Entry>(entries);

      entries.clear();

      return pulled;
    }

    /**
     * @description It pushes the passed entries.
     *
     * @see AppenderFlushable#push(List<Entry>) push
     * @since 1.1
     */
    global void push(List<Entry> pulled) {
      entries.addAll(pulled);
    }
  }

  /**
   * @description Extending class for <code>MessageAppender</code>.
   * This implementation publishes as a platform event the queued entries
   * when the <code>flush</code> method is invoked.
   *
   * @see Logger.MessageAppender
   * @since 1.1
   */
  global class PlatformEventAppender extends MessageAppender {
    /**
     * @description It processes all the queued entries and it afterward drops them.
     *
     * @see Appender#flush() flush
     * @since 1.1
     */
    global override void flush() {
      if (!entries.isEmpty()) {
        final Map<String, Object> payload = new Map<String, Object>{
          'count' => entries.size(),
          'entries' => entries
        };

        if (discarded > 0) {
          payload.put('discarded', discarded);
        }

        EventBus.publish(new Pe_Logger__e(Payload__c = JSON.serialize(payload)));
      }

      super.flush();
    }
  }

  /**
   * @description The object detailing the information to be logged.
   *
   * @see Logger.Instance#log(System.LoggingLevel, Object) log
   * @since 1.1
   */
  @JsonAccess(serializable='always' deserializable='always')
  global class Entry {
    global final System.LoggingLevel l;
    global final String n;
    global final Datetime t;
    global final Object v;

    private Entry(String n, System.LoggingLevel l, Object v) {
      this.l = l;
      this.n = n;
      this.t = System.now();
      this.v = v;
    }
  }

  /**
   * @description The main object that any other class will use to access the <code>Logger</code>.
   * To create an instance the static method must be called by passing the calling class <code>System.Type</code>.
   * Only one instance for each calling class will be created.
   *
   * @see Logger#getInstance(System.Type) getInstance
   * @since 1.1
   */
  global class Instance {
    private final System.Type t;
    private final String name;

    private Profile p;
    private System.LoggingLevel threshold;

    private Instance(System.Type t) {
      this.t = t;
      this.name = t.getName();
    }

    private void checkAllowFlushes(String operation) {
      if (!AllowFlushes.class.isAssignableFrom(t)) {
        throw new UnsupportedOperationException(
          name +
          ' is not entitled to ' +
          operation +
          ' entries since it is not implementing ' +
          AllowFlushes.class.getName()
        );
      }
    }

    /**
     * @description The method to log information at the <code>DEBUG</code> level.
     * If the detected threshold is above this level the information won't be processed.
     *
     * @param value the information to be logged
     * @see Logger.Instance#log(System.LoggingLevel, Object) log
     * @since 1.1
     */
    global void debug(Object value) {
      log(System.LoggingLevel.DEBUG, value);
    }

    /**
     * @description The method to log information at the <code>ERROR</code> level.
     * If the detected threshold is above this level the information won't be processed.
     *
     * @param value the information to be logged
     * @see Logger.Instance#log(System.LoggingLevel, Object) log
     * @since 1.1
     */
    global void error(Object value) {
      log(System.LoggingLevel.ERROR, value);
    }

    /**
     * @description The method to log information at the <code>FINE</code> level.
     * If the detected threshold is above this level the information won't be processed.
     *
     * @param value the information to be logged
     * @see Logger.Instance#log(System.LoggingLevel, Object) log
     * @since 1.1
     */
    global void fine(Object value) {
      log(System.LoggingLevel.FINE, value);
    }

    /**
     * @description The method to log information at the <code>FINER</code> level.
     * If the detected threshold is above this level the information won't be processed.
     *
     * @param value the information to be logged
     * @see Logger.Instance#log(System.LoggingLevel, Object) log
     * @since 1.1
     */
    global void finer(Object value) {
      log(System.LoggingLevel.FINER, value);
    }

    /**
     * @description The method to log information at the <code>FINEST</code> level.
     * If the detected threshold is above this level the information won't be processed.
     *
     * @param value the information to be logged
     * @see Logger.Instance#log(System.LoggingLevel, Object) log
     * @since 1.1
     */
    global void finest(Object value) {
      log(System.LoggingLevel.FINEST, value);
    }

    /**
     * @description It processes all the queued entries and it afterward drops them.
     *
     * @see Appender#flush() flush
     * @since 1.1
     */
    global void flush() {
      checkAllowFlushes('flush');

      final Profile p = getSingleton().getProfile(name);

      if (p != null) {
        for (Appender a : singleton.appenders.values()) {
          if (a instanceof AppenderFlushable) {
            ((AppenderFlushable) a).flush();
          }
        }
      }
    }

    private Profile getProfile() {
      if (p == null) {
        p = getSingleton().getProfile(name);
      }

      return p;
    }

    /**
     * @description The method to log information at the <code>INFO</code> level.
     * If the detected threshold is above this level the information won't be processed.
     *
     * @param value the information to be logged
     * @see Logger.Instance#log(System.LoggingLevel, Object) log
     * @since 1.1
     */
    global void info(Object value) {
      log(System.LoggingLevel.INFO, value);
    }

    /**
     * @description The method to log information at the <code>INFO</code> level.
     * If the detected threshold is above this level the information won't be processed.
     *
     * @param value the logging level
     * @return true if the logging level passed is processed by the current threshold
     * @since 1.1
     */
    global Boolean isLogging(System.LoggingLevel value) {
      Utils.requireNonNull(value, 'Level cannot be null');

      if (value == System.LoggingLevel.NONE) {
        return true;
      }

      final Profile p = getProfile();

      if (!p.us.isEmpty() && !p.us.contains(UserInfo.getName())) {
        return false;
      }

      final System.LoggingLevel threshold = this.threshold != null ? this.threshold : p.th;

      return threshold != System.LoggingLevel.NONE && value.ordinal() >= threshold.ordinal();
    }

    /**
     * @description The method to log information.
     * If the detected threshold is above this level the information won't be processed.
     *
     * @param level the logging level
     * @param value the information to be logged
     * @since 1.1
     */
    global void log(System.LoggingLevel level, Object value) {
      Utils.requireNonNull(level, 'Level cannot be null');

      if (!isLogging(level)) {
        return;
      }

      for (String a : getProfile().ap) {
        final Appender app = singleton.appenders.get(a);

        if (app != null) {
          app.append(name, level, value);
        }
      }
    }

    /**
     * @description It pulls the currently queued entries by all the instatiated appenders
     * and returning a map with a copy of the entry list for each appender.
     *
     * @return the map of entries by <code>Appender</code> class name
     * @see Logger.AppenderFlushable#flush() flush
     * @see Logger.Instance#pushEntries() pushEntries
     * @since 1.1
     */
    global Map<String, List<Entry>> pullEntries() {
      checkAllowFlushes('pull');

      final Map<String, List<Entry>> entries = new Map<String, List<Entry>>();

      for (String name : getSingleton().appenders.keySet()) {
        final Appender a = singleton.appenders.get(name);

        if (a instanceof AppenderFlushable) {
          final List<Entry> afe = ((AppenderFlushable) a).pull();

          if (!afe.isEmpty()) {
            entries.put(name, afe);
          }
        }
      }

      return entries;
    }

    /**
     * @description It pushes/restores the previously pulled entries to the appenders' singleton instances.
     *
     * @param entries the logging entries to restore
     * @see Logger.AppenderFlushable#flush() flush
     * @see Logger.Instance#pullEntries() pullEntries
     * @since 1.1
     */
    global void pushEntries(Map<String, List<Entry>> entries) {
      checkAllowFlushes('push');

      getSingleton();

      for (String name : entries.keySet()) {
        final Appender a = singleton.appenders.get(name);

        if (a instanceof AppenderFlushable) {
          ((AppenderFlushable) a).push(entries.get(name));
        }
      }

      entries.clear();
    }

    /**
     * @description The method to log information at the <code>WARN</code> level.
     * If the detected threshold is above this level the information won't be processed.
     *
     * @param value the logging level
     * @return true if the logging level passed is processed by the current threshold
     * @since 1.1
     */
    global void warn(Object value) {
      log(System.LoggingLevel.WARN, value);
    }
  }

  private class Profile {
    private final List<String> ap;
    private final List<String> cl;
    private final List<String> ns;
    private final List<String> us;
    private final System.LoggingLevel th;

    private Profile(Schema.Cs_Logger__c record) {
      ap = treat(record.Appenders__c);
      cl = treat(record.Class_Names__c);
      ns = treat(record.Namespaces__c);
      us = treat(record.Users__c);
      th = System.LoggingLevel.valueOf(record.Threshold__c);
    }

    private List<String> treat(String value) {
      final List<String> values = new List<String>();

      if (String.isNotEmpty(value)) {
        for (String v : value.split(',')) {
          values.add(v.trim());
        }
      }

      return values;
    }
  }

  private static final Profile PROFILE_NULL = new Profile(
    new Schema.Cs_Logger__c(Threshold__c = 'NONE')
  );

  private static Map<System.Type, Instance> instances;
  private static Logger singleton;

  private final Map<String, Appender> appenders;
  private final Map<String, Profile> profiles;

  private Logger() {
    appenders = new Map<String, Appender>();
    profiles = new Map<String, Profile>();
  }

  private Profile getProfile(String name) {
    Profile p = profiles.get(name);

    if (p != null) {
      return p;
    }

    if (name.contains('.')) {
      p = profiles.get(name.substringBefore('.') + '.*');
    }

    if (p != null) {
      return p;
    }

    p = profiles.get('*');

    if (p != null) {
      return p;
    }

    return PROFILE_NULL;
  }

  /**
   * @description It returns the <code>Logger.Instance</code> singleton instance
   * that will be used by the class to call the logging methods.
   *
   * @param t the class calling the instance
   * @return the <code>Logger.Instance</code> for the class passed
   * @since 1.1
   */
  global static Instance getInstance(System.Type t) {
    Utils.requireNonNull(t, 'Type cannot be null');

    if (instances == null) {
      instances = new Map<System.Type, Instance>();
    }

    Instance inst = instances.get(t);

    if (inst == null) {
      inst = new Instance(t);

      instances.put(t, inst);
    }

    return inst;
  }

  private static Logger getSingleton() {
    if (singleton == null) {
      singleton = new Logger();

      for (Schema.Cs_Logger__c record : Schema.Cs_Logger__c.getAll().values()) {
        if (record.Is_Disabled__c) {
          continue;
        }

        final Profile p = new Profile(record);

        // Profiles by namespace
        for (String n : p.ns) {
          if (!singleton.profiles.containsKey(n + '.*')) {
            singleton.profiles.put(n + '.*', p);
          }
        }

        // Profiles by class name
        for (String c : p.cl) {
          if (!singleton.profiles.containsKey(c)) {
            singleton.profiles.put(c, p);
          }
        }

        // Catch-all profile
        if (p.ns.isEmpty() && p.cl.isEmpty()) {
          singleton.profiles.put('*', p);
        }

        // Appenders
        for (String a : p.ap) {
          if (!singleton.appenders.containsKey(a)) {
            singleton.appenders.put(a, (Appender) System.Type.forName(a).newInstance());
          }
        }
      }
    }

    return singleton;
  }
}
