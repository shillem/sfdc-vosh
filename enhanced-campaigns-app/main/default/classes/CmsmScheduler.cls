global class CmsmScheduler implements Schedulable {
  private class Transition {
    private final Schema.Campaign_Member_Transition__c record;

    private Boolean disabled;

    private Transition(Schema.Campaign_Member_Transition__c record) {
      this.record = record;
      this.disabled = false;
    }

    private Id getCampaignId() {
      return (Id) record.Campaign__c;
    }

    private Id getEmailTemplateId() {
      return (Id) record.Email_Template_Id__c;
    }

    private String getFinalStatus() {
      return record.Final_Status__c;
    }

    private String getInitialStatus() {
      return record.Initial_Status__c;
    }

    private Id getOrgWideEmailAddressId() {
      return (Id) record.Organization_Wide_Email_Address_Id__c;
    }

    private Boolean process(Schema.CampaignMember member, TransitionProcessor processor) {
      member.Status = getFinalStatus();

      Id templateId = getEmailTemplateId();

      if (templateId == null) {
        processor.queueMember(member);

        return true;
      }

      if (!processor.canAddMessage()) {
        return false;
      }

      Messaging.SingleEmailMessage template = Messaging.renderStoredEmailTemplate(
        templateId,
        processor.getTargetObjectId(member),
        getCampaignId()
      );
      Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

      message.setHtmlBody(template.getHtmlBody());
      message.setOptOutPolicy('FILTER');
      message.setOrgWideEmailAddressId(getOrgWideEmailAddressId());
      message.setPlainTextBody(template.getPlainTextBody());
      message.setSubject(template.getSubject());
      message.setTargetObjectId(template.getTargetObjectId());

      processor.queueMember(member);
      processor.queueMessage(message);

      return true;
    }
  }

  private class Transitions {
    private final Set<Id> campaignIds;
    private final Map<String, Transition> values;

    private Transitions() {
      campaignIds = new Set<Id>();
      values = new Map<String, Transition>();
    }

    private void add(Transition value) {
      campaignIds.add(value.getCampaignId());
      values.put(value.getInitialStatus(), value);
    }

    private void process(TransitionProcessor processor) {
      List<Schema.CampaignMember> members = [
        SELECT ContactId, LeadId, Status
        FROM CampaignMember
        WHERE CampaignId IN :campaignIds AND Status IN :values.keySet()
      ];

      for (Schema.CampaignMember member : members) {
        Transition trans = values.get(member.Status);

        if (trans.disabled) {
          continue;
        }

        trans.disabled = !trans.process(member, processor);
      }
    }
  }

  private class TransitionProcessor {
    private Map<Id, Schema.CampaignMember> members;
    private List<Messaging.SingleEmailMessage> messages;
    private Boolean messageLimiter;

    private TransitionProcessor() {
      members = new Map<Id, Schema.CampaignMember>();
      messages = new List<Messaging.SingleEmailMessage>();
      messageLimiter = false;
    }

    private Boolean canAddMessage() {
      if (messageLimiter) {
        return false;
      }

      try {
        Messaging.reserveSingleEmailCapacity(messages.size() + 1);

        return true;
      } catch (System.HandledException e) {
        messageLimiter = true;
      }

      return false;
    }

    private void dropMember(Id targetObjectId) {
      members.remove(targetObjectId);
    }

    private List<Schema.CampaignMember> getMembers() {
      return members.values();
    }

    private List<Messaging.SingleEmailMessage> getMessages() {
      return messages;
    }

    private Id getTargetObjectId(Schema.CampaignMember member) {
      return member.ContactId != null ? member.ContactId : member.LeadId;
    }

    private void queueMember(Schema.CampaignMember member) {
      members.put(getTargetObjectId(member), member);
    }

    private void queueMessage(Messaging.SingleEmailMessage message) {
      messages.add(message);
    }
  }

  global void execute(SchedulableContext context) {
    List<Schema.Campaign> campaigns = [
      SELECT
        (
          SELECT
            Campaign__c,
            Email_Template_Id__c,
            Final_Status__c,
            Initial_Status__c,
            Organization_Wide_Email_Address_Id__c
          FROM Campaign_Member_Transitions__r
        )
      FROM Campaign
      WHERE IsActive = TRUE
    ];

    TransitionProcessor processor = new TransitionProcessor();

    for (Schema.Campaign camp : campaigns) {
      List<Schema.Campaign_Member_Transition__c> cmts = camp.Campaign_Member_Transitions__r;

      if (cmts != null && !cmts.isEmpty()) {
        Transitions trans = new Transitions();

        for (Schema.Campaign_Member_Transition__c cmt : cmts) {
          trans.add(new Transition(cmt));
        }

        trans.process(processor);
      }
    }

    if (!processor.getMessages().isEmpty()) {
      List<Messaging.SendEmailResult> results = Messaging.sendEmail(processor.getMessages(), false);

      for (Messaging.SendEmailResult result : results) {
        if (!result.isSuccess()) {
          processor.dropMember(result.getErrors()[0].getTargetObjectId());
        }
      }
    }

    if (!processor.getMembers().isEmpty()) {
      update processor.getMembers();
    }
  }

  global static void schedule() {
    schedule('0 0 * * * ?');
  }

  global static void schedule(String schedule) {
    Utils.requireNonNull(schedule, 'Schedule cannot be null');

    System.schedule('CmsmScheduler-' + System.currentTimeMillis(), schedule, new CmsmScheduler());
  }
}
