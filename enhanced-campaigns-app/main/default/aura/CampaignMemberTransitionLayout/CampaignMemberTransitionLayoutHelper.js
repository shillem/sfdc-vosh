({
  asyncLoadDescriptor: function (cmp, campaignId) {
    var payload = {
      campaignId: campaignId,
      recordId: cmp.get("v.recordId")
    };

    if (!payload.campaignId && !payload.recordId) {
      return;
    }

    var utils = cmp.find("utils");

    return utils
      .auraAction($A, {
        jsonify: true,
        method: cmp.get("c.auraGetRecord"),
        params: { payload: payload }
      })
      .then(
        $A.getCallback(function (response) {
          cmp.set("v.campaignName", response.campaignName);
          cmp.set("v.descriptor", response.descriptor);

          cmp.set(
            "v.record",
            Object.values(response.descriptor.fieldMap).reduce(function (acc, field) {
              acc[field.name] = field.value;

              return acc;
            }, {})
          );
        })
      )
      .catch(function (error) {
        cmp.set("v.error", utils.extractErrorMessages(error).join("\\n"));
      });
  }
});
