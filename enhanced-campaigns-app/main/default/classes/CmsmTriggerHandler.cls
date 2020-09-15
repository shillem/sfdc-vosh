global class CmsmTriggerHandler extends TriggerHandler.Routine {
    private Map<Id, String> campaigns;

    global CmsmTriggerHandler() {
        campaigns = new Map<Id, String>();
    }

    global override void afterInsert(SObject record) {
        queueCampaign((Schema.Campaign) record);
    }

    global override void post() {
        Set<Id> campaignIds = campaigns.keySet();
        Map<Id, List<Schema.CampaignMemberStatus>> defaultMemberStatuses = getDefaultMemberStatuses(
            campaignIds
        );
        Map<String, List<Schema.Cs_Cmsm__c>> statusMappings = getMemberStatusMappings(
            new Set<String>(campaigns.values())
        );
        List<Schema.CampaignMemberStatus> newStatusMappings = new List<Schema.CampaignMemberStatus>();

        for (String campaignId : campaignIds) {
            String campaignType = campaigns.get(campaignId);
            List<Schema.Cs_Cmsm__c> campaignStatusMappings = statusMappings.get(campaignType);

            if (campaignStatusMappings == null) {
                campaignStatusMappings = statusMappings.get('*');
            }

            if (campaignStatusMappings == null) {
                defaultMemberStatuses.remove(campaignId);

                continue;
            }

            for (Schema.Cs_Cmsm__c statusMapping : campaignStatusMappings) {
                newStatusMappings.add(
                    new Schema.CampaignMemberStatus(
                        CampaignId = campaignId,
                        HasResponded = statusMapping.Has_Responded__c,
                        IsDefault = statusMapping.Is_Default__c,
                        Label = statusMapping.Campaign_Member_Status__c,
                        SortOrder = (Integer) statusMapping.Sort_Order__c
                    )
                );
            }
        }

        if (newStatusMappings.isEmpty()) {
            return;
        }

        insert newStatusMappings;

        List<Schema.CampaignMemberStatus> previousStatusMappings = new List<Schema.CampaignMemberStatus>();

        for (List<Schema.CampaignMemberStatus> ls : defaultMemberStatuses.values()) {
            previousStatusMappings.addAll(ls);
        }

        if (!previousStatusMappings.isEmpty()) {
            delete previousStatusMappings;
        }
    }

    private Map<Id, List<Schema.CampaignMemberStatus>> getDefaultMemberStatuses(
        Set<Id> campaignIds
    ) {
        Map<Id, List<Schema.CampaignMemberStatus>> statuses = new Map<Id, List<Schema.CampaignMemberStatus>>();

        for (Schema.CampaignMemberStatus status : [
            SELECT CampaignId
            FROM CampaignMemberStatus
            WHERE CampaignId IN :campaignIds
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
            ORDER BY Campaign_Type__c
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
}
