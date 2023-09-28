({
  doInit: function (cmp, event, helper) {
    const utils = cmp.find("utils");
    const pageReference = cmp.get("v.pageReference");

    if (pageReference) {
      const {
        attributes: { recordId: campaignId }
      } = utils.untanglePageReference(pageReference);

      cmp.set("v.campaignId", campaignId);

      if (!cmp.get("v.recordId")) {
        cmp.find("form").setNewRecord(campaignId);
      }
    }

    utils.auraAction($A, { method: cmp.get("c.auraGetObjectLabel") }).then(
      $A.getCallback(function (label) {
        const modal = cmp.find("modal");

        modal.set("v.loading", false);
        modal.set("v.title", label);
      })
    );
  },
  handleModalAction: function (cmp, event, helper) {
    const { name } = event.getParam("value");

    switch (name) {
      case "close":
        helper.navigateToCampaign(cmp);

        break;
      case "ok":
        cmp
          .find("form")
          .save()
          .then(
            $A.getCallback(function (success) {
              if (success) {
                helper.navigateToCampaign(cmp);
              }
            })
          );

        break;
    }
  }
});
