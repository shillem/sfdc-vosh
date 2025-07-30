({
  calculateStepRange: function (cmp, value) {
    var steps = cmp.get("v.steps");
    var index = this.getStepIndex(steps, value);

    cmp.set("v.firstStep", index === 0);
    cmp.set("v.lastStep", index === steps.length - 1);
  },
  fireAction: function (cmp, value) {
    cmp.getEvent("onaction").setParams({ value: value }).fire();
  },
  getStepIndex: function (steps, stepValue) {
    return steps.findIndex(function (step) {
      return step.value === stepValue;
    });
  },
  getStepName: function (cmp, mover) {
    var steps = cmp.get("v.steps");
    var currentIndex = this.getStepIndex(steps, cmp.get("v.step"));

    return steps[currentIndex + mover].value;
  },
  setOpenedClasses: function (cmp) {
    var opened = cmp.get("v.opened");
    var sectionClass = "slds-modal";
    var backdropClass = "slds-backdrop";

    if (opened) {
      var size = cmp.get("v.size");

      if (size) {
        sectionClass += " slds-modal_" + size;
      }

      sectionClass += " slds-fade-in-open";
      backdropClass += " slds-backdrop_open";
    } else {
      sectionClass += " slds-hide";
    }

    cmp.set("v.sectionClass", sectionClass);
    cmp.set("v.backdropClass", backdropClass);
  }
});
