({
  doInit: function (cmp, event, helper) {
    helper.asyncLoadDescriptor(cmp);
  },
  handleEmailTemplateChange: function (cmp, event, helper) {
    var record = cmp.get("v.record");

    record.vosh__Email_Template_Id__c = event.getParam("value");

    cmp.set("v.record", record);
  },
  handleEmailTemplateLookup: function (cmp, event, helper) {
    var params = event.getParams();

    cmp
      .find("utils")
      .auraAction($A, {
        jsonify: true,
        method: cmp.get("c.auraGetEmailTemplates"),
        params: { payload: { term: params.term } }
      })
      .then(
        $A.getCallback(function (results) {
          params.success(results);
        })
      )
      .catch(function (error) {
        params.failure(error[0].message);
      });
  },
  handleRecordIdChange: function (cmp, event, helper) {
    helper.asyncLoadDescriptor(cmp);
  },
  handleSave: function (cmp, event, helper) {
    var valid = cmp.find("field").reduce(function (flag, input) {
      input.setCustomValidity("");

      return input.reportValidity() ? flag : false;
    }, true);

    if (!valid) {
      return;
    }

    var utils = cmp.find("utils");

    return utils
      .auraAction($A, {
        method: cmp.get("c.auraSaveRecord"),
        params: {
          record: Object.assign(
            { sObjectType: "Campaign_Member_Transition__c", Id: cmp.get("v.recordId") },
            cmp.get("v.record")
          )
        }
      })
      .then(
        $A.getCallback(function (record) {
          cmp.set("v.record", record);

          $A.get("e.force:showToast")
            .setParams({
              message: cmp.get("v.descriptor").label + " was saved.",
              type: "success"
            })
            .fire();

          return true;
        })
      )
      .catch(function (error) {
        $A.get("e.force:showToast")
          .setParams({
            message: utils.extractErrorMessages(error).join("\\n"),
            type: "error"
          })
          .fire();

        return false;
      });
  },
  handleSetNewRecord: function (cmp, event, helper) {
    var params = event.getParam("arguments");

    helper.asyncLoadDescriptor(cmp, params.campaignId);
  }
});
