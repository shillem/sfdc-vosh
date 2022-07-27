global class CmsmTriggerHandler extends TriggerHandler.Routine {
  private class Rejiggler {
    private final Id campaignId;
    private final Map<String, Schema.CampaignMemberStatus> statuses;

    private Set<Schema.CampaignMemberStatus> upserts;
    private Set<Schema.CampaignMemberStatus> deletes;

    private Rejiggler(Id campaignId, Map<String, Schema.CampaignMemberStatus> statuses) {
      this.campaignId = campaignId;
      this.statuses = statuses;
    }

    private void rejiggle(List<Schema.Cs_Cmsm__c> mappings) {
      Schema.CampaignMemberStatus defaultStatus = getDefaultStatus();

      upserts = new Set<Schema.CampaignMemberStatus>();
      deletes = new Set<Schema.CampaignMemberStatus>();

      for (Schema.Cs_Cmsm__c mapping : mappings) {
        Schema.CampaignMemberStatus status = statuses.get(mapping.Campaign_Member_Status__c);
        Integer sortOrder = 100 + (Integer) mapping.Sort_Order__c;

        if (status != null) {
          status.SortOrder = sortOrder;
          upserts.add(status);
          statuses.remove(mapping.Campaign_Member_Status__c);

          continue;
        }

        Schema.CampaignMemberStatus newStatus = new Schema.CampaignMemberStatus(
          CampaignId = campaignId,
          HasResponded = mapping.Has_Responded__c,
          IsDefault = mapping.Is_Default__c,
          Label = mapping.Campaign_Member_Status__c,
          SortOrder = sortOrder
        );

        upserts.add(newStatus);

        if (mapping.Is_Default__c && defaultStatus != null) {
          defaultStatus.IsDefault = false;

          upserts.add(defaultStatus);
        }
      }

      deletes.addAll(statuses.values());
    }

    private Schema.CampaignMemberStatus getDefaultStatus() {
      for (Schema.CampaignMemberStatus status : statuses.values()) {
        if (status.IsDefault) {
          return status;
        }
      }

      return null;
    }
  }

  private class MemberStatusProcessor {
    private final Map<Id, String> campaigns;
    private final Map<String, List<Schema.Cs_Cmsm__c>> mappings;
    private final Map<Id, Map<String, Schema.CampaignMemberStatus>> statuses;

    private MemberStatusProcessor(Map<Id, String> campaigns) {
      this.campaigns = campaigns;
      this.mappings = getMappings();
      this.statuses = getStatuses();
    }

    private Map<String, List<Schema.Cs_Cmsm__c>> getMappings() {
      Set<String> types = new Set<String>(campaigns.values());
      Map<String, List<Schema.Cs_Cmsm__c>> values = new Map<String, List<Schema.Cs_Cmsm__c>>();

      for (Schema.Cs_Cmsm__c value : [
        SELECT
          Campaign_Member_Status__c,
          Campaign_Type__c,
          Is_Default__c,
          Has_Responded__c,
          Sort_Order__c
        FROM Cs_Cmsm__c
        WHERE Campaign_Type__c IN :types OR Campaign_Type__c = '*'
      ]) {
        List<Schema.Cs_Cmsm__c> bucket = values.get(value.Campaign_Type__c);

        if (bucket == null) {
          bucket = new List<Schema.Cs_Cmsm__c>();

          values.put(value.Campaign_Type__c, bucket);
        }

        bucket.add(value);
      }

      return values;
    }

    private Map<Id, Map<String, Schema.CampaignMemberStatus>> getStatuses() {
      Map<Id, Map<String, Schema.CampaignMemberStatus>> statuses = new Map<Id, Map<String, Schema.CampaignMemberStatus>>();

      for (Schema.CampaignMemberStatus status : [
        SELECT CampaignId, IsDefault, Label, SortOrder
        FROM CampaignMemberStatus
        WHERE CampaignId IN :campaigns.keySet()
      ]) {
        Map<String, Schema.CampaignMemberStatus> labels = statuses.get(status.CampaignId);

        if (labels == null) {
          labels = new Map<String, Schema.CampaignMemberStatus>();

          statuses.put(status.CampaignId, labels);
        }

        labels.put(status.Label, status);
      }

      return statuses;
    }

    private void process() {
      Set<Schema.CampaignMemberStatus> upserts = new Set<Schema.CampaignMemberStatus>();
      Set<Schema.CampaignMemberStatus> deletes = new Set<Schema.CampaignMemberStatus>();

      for (Id campaignId : campaigns.keySet()) {
        List<Schema.Cs_Cmsm__c> campaignMappings = mappings.get(campaigns.get(campaignId));

        if (campaignMappings == null) {
          campaignMappings = mappings.get('*');
        }

        if (campaignMappings == null) {
          continue;
        }

        Map<String, Schema.CampaignMemberStatus> campaignStatuses = statuses.get(campaignId);

        if (campaignStatuses == null) {
          campaignStatuses = new Map<String, Schema.CampaignMemberStatus>();
        }

        Rejiggler rej = new Rejiggler(campaignId, campaignStatuses);
        rej.rejiggle(campaignMappings);

        upserts.addAll(rej.upserts);
        deletes.addAll(rej.deletes);
      }

      if (upserts.isEmpty()) {
        return;
      }

      upsert new List<Schema.CampaignMemberStatus>(upserts);

      if (!deletes.isEmpty()) {
        delete new List<Schema.CampaignMemberStatus>(deletes);
      }
    }
  }

  private Map<Id, String> campaigns;

  global override void afterInsert(SObject record) {
    queueCampaign((Schema.Campaign) record);
  }

  global override System.TriggerOperation pre() {
    campaigns = new Map<Id, String>();

    return getOperationType();
  }

  global override void post() {
    if (campaigns.isEmpty()) {
      return;
    }

    new MemberStatusProcessor(campaigns).process();
  }

  global override Schema.SObjectType getSObjectType() {
    return Schema.Campaign.SObjectType;
  }

  private void queueCampaign(Schema.Campaign campaign) {
    campaigns.put(campaign.Id, campaign.Type);
  }
}
