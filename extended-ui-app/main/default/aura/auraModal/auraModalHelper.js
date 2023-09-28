({
  calculateStepRange: function (cmp, value) {
    const steps = cmp.get("v.steps");
    const index = this.getStepIndex(steps, value);

    cmp.set("v.firstStep", index === 0);
    cmp.set("v.lastStep", index === steps.length - 1);
  },
  fireAction: function (cmp, value) {
    cmp.getEvent("onaction").setParams({ value }).fire();
  },
  getStepIndex: function (steps, stepValue) {
    return steps.findIndex((step) => step.value === stepValue);
  },
  getStepName: function (cmp, mover) {
    const steps = cmp.get("v.steps");
    const currentIndex = this.getStepIndex(steps, cmp.get("v.step"));

    return steps[currentIndex + mover].value;
  },
  setOpenedClasses: function (cmp) {
    const opened = cmp.get("v.opened");

    let sectionClass = "slds-modal";
    let backdropClass = "slds-backdrop";

    if (opened) {
      const size = cmp.get("v.size");

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
