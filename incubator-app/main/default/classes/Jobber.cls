public inherited sharing class Jobber {
  public enum SchedulingStatus {
    DISABLED,
    DISABLED_ALREADY,
    ENABLED,
    ENABLED_ALREADY
  }

  private static final List<String> ASYNC_ACTIVE_STATUSES = new List<String>{
    'Holding',
    'Preparing',
    'Processing',
    'Queued'
  };
  private static final List<String> ASYNC_TYPES = new List<String>{
    'BatchApex',
    'BatchApexWorker',
    'Queueable',
    'ScheduledApex'
  };
  private static final List<String> SCHEDULED_ACTIVE_STATUSES = new List<String>{
    'ACQUIRED',
    'BLOCKED',
    'EXECUTING',
    'PAUSED',
    'PAUSED_BLOCKED',
    'WAITING'
  };

  public static SchedulingStatus disableAsync(List<System.Type> apexClasses) {
    List<Schema.AsyncApexJob> jobs = getAsyncActive(apexClasses);

    if (jobs.isEmpty()) {
      return SchedulingStatus.DISABLED_ALREADY;
    }

    for (Schema.AsyncApexJob j : jobs) {
      System.abortJob(j.Id);
    }

    return SchedulingStatus.DISABLED;
  }

  public static SchedulingStatus disableScheduled(String jobName) {
    List<Schema.CronTrigger> jobs = getScheduledActive(jobName);

    if (jobs.isEmpty()) {
      return SchedulingStatus.DISABLED_ALREADY;
    }

    for (Schema.CronTrigger j : jobs) {
      System.abortJob(j.Id);
    }

    return SchedulingStatus.DISABLED;
  }

  public static SchedulingStatus enableScheduled(
    String jobName,
    String cronExpression,
    Schedulable sched
  ) {
    Utils.requireNonNull(jobName, 'Job name cannot be null');
    Utils.requireNonNull(cronExpression, 'Cron expression cannot be null');
    Utils.requireNonNull(sched, 'Schedulable cannot be null');

    List<Schema.CronTrigger> jobs = getScheduledActive(jobName);

    if (!jobs.isEmpty()) {
      return SchedulingStatus.ENABLED_ALREADY;
    }

    String jobIdentifier = System.schedule(jobName, cronExpression, sched);

    if (Id.valueOf(jobIdentifier).getSObjectType() != Schema.CronTrigger.SObjectType) {
      throw new System.UnexpectedException('Unable to schedule job ' + jobName);
    }

    return SchedulingStatus.ENABLED;
  }

  public static List<Schema.AsyncApexJob> getAsync(
    List<System.Type> apexClasses,
    List<String> statuses
  ) {
    return getAsync(apexClasses, statuses, ASYNC_TYPES);
  }

  public static List<Schema.AsyncApexJob> getAsync(
    List<System.Type> apexClasses,
    List<String> statuses,
    List<String> types
  ) {
    Utils.requireNonNull(apexClasses, 'Classes cannot be null');

    Soqler query = new Soqler(Schema.AsyncApexJob.SObjectType);

    query.fields()
      .add(Schema.AsyncApexJob.CronTriggerId)
      .add(Schema.AsyncApexJob.JobItemsProcessed)
      .add(Schema.AsyncApexJob.JobType)
      .add(Schema.AsyncApexJob.NumberOfErrors)
      .add(Schema.AsyncApexJob.TotalJobItems)
      .add(Schema.AsyncApexJob.Status);

    if (statuses != null && !statuses.isEmpty()) {
      query.wheres().addAnd(new Soqler.IWhereName(Schema.AsyncApexJob.Status, 'IN', statuses));
    }

    if (types != null && !types.isEmpty()) {
      query.wheres().addAnd(new Soqler.IWhereName(Schema.AsyncApexJob.JobType, 'IN', types));
    }

    final Soqler.IWhereGroup classesGroup = new Soqler.IWhereGroup();

    for (System.Type t : apexClasses) {
      final Soqler.IWhereGroup classGroup = new Soqler.IWhereGroup();
      final String[] n = t.getName().split('\\.');

      if (n.size() > 1) {
        classGroup.wheres()
          .addAnd(new Soqler.IWhereName('ApexClass', Schema.ApexClass.NamespacePrefix, '=', n[0]))
          .addAnd(new Soqler.IWhereName('ApexClass', Schema.ApexClass.Name, '=', n[1]));
      } else {
        classGroup.wheres()
          .addAnd(new Soqler.IWhereName('ApexClass', Schema.ApexClass.Name, '=', n[0]));
      }

      classesGroup.wheres().addOr(classGroup);
    }

    query.wheres().addAnd(classesGroup);

    return (List<Schema.AsyncApexJob>) query.query();
  }

  public static List<Schema.AsyncApexJob> getAsyncActive(List<System.Type> apexClasses) {
    return getAsync(apexClasses, ASYNC_ACTIVE_STATUSES);
  }

  public static List<Schema.CronTrigger> getScheduled(String jobName, List<String> statuses) {
    Utils.requireNonNull(jobName, 'Job name cannot be null');

    Soqler query = new Soqler(Schema.CronTrigger.SObjectType);

    query.fields()
      .add(new Soqler.IFieldName('CronJobDetail', Schema.CronJobDetail.Name))
      .add(Schema.CronTrigger.NextFireTime)
      .add(Schema.CronTrigger.PreviousFireTime)
      .add(Schema.CronTrigger.State);

    query.wheres()
      .addAnd(
        new Soqler.IWhereName(
          'CronJobDetail',
          Schema.CronJobDetail.Name,
          jobName.contains('%') ? 'LIKE' : '=',
          jobName
        )
      )
      .addAnd(new Soqler.IWhereName('CronJobDetail', Schema.CronJobDetail.JobType, '=', '7'));

    if (statuses != null && !statuses.isEmpty()) {
      query.wheres().addAnd(new Soqler.IWhereName(Schema.CronTrigger.State, 'IN', statuses));
    }

    return (List<Schema.CronTrigger>) query.query();
  }

  public static List<Schema.CronTrigger> getScheduledActive(String jobName) {
    return getScheduled(jobName, SCHEDULED_ACTIVE_STATUSES);
  }

  public static List<String> getScheduledActiveStatuses() {
    return new List<String>(SCHEDULED_ACTIVE_STATUSES);
  }
}
