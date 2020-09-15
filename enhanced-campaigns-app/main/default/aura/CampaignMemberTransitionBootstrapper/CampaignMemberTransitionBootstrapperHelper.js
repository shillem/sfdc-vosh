({
    navigateToCampaign: function (cmp) {
        $A.get("e.force:navigateToSObject")
            .setParams({
                recordId: cmp.get("v.campaignId"),
                slideDevName: "related"
            })
            .fire();
    }
});
