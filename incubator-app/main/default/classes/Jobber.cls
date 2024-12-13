public without sharing class Jobber {
  private static final Logger.Instance LOG = Logger.getInstance(Jobber.class);

  public class Instance {
    public String className { get; private set; }
    public InstanceCron cron { get; private set; }
    public Id jobId { get; private set; }
    public String name { get; private set; }
    public String state { get; private set; }
    public Boolean userActive { get; private set; }
    public String userId { get; private set; }
    public String userName { get; private set; }

    public Boolean abort() {
      try {
        if (isActive()) {
          System.abortJob(hasCron() ? cron.jobId : jobId);

          return true;
        }
      } catch (System.Exception e) {
        LOG.warn('abort() ' + e.getMessage());
      }

      return false;
    }

    public Boolean hasCron() {
      return cron != null;
    }

    public Boolean isActive() {
      if (!hasCron() && STATUSES_ACTIVE.contains(state)) {
        return true;
      }

      if (hasCron() && cron.isActive()) {
        return true;
      }

      return false;
    }

    public Boolean isZombie() {
      return hasCron() && !cron.isValid();
    }
  }

  public class InstanceCron {
    public Id jobId { get; private set; }
    public String name { get; private set; }
    public Datetime nextFireTime { get; private set; }
    public Datetime previousFireTime { get; private set; }
    public String state { get; private set; }
    public Boolean userActive { get; private set; }
    public String userId { get; private set; }
    public String userName { get; private set; }

    public Boolean isActive() {
      return isValid() && STATUSES_CRON_ACTIVE.contains(state);
    }

    public Boolean isValid() {
      return state != null;
    }
  }

  public abstract class Snapshot {
    private final List<Instance> values;

    public Snapshot() {
      values = new List<Instance>();
    }

    public SchedulingStatus abortAll() {
      SchedulingStatus status = SchedulingStatus.DISABLED_ALREADY;

      for (Instance r : values) {
        if (r.abort()) {
          status = SchedulingStatus.DISABLED;
        }
      }

      return status;
    }

    protected virtual Instance add(Schema.AsyncApexJob j) {
      final Instance instance = new Instance();

      instance.className = j.ApexClass.Name;
      instance.jobId = j.Id;
      instance.state = j.Status;
      instance.userActive = j.CreatedBy?.IsActive;
      instance.userId = j.CreatedBy?.Id;
      instance.userName = j.CreatedBy?.Name;

      if (j.CronTrigger != null) {
        instance.cron = new InstanceCron();

        instance.cron.jobId = j.CronTrigger.Id;
        instance.cron.name = j.CronTrigger.CronJobDetail?.Name;
        instance.cron.nextFireTime = j.CronTrigger.NextFireTime;
        instance.cron.previousFireTime = j.CronTrigger.PreviousFireTime;
        instance.cron.state = j.CronTrigger.State;
        instance.cron.userActive = j.CronTrigger.CreatedBy?.IsActive;
        instance.cron.userId = j.CronTrigger.CreatedBy?.Id;
        instance.cron.userName = j.CronTrigger.CreatedBy?.Name;
      } else if (j.CronTriggerId != null) {
        LOG.warn('add() CronTriggerId is not null but CronTrigger is');

        instance.cron = new InstanceCron();
        instance.cron.jobId = j.CronTriggerId;
      }

      values.add(instance);

      return instance;
    }

    public List<Instance> getAll() {
      return new List<Instance>(values);
    }

    public List<Instance> getCrons() {
      final List<Instance> filtered = new List<Instance>();

      for (Instance r : values) {
        if (r.hasCron()) {
          filtered.add(r);
        }
      }

      return filtered;
    }

    public Boolean isActive() {
      for (Instance r : values) {
        if (r.isActive()) {
          return true;
        }
      }

      return false;
    }
  }

  public enum SchedulingStatus {
    DISABLED,
    DISABLED_ALREADY,
    ENABLED,
    ENABLED_ALREADY
  }

  private static final List<String> STATUSES_ACTIVE = new List<String>{
    'Holding',
    'Preparing',
    'Processing',
    'Queued'
  };
  private static final List<String> STATUSES_CRON_ACTIVE = new List<String>{
    'ACQUIRED',
    'BLOCKED',
    'EXECUTING',
    'PAUSED',
    'PAUSED_BLOCKED',
    'WAITING'
  };

  private static SchedulingStatus abort(List<Schema.AsyncApexJob> jobs) {
    SchedulingStatus status = SchedulingStatus.DISABLED_ALREADY;

    for (Schema.AsyncApexJob j : jobs) {
      System.abortJob(j.CronTrigger != null ? j.CronTrigger.Id : j.Id);

      status = SchedulingStatus.DISABLED;
    }

    return status;
  }

  public static SchedulingStatus abortByClasses(List<System.Type> apexClasses) {
    return abort(getActiveByClasses(apexClasses));
  }

  public static SchedulingStatus abortByCronName(String name) {
    return abort(getByCronName(name));
  }

  public static SchedulingStatus abortByNamespaces(List<String> namespaces) {
    return abort(getActiveByNamespaces(namespaces));
  }

  public static SchedulingStatus enlist(
    String jobName,
    String cronExpression,
    System.Schedulable sched
  ) {
    Utils.requireNonNull(jobName, 'Job name cannot be null');
    Utils.requireNonNull(cronExpression, 'Cron expression cannot be null');
    Utils.requireNonNull(sched, 'Schedulable cannot be null');

    try {
      final String jobIdentifier = System.schedule(jobName, cronExpression, sched);

      if (Id.valueOf(jobIdentifier).getSObjectType() != Schema.CronTrigger.SObjectType) {
        throw new System.UnexpectedException('Unable to schedule job ' + jobName);
      }

      return SchedulingStatus.ENABLED;
    } catch (System.AsyncException e) {
      return SchedulingStatus.ENABLED_ALREADY;
    }
  }

  public static List<Schema.AsyncApexJob> getActiveByClasses(List<System.Type> classes) {
    return getByClasses(classes, true);
  }

  public static List<Schema.AsyncApexJob> getActiveByNamespaces(List<String> namespaces) {
    if (namespaces == null || namespaces.isEmpty()) {
      throw new IllegalArgumentException('Namespaces cannot be null or empty');
    }

    final Soqler soql = getSoqler(true);

    soql.wheres()
      .addAnd(
        new Soqler.IWhereName('ApexClass', Schema.ApexClass.NamespacePrefix, 'IN', namespaces)
      );

    return soql.query();
  }

  public static List<Schema.AsyncApexJob> getByCronName(String name) {
    if (String.isEmpty(name)) {
      throw new IllegalArgumentException('Name cannot be null or empty');
    }

    final Soqler soql = getSoqler(false);

    soql.wheres()
      .addAnd(
        new Soqler.IWhereName(
          'CronTrigger.CronJobDetail',
          Schema.CronJobDetail.Name,
          name.contains('%') ? 'LIKE' : '=',
          name
        )
      );

    return soql.query();
  }

  public static List<Schema.AsyncApexJob> getByClasses(List<System.Type> classes) {
    return getByClasses(classes, false);
  }

  private static List<Schema.AsyncApexJob> getByClasses(
    List<System.Type> classes,
    Boolean filterActiveStatuses
  ) {
    if (classes == null || classes.isEmpty()) {
      throw new IllegalArgumentException('Classes cannot be null or empty');
    }

    final Soqler soql = getSoqler(filterActiveStatuses);

    final Map<String, List<String>> breakdown = new Map<String, List<String>>();

    for (System.Type t : classes) {
      final String[] n = t.getName().split('\\.');
      final String namespace;
      final String className;

      if (n.size() > 1) {
        namespace = n[0];
        className = n[1];
      } else {
        namespace = '';
        className = n[0];
      }

      final List<String> classNames = breakdown.get(namespace);

      if (classNames == null) {
        classNames = new List<String>();
        breakdown.put(namespace, classNames);
      }

      classNames.add(className);
    }

    final Soqler.IWhereGroup classesGroup = new Soqler.IWhereGroup();

    for (String namespace : breakdown.keySet()) {
      final Soqler.IWhereGroup classGroup = new Soqler.IWhereGroup();

      classGroup.wheres()
        .addAnd(
          new Soqler.IWhereName('ApexClass', Schema.ApexClass.NamespacePrefix, '=', namespace)
        )
        .addAnd(
          new Soqler.IWhereName('ApexClass', Schema.ApexClass.Name, 'IN', breakdown.get(namespace))
        );

      classesGroup.wheres().addOr(classGroup);
    }

    soql.wheres().addAnd(classesGroup);

    return soql.query();
  }

  public static List<Schema.AsyncApexJob> getByIds(Set<Id> jobIds) {
    if (jobIds == null || jobIds.isEmpty()) {
      throw new IllegalArgumentException('Job Ids cannot be null or empty');
    }

    final Soqler soql = getSoqler(false);

    soql.wheres().addAnd(new Soqler.IWhereName(Schema.AsyncApexJob.Id, 'IN', soql.bind(jobIds)));

    return soql.query();
  }

  private static Soqler getSoqler(Boolean filterActiveStatuses) {
    final Soqler soql = new Soqler(Schema.AsyncApexJob.SObjectType);

    soql.fields()
      .add(new Soqler.IFieldName('ApexClass', Schema.ApexClass.Name))
      .add(new Soqler.IFieldName('CreatedBy', Schema.User.IsActive))
      .add(new Soqler.IFieldName('CreatedBy', Schema.User.Name))
      .add(new Soqler.IFieldName('CronTrigger', Schema.CronTrigger.NextFireTime))
      .add(new Soqler.IFieldName('CronTrigger', Schema.CronTrigger.PreviousFireTime))
      .add(new Soqler.IFieldName('CronTrigger', Schema.CronTrigger.State))
      .add(new Soqler.IFieldName('CronTrigger.CreatedBy', Schema.User.IsActive))
      .add(new Soqler.IFieldName('CronTrigger.CreatedBy', Schema.User.Name))
      .add(new Soqler.IFieldName('CronTrigger.CronJobDetail', Schema.CronJobDetail.Name))
      .add(new Soqler.IFieldName('CronTrigger.CronJobDetail', Schema.CronJobDetail.JobType))
      .add(Schema.AsyncApexJob.ExtendedStatus)
      .add(Schema.AsyncApexJob.JobItemsProcessed)
      .add(Schema.AsyncApexJob.JobType)
      .add(Schema.AsyncApexJob.NumberOfErrors)
      .add(Schema.AsyncApexJob.TotalJobItems)
      .add(Schema.AsyncApexJob.Status);

    if (filterActiveStatuses) {
      final Soqler.IWhereGroup grp = new Soqler.IWhereGroup();

      grp.wheres()
        .addOr(new Soqler.IWhereName(Schema.AsyncApexJob.Status, 'IN', soql.bind(STATUSES_ACTIVE)))
        .addOr(
          new Soqler.IWhereName(
            'CronTrigger',
            Schema.CronTrigger.State,
            'IN',
            soql.bind(STATUSES_CRON_ACTIVE)
          )
        );

      soql.wheres().addAnd(grp);
    }

    soql.orders()
      .add(
        new Soqler.IOrderName(
          Schema.AsyncApexJob.CreatedDate,
          Soqler.OrderType.DESCENDING_NULLS_LAST
        )
      )
      .add(
        new Soqler.IOrderName(
          'CronTrigger',
          Schema.CronTrigger.CreatedDate,
          Soqler.OrderType.DESCENDING_NULLS_LAST
        )
      );

    return soql;
  }
}
