@isTest
public class CmsmTest {
  @testSetup
  static void init() {
    insert new List<SObject>{
      new Cs_Cmsm__c(
        Campaign_Member_Status__c = 'One',
        Campaign_Type__c = '*',
        Is_Default__c = true,
        Name = 'One',
        Has_Responded__c = false,
        Sort_Order__c = 100
      ),
      new Cs_Cmsm__c(
        Campaign_Member_Status__c = 'Two',
        Campaign_Type__c = '*',
        Is_Default__c = false,
        Name = 'Two',
        Has_Responded__c = false,
        Sort_Order__c = 200
      ),
      new Cs_Cmsm__c(
        Campaign_Member_Status__c = 'Three',
        Campaign_Type__c = '*',
        Is_Default__c = false,
        Name = 'Three',
        Has_Responded__c = true,
        Sort_Order__c = 300
      )
    };

    Schema.User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    System.runAs(currentUser) {
      insert new Schema.EmailTemplate(
        Name = 'CampaignMemberManagerInvitation',
        // BrandTemplateId = brand.Id,
        DeveloperName = 'CampaignMemberManagerInvitation',
        Body = '{{{Recipient.Id}}}',
        FolderId = currentUser.Id,
        Subject = '{{{Campaign.Number__c}}}',
        TemplateType = 'Text'
      );
    }
  }

  @isTest
  static void memberStatusCreator() {
    Schema.PicklistEntry firstTypeEntry = Describer.getInstance()
      .getFieldDescribe(Campaign.Type)
      .getPicklistValues()[0];
    String emailCampaignType = firstTypeEntry != null ? firstTypeEntry.getValue() : null;

    TriggerHandler.enable(CmsmTriggerHandler.class);

    Test.startTest();

    List<Campaign> bucket = new List<Campaign>{
      new Campaign(Name = 'Bucket'),
      new Campaign(Name = 'Email', Type = emailCampaignType)
    };

    insert bucket;

    Test.stopTest();

    System.assertEquals(
      3,
      [SELECT COUNT() FROM CampaignMemberStatus WHERE CampaignId = :bucket[0].Id]
    );
  }

  @isTest
  static void memberStatusController() {
    Schema.Campaign camp = new Schema.Campaign(Name = 'Demo');

    insert camp;

    Test.startTest();

    // Object Label
    System.assert(CampaignMemberTransitionController.auraGetObjectLabel() != null);

    // Object Descriptor
    Utils.Mapper response = Utils.deserializeToMapper(
      CampaignMemberTransitionController.auraGetRecord(
        JSON.serialize(new Map<String, Object>{ 'campaignId' => camp.Id })
      )
    );

    System.assert(
      response.containsKey('campaignName'),
      'It should have contained the campaign name'
    );
    System.assert(response.containsKey('descriptor'), 'It should have contained the descriptor');

    Utils.Mapper fieldMap = response.getObjectAsMapper('descriptor').getObjectAsMapper('fieldMap');

    System.assert(
      fieldMap.containsKey(String.valueOf(Schema.Campaign_Member_Transition__c.Initial_Status__c))
    );

    // EmailTemplate Lookup
    List<Object> results = (List<Object>) JSON.deserializeUntyped(
      CampaignMemberTransitionController.auraGetEmailTemplates(
        JSON.serialize(new Map<String, Object>{ 'term' => 'invitation' })
      )
    );

    System.assert(!results.isEmpty(), 'It should have contained at least a template');

    Test.stopTest();
  }

  @isTest
  static void memberStatusTransitioner() {
    TriggerHandler.enable(CmsmTriggerHandler.class);

    List<Schema.Campaign> campaigns = new List<Schema.Campaign>{
      new Schema.Campaign(Name = 'Bucket1', IsActive = true),
      new Schema.Campaign(Name = 'Bucket2')
    };

    List<Schema.Lead> leads = new List<Schema.Lead>{
      new Schema.Lead(FirstName = 'First1', LastName = 'Last2', Company = 'No Company1'),
      new Schema.Lead(FirstName = 'First2', LastName = 'Last2', Company = 'No Company2'),
      new Schema.Lead(
        FirstName = 'First3',
        LastName = 'Last3',
        Company = 'No Company3',
        Email = 'example@example.com'
      )
    };

    insert new List<SObject>{ campaigns[0], campaigns[1], leads[0], leads[1], leads[2] };

    insert new List<SObject>{
      newMemberTransition(
        'One',
        'Two',
        [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'CampaignMemberManagerInvitation']
        .Id,
        null,
        campaigns[0].Id
      )
    };

    List<Schema.CampaignMember> campaignMembers = new List<Schema.CampaignMember>{
      newMember(leads[0].Id, 'One', campaigns[0].Id),
      newMember(leads[1].Id, 'Three', campaigns[0].Id),
      newMember(leads[2].Id, 'One', campaigns[0].Id),
      newMember(leads[1].Id, 'One', campaigns[1].Id)
    };

    insert campaignMembers;

    Test.startTest();

    new CmsmScheduler().execute(null);

    Test.stopTest();

    Map<Id, Schema.CampaignMember> feedback = new Map<Id, Schema.CampaignMember>(
      [SELECT Id, Status FROM CampaignMember WHERE CampaignId = :campaigns[0].Id]
    );

    System.assertEquals('One', feedback.get(campaignMembers[0].Id).Status);
    System.assertEquals('Three', feedback.get(campaignMembers[1].Id).Status);
    System.assertEquals('Two', feedback.get(campaignMembers[2].Id).Status);
  }

  @isTest
  static void memberStatusTransitionerSchedule() {
    Test.startTest();

    CmsmScheduler.schedule();

    Test.stopTest();

    List<Schema.CronTrigger> crons = [
      SELECT Id
      FROM CronTrigger
      WHERE CronJobDetail.Name LIKE 'CmsmScheduler-%'
    ];

    System.assert(!crons.isEmpty());
  }

  private static Schema.CampaignMember newMember(Id whoId, String status, Id campaignId) {
    Schema.CampaignMember member = new Schema.CampaignMember(
      CampaignId = campaignId,
      Status = status
    );

    if (whoId.getSObjectType() == Schema.Contact.SObjectType) {
      member.ContactId = whoId;
    } else {
      member.LeadId = whoId;
    }

    return member;
  }

  private static Schema.Campaign_Member_Transition__c newMemberTransition(
    String initialStatus,
    String finalStatus,
    Id emailTemplateId,
    Id orgWideAddressId,
    Id campaignId
  ) {
    return new Schema.Campaign_Member_Transition__c(
      Campaign__c = campaignId,
      Email_Template_Id__c = emailTemplateId,
      Initial_Status__c = initialStatus,
      Final_Status__c = finalStatus,
      Organization_Wide_Email_Address_Id__c = orgWideAddressId
    );
  }
}
