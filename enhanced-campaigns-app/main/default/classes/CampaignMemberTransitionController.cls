public with sharing class CampaignMemberTransitionController {
  private class DescriptorRequest {
    private final Id campaignId;
    private final Id recordId;
  }

  private class EmailTemplateLookupRequest {
    private final String term;

    private List<String> getEntityTypes() {
      return new List<String>{
        String.valueOf(Schema.Campaign.SObjectType),
        String.valueOf(Schema.Contact.SObjectType),
        String.valueOf(Schema.Lead.SObjectType)
      };
    }
  }

  @AuraEnabled(cacheable=true)
  public static String auraGetEmailTemplates(String payload) {
    try {
      EmailTemplateLookupRequest request = (EmailTemplateLookupRequest) JSON.deserialize(
        payload,
        EmailTemplateLookupRequest.class
      );

      Utils.requireNonNull(request.term, 'Term cannot be null');

      String term = request.term.replace('\\*', '%');
      term = term.contains('%') ? term : '%' + term + '%';

      List<Schema.EmailTemplate> records = [
        SELECT Id, Name
        FROM EmailTemplate
        WHERE
          (RelatedEntityType = NULL
          OR RelatedEntityType IN :request.getEntityTypes())
          AND Name LIKE :term
      ];

      Set<UI.ListboxItem> results = new Set<UI.ListboxItem>();

      for (Schema.EmailTemplate record : records) {
        results.add(new UI.ListboxItem(record.Id, record.Name));
      }

      return JSON.serialize(results, true);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static String auraGetObjectLabel() {
    try {
      return Describer.getInstance()
        .getObjectDescribe(Schema.Campaign_Member_Transition__c.SObjectType)
        .getLabel();
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static String auraGetRecord(String payload) {
    try {
      DescriptorRequest request = (DescriptorRequest) JSON.deserialize(
        payload,
        DescriptorRequest.class
      );

      Utils.Entry campaignEntry;
      Utils.Entry emailTemplateEntry;
      Schema.Campaign_Member_Transition__c record;

      if (request.recordId != null) {
        record = [
          SELECT
            Campaign__r.Name,
            Email_Template_Id__c,
            Final_Status__c,
            Initial_Status__c,
            Organization_Wide_Email_Address_Id__c
          FROM Campaign_Member_Transition__c
          WHERE Id = :request.recordId
        ];

        campaignEntry = new Utils.Entry(record.Campaign__r.Id, record.Campaign__r.Name);

        if (record.Email_Template_Id__c != null) {
          Schema.EmailTemplate emailTemplate = [
            SELECT Name
            FROM EmailTemplate
            WHERE Id = :record.Email_Template_Id__c
          ];

          emailTemplateEntry = new Utils.Entry(emailTemplate.Id, emailTemplate.Name);
        }
      } else if (request.campaignId != null) {
        campaignEntry = new Utils.Entry(
          request.campaignId,
          [SELECT Name FROM Campaign WHERE Id = :request.campaignId]
          .Name
        );
      } else {
        throw new UnsupportedOperationException('Either Campaign Id or Record Id must be present');
      }

      UI.SObjectDescriptor descr = new UI.SObjectDescriptor(
        Schema.Campaign_Member_Transition__c.SObjectType,
        new Set<Schema.SObjectField>{
          Schema.Campaign_Member_Transition__c.Campaign__c,
          Schema.Campaign_Member_Transition__c.Email_Template_Id__c,
          Schema.Campaign_Member_Transition__c.Final_Status__c,
          Schema.Campaign_Member_Transition__c.Initial_Status__c,
          Schema.Campaign_Member_Transition__c.Organization_Wide_Email_Address_Id__c
        }
      );

      Set<Utils.Entry> memberStatuses = getMemberStatuses((Id) campaignEntry.getValue());

      descr.getField(Schema.Campaign_Member_Transition__c.Campaign__c)
        .setValue(campaignEntry.getValue());
      descr.getField(Schema.Campaign_Member_Transition__c.Initial_Status__c)
        .addOptions(memberStatuses);
      descr.getField(Schema.Campaign_Member_Transition__c.Final_Status__c)
        .addOptions(memberStatuses);

      if (emailTemplateEntry != null) {
        descr.getField(Schema.Campaign_Member_Transition__c.Email_Template_Id__c)
          .addOption(emailTemplateEntry);
      }

      descr.getField(Schema.Campaign_Member_Transition__c.Organization_Wide_Email_Address_Id__c)
        .addOptions(getOrgWideEmailAddresses());

      if (record != null) {
        descr.setValues(record);
      }

      return JSON.serialize(
        new Map<String, Object>{
          'campaignName' => campaignEntry.getLabel(),
          'descriptor' => descr
        },
        true
      );
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static Schema.Campaign_Member_Transition__c auraSaveRecord(
    Schema.Campaign_Member_Transition__c record
  ) {
    try {
      upsert record;

      return record;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static Set<Utils.Entry> getMemberStatuses(Id campaignId) {
    Set<Utils.Entry> values = new Set<Utils.Entry>();

    List<Schema.CampaignMemberStatus> records = [
      SELECT Label
      FROM CampaignMemberStatus
      WHERE CampaignId = :campaignId
      ORDER BY SortOrder
    ];

    for (Schema.CampaignMemberStatus record : records) {
      values.add(new Utils.Entry(record.Label));
    }

    return values;
  }

  private static Set<Utils.Entry> getOrgWideEmailAddresses() {
    Set<Utils.Entry> values = new Set<Utils.Entry>();

    for (Schema.OrgWideEmailAddress record : [
      SELECT Id, Address, DisplayName
      FROM OrgWideEmailAddress
    ]) {
      values.add(
        new Utils.Entry(
          record.Id,
          String.format('{0} <{1}>', new List<String>{ record.DisplayName, record.Address })
        )
      );
    }

    return values;
  }
}
