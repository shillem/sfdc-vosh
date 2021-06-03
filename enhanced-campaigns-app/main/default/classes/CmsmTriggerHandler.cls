global class CmsmTriggerHandler extends TriggerHandler.Routine {
    private Map<Id, String> campaigns;

    global override void afterInsert(SObject record) {
        queueCampaign((Schema.Campaign) record);
    }

    global override void pre() {
        campaigns = new Map<Id, String>();
    }

    global override void post() {
        if (campaigns.isEmpty()) {
            return;
        }

        Set<Id> campaignIds = campaigns.keySet();
        Map<Id, List<Schema.CampaignMemberStatus>> currentStatuses = getDefaultMemberStatuses(
            campaignIds
        );
        Map<String, List<Schema.Cs_Cmsm__c>> statusMappings = getMemberStatusMappings(
            new Set<String>(campaigns.values())
        );
        List<Schema.CampaignMemberStatus> newStatuses = new List<Schema.CampaignMemberStatus>();
        List<Schema.CampaignMemberStatus> discardedStatuses = new List<Schema.CampaignMemberStatus>();

        for (Id campaignId : campaignIds) {
            List<Schema.Cs_Cmsm__c> campaignStatusMappings = statusMappings.get(
                campaigns.get(campaignId)
            );

            if (campaignStatusMappings == null) {
                campaignStatusMappings = statusMappings.get('*');
            }

            if (campaignStatusMappings == null) {
                currentStatuses.remove(campaignId);

                continue;
            }

            List<Schema.CampaignMemberStatus> cs = currentStatuses.get(campaignId);

            if (cs == null) {
                cs = new List<Schema.CampaignMemberStatus>();
            }
            
            List<Schema.CampaignMemberStatus> ns = rejigCampaignMemberStatuses(
                campaignId,
                cs,
                campaignStatusMappings
            );

            newStatuses.addAll(ns);

            for (Integer i = ns.size(); i < cs.size(); i++) {
                discardedStatuses.add(cs.get(i));
            }
        }

        if (newStatuses.isEmpty()) {
            return;
        }

        upsert newStatuses;

        if (!discardedStatuses.isEmpty()) {
            delete discardedStatuses;
        }
    }

    private Map<Id, List<Schema.CampaignMemberStatus>> getDefaultMemberStatuses(
        Set<Id> campaignIds
    ) {
        Map<Id, List<Schema.CampaignMemberStatus>> statuses = new Map<Id, List<Schema.CampaignMemberStatus>>();

        for (Schema.CampaignMemberStatus status : [
            SELECT CampaignId, IsDefault, SortOrder
            FROM CampaignMemberStatus
            WHERE CampaignId IN :campaignIds
            ORDER BY SortOrder
        ]) {
            List<Schema.CampaignMemberStatus> bucket = statuses.get(status.CampaignId);

            if (bucket == null) {
                bucket = new List<Schema.CampaignMemberStatus>();

                statuses.put(status.CampaignId, bucket);
            }

            bucket.add(status);
        }

        return statuses;
    }

    private Map<String, List<Schema.Cs_Cmsm__c>> getMemberStatusMappings(Set<String> types) {
        Map<String, List<Schema.Cs_Cmsm__c>> statuses = new Map<String, List<Schema.Cs_Cmsm__c>>();

        for (Schema.Cs_Cmsm__c mapping : [
            SELECT
                Campaign_Member_Status__c,
                Campaign_Type__c,
                Is_Default__c,
                Has_Responded__c,
                Sort_Order__c
            FROM Cs_Cmsm__c
            WHERE Campaign_Type__c IN :types OR Campaign_Type__c = '*'
            ORDER BY Campaign_Type__c, Sort_Order__c
        ]) {
            List<Schema.Cs_Cmsm__c> bucket = statuses.get(mapping.Campaign_Type__c);

            if (bucket == null) {
                bucket = new List<Schema.Cs_Cmsm__c>();

                statuses.put(mapping.Campaign_Type__c, bucket);
            }

            bucket.add(mapping);
        }

        return statuses;
    }

    global override Schema.SObjectType getSObjectType() {
        return Schema.Campaign.SObjectType;
    }

    private void queueCampaign(Schema.Campaign campaign) {
        campaigns.put(campaign.Id, campaign.Type);
    }

    private List<Schema.CampaignMemberStatus> rejigCampaignMemberStatuses(
        Id campaignId,
        List<Schema.CampaignMemberStatus> currentStatuses,
        List<Schema.Cs_Cmsm__c> newMappings
    ) {
        List<Schema.CampaignMemberStatus> rejigged = new List<Schema.CampaignMemberStatus>();

        for (Integer i = 0; i < newMappings.size(); i++) {
            Schema.Cs_Cmsm__c newMapping = newMappings[i];
            Schema.CampaignMemberStatus status;

            if (i < currentStatuses.size()) {
                status = currentStatuses[i];
            } else {
                status = new Schema.CampaignMemberStatus(CampaignId = campaignId);
            }

            status.HasResponded = newMapping.Has_Responded__c;
            status.IsDefault = newMapping.Is_Default__c;
            status.Label = newMapping.Campaign_Member_Status__c;
            status.SortOrder = (Integer) newMapping.Sort_Order__c;

            rejigged.add(status);
        }

        return rejigged;
    }
}
