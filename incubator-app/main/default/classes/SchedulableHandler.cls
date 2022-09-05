public abstract class SchedulableHandler implements Schedulable {
  public enum SchedulingStatus {
    DISABLED,
    DISABLED_ALREADY,
    ENABLED,
    ENABLED_ALREADY
  }

  public virtual SchedulingStatus disableJobScheduling() {
    String jobIdentifier = getJobId();

    if (jobIdentifier == null) {
      return SchedulingStatus.DISABLED_ALREADY;
    }

    System.abortJob(jobIdentifier);

    return SchedulingStatus.DISABLED;
  }

  public virtual SchedulingStatus enableJobScheduling() {
    if (isJobScheduled()) {
      return SchedulingStatus.ENABLED_ALREADY;
    }

    String jobIdentifier = System.schedule(getJobName(), getCronExpression(), newJobInstance());

    if (Id.valueOf(jobIdentifier).getSObjectType() != Schema.CronTrigger.SObjectType) {
      throw new System.UnexpectedException('Unable to schedule job ' + getJobName());
    }

    return SchedulingStatus.ENABLED;
  }

  protected abstract String getCronExpression();

  public Schema.CronTrigger getJob() {
    return getJob(getJobName());
  }

  public Id getJobId() {
    return getJobId(getJobName());
  }

  protected abstract String getJobName();

  public Boolean isJobScheduled() {
    return isJobScheduled(getJobName());
  }

  protected abstract Schedulable newJobInstance();

  public static Schema.AsyncApexJob getAsyncJob(System.Type apexClass, List<String> jobType) {
    Utils.requireNonNull(apexClass, 'Class cannot be null');

    Soqler query = new Soqler(Schema.AsyncApexJob.SObjectType).setMaxCount(1);

    query.fields().add(Schema.AsyncApexJob.Id).add(Schema.AsyncApexJob.Status);

    if (jobType != null && !jobType.isEmpty()) {
      query.wheres().addAnd(new Soqler.IWhereName(Schema.AsyncApexJob.JobType, 'IN', jobType));
    }

    query.wheres()
      .addAnd(
        new Soqler.IWhereName(
          Schema.AsyncApexJob.Status,
          'IN',
          new List<String>{ 'Holding', 'Preparing', 'Processing', 'Queued' }
        )
      );

    String[] name = apexClass.getName().split('\\.');

    if (name.size() > 1) {
      query.wheres()
        .addAnd(new Soqler.IWhereName('ApexClass', Schema.ApexClass.NamespacePrefix, '=', name[0]))
        .addAnd(new Soqler.IWhereName('ApexClass', Schema.ApexClass.Name, '=', name[1]));
    } else {
      query.wheres()
        .addAnd(new Soqler.IWhereName('ApexClass', Schema.ApexClass.Name, '=', name[0]));
    }

    List<Schema.AsyncApexJob> jobs = (List<Schema.AsyncApexJob>) query.query();

    return jobs.isEmpty() ? null : jobs[0];
  }

  public static Schema.CronTrigger getJob(String jobName) {
    Utils.requireNonNull(jobName, 'Job name cannot be null');

    Soqler query = new Soqler(Schema.CronTrigger.SObjectType);

    query.fields()
      .add(Schema.CronTrigger.Id)
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

    List<Schema.CronTrigger> triggers = (List<Schema.CronTrigger>) query.query();

    return triggers.isEmpty() ? null : triggers[0];
  }

  public static Id getJobId(String jobName) {
    return getJob(jobName)?.Id;
  }

  public static Boolean isAsyncJobPresent(System.Type apexClass, List<String> jobType) {
    return getAsyncJob(apexClass, jobType) != null;
  }

  public static Boolean isJobScheduled(String jobName) {
    return getJobId(jobName) != null;
  }
}
