import { api, LightningElement } from "lwc";

export default class Modal extends LightningElement {
  @api disabled = false;
  @api hideFooter = false;
  @api i18n = { cancel: "Cancel", close: "Close", next: "Next", ok: "OK", previous: "Previous" };
  @api loading = false;
  @api opened = false;
  @api size;
  @api step;
  @api steps;
  @api tagline;
  @api title;

  customFooter = false;

  get backdropClass() {
    let value = "slds-backdrop";

    if (this.opened) {
      value += " slds-backdrop_open";
    }

    return value;
  }

  get closed() {
    return !this.opened;
  }

  get hasSteps() {
    return Array.isArray(this.steps) && this.steps.length > 0;
  }

  get headerClass() {
    return this.title || this.tagline
      ? "slds-modal__header"
      : "slds-modal__header slds-modal__header_empty";
  }

  get lastStep() {
    return !this.hasSteps || this.steps[this.steps.length - 1].value === this.step;
  }

  get sectionClass() {
    let value = "slds-modal";

    if (this.opened) {
      if (this.size) {
        value += " slds-modal_" + this.size;
      }

      value += " slds-fade-in-open";
    } else {
      value += " slds-hide";
    }

    return value;
  }

  get showDefaultFooter() {
    return !this.noFooter;
  }

  get showFooter() {
    return !this.hideFooter;
  }

  get stepIndex() {
    return this.steps.findIndex((step) => step.value === this.step);
  }

  get subsequentStep() {
    return this.hasSteps && !this.steps[0].value === this.step;
  }

  fireAction(detail) {
    this.dispatchEvent(new CustomEvent("action", { detail }));
  }

  handleFooterSlotChange() {
    this.customFooter = true;
  }

  handleClose() {
    this.fireAction({ name: "close" });
  }

  handleOk() {
    this.fireAction({ name: "ok" });
  }

  handleStepNext() {
    this.fireAction({
      name: "stepNext",
      step: this.steps[this.stepIndex + 1]
    });
  }

  handleStepPrevious() {
    this.fireAction({
      name: "stepPrevious",
      step: this.steps[this.stepIndex - 1]
    });
  }
}
