trigger Pe_LoggerTrigger on Pe_Logger__e (after insert) {
  System.enqueueJob(new HttpAppender(Trigger.new));
}