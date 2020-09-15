({
    doInit: function (cmp, event, helper) {
        helper.setOpenedClasses(cmp);
    },
    handleClose: function (cmp, event, helper) {
        helper.fireAction(cmp, { name: "close" });
    },
    handleOk: function (cmp, event, helper) {
        helper.fireAction(cmp, { name: "ok" });
    },
    handleOpenedChange: function (cmp, event, helper) {
        helper.setOpenedClasses(cmp);
    },
    handleStepChange: function (cmp, event, helper) {
        helper.calculateStepRange(cmp, event.getParam("value"));
    },
    handleStepNext: function (cmp, event, helper) {
        helper.fireAction(cmp, { name: "stepNext", step: helper.getStepName(cmp, 1) });
    },
    handleStepPrevious: function (cmp, event, helper) {
        helper.fireAction(cmp, { name: "stepPrevious", step: helper.getStepName(cmp, -1) });
    }
});
