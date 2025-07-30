({
  doInit: function (cmp, event, helper) {
    var utils = cmp.find("utils");
    var pageReference = cmp.get("v.pageReference");

    if (pageReference) {
      var untangled = utils.untanglePageReference(pageReference);

      cmp.set("v.campaignId", untangled.attributes.campaignId);

      if (!cmp.get("v.recordId")) {
        cmp.find("form").setNewRecord(untangled.attributes.campaignId);
      }
    }

    utils.auraAction($A, { method: cmp.get("c.auraGetObjectLabel") }).then(
      $A.getCallback(function (label) {
        var modal = cmp.find("modal");

        modal.set("v.loading", false);
        modal.set("v.title", label);
      })
    );
  },
  handleModalAction: function (cmp, event, helper) {
    var param = event.getParam("value");

    switch (param.name) {
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
      default:
        console.warn("Unhandled modal action: " + param.name);
    }
  }
});
