import { api, LightningElement } from "lwc";

export default class AutocompleteCombobox extends LightningElement {
  @api delay = 500;
  @api fieldLevelHelp;
  @api label;
  @api length = 5;
  @api messageWhenValueMissing = "Complete this field.";
  @api minimum = 3;
  @api placeholder;
  @api required = false;
  @api variant = "standard";

  expanded = false;
  focused = false;
  loading = false;
  results = [];
  selection = {};

  _options;
  _value;

  validation = true;
  validationCustomMessage;
  validationMessage;

  get comboboxIcon() {
    return this.empty ? "utility:down" : "utility:close";
  }

  get comboboxIconClass() {
    return (
      "slds-input__icon slds-input__icon_right" + (this.empty ? "" : " slds-input__icon_clickable")
    );
  }

  connectedCallback() {
    this.classList.add("slds-form-element");

    if (this.variant === "label-stacked") {
      this.classList.add("slds-form-element_stacked");
    }
  }

  get dropdownClass() {
    return (
      "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click" +
      (this.expanded ? " slds-is-open" : "")
    );
  }

  get empty() {
    return !(typeof this.value === "string" && this.value.length > 0);
  }

  get inputPlaceholder() {
    return this.minimum > 0 ? `Type at least ${this.minimum} chars to search` : "Type to search";
  }

  get listboxClass() {
    return `slds-dropdown slds-dropdown_length-${this.length} slds-dropdown_fluid`;
  }

  @api get options() {
    return this._options;
  }

  set options(values) {
    this._options = values;

    if (!Array.isArray(values) || this.empty) {
      this.selection = {};

      return;
    }

    const selected = values.find((v) => v.value === this._value);

    this.selection = selected ? selected : {};
  }

  @api get value() {
    return this._value;
  }

  set value(val) {
    this._value = val;

    const findValueOn = (token, values) => {
      const match = values.find((element) => element.value === token);

      if (!match) {
        return false;
      }

      this.selection = match;

      return true;
    };

    if (
      findValueOn(val, this.results) ||
      (Array.isArray(this._options) && findValueOn(val, this._options))
    ) {
      return;
    }

    this.selection = {
      label: val
    };
  }

  @api get validity() {
    const state = {
      customError:
        typeof this.validationCustomMessage === "string" && this.validationCustomMessage.length > 0,
      valueMissing: this.empty
    };

    state.valid = !Object.values(state).some((bool) => bool);

    return state;
  }

  @api checkValidity() {
    return this.validity.valid;
  }

  handleComboboxIconClick(event) {
    if (this.empty) {
      return;
    }

    event.preventDefault();

    this.fireValueChange("");
  }

  handleComboboxFocus(event) {
    if (!this.empty && event.target.classList.contains("slds-input__icon")) {
      return;
    }

    this.expanded = true;
    this.focused = true;

    if (this.minimum > 0) {
      this.results = [];

      return;
    }

    this.lookup("");
  }

  handleInputBlur() {
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setTimeout(() => {
      this.expanded = false;
    }, 200);

    this.reportValidity();
  }

  handleInputChange(event) {
    this.lookup(event.target.value);
  }

  handleInputKeyDown(event) {
    if (event.key === "Escape") {
      event.target.blur();
    } else if (event.key === "Enter") {
      this.lookup(event.target.value, true);
    }
  }

  handleInputMouseDown(event) {
    event.stopPropagation();
  }

  handleListboxMouseDown(event) {
    event.preventDefault();
  }

  handleOptionClick(event) {
    if (event.currentTarget.getAttribute("aria-disabled") === "true") {
      return;
    }

    event.stopPropagation();

    this.fireValueChange(event.currentTarget.dataset.value);
  }

  fireValueChange(value) {
    if (value !== this.value) {
      this.dispatchEvent(new CustomEvent("change", { detail: { value } }));
    }
  }

  lookup(term, force = false) {
    if (term === this.currentTerm && !force) {
      return;
    }

    this.currentTerm = term;

    if (term.length < this.minimum) {
      this.results = [];

      return;
    }

    if (this.lookupTimeout) {
      clearTimeout(this.lookupTimeout);
    }

    this.loading = true;

    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.lookupTimeout = setTimeout(() => {
      const re = new RegExp(`(${term})`, "gi");
      const matcher = (value) => value.replace(re, "<mark>$1</mark>");
      const transformResult = ({ disabled, icon, meta, label, value }) => {
        return {
          containerClass: meta
            ? "slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta"
            : "slds-media slds-listbox__option slds-listbox__option_plain slds-media_small",
          disabled: typeof disabled === "boolean" ? disabled : false,
          icon,
          iconClass: typeof disabled === "boolean" ? "slds-icon_disabled" : "",
          label,
          label_matched: typeof label === "string" ? matcher(label) : label,
          meta,
          meta_matched: typeof meta === "string" ? matcher(meta) : meta,
          selected: value === this.value,
          value
        };
      };

      this.dispatchEvent(
        new CustomEvent("lookup", {
          detail: {
            failure: (error) => {
              this.results = [transformResult({ disabled: true, label: error })];

              this.lookupTimeout = null;
              this.loading = false;
            },
            success: (results) => {
              const dressed = results.map(transformResult);

              if (dressed.length === 0) {
                const message = transformResult({
                  disabled: true,
                  label: "No results found",
                  value: "NA"
                });

                message.message = true;

                dressed.push(message);
              }

              this.results = dressed;
              this.expanded = true;

              this.lookupTimeout = null;
              this.loading = false;
            },
            term
          }
        })
      );
    }, this.delay);
  }

  renderedCallback() {
    if (this.focused) {
      const input = this.template.querySelector(".slds-listbox__option_term input");

      input.value = "";
      input.focus();

      this.focused = false;
    }

    if (this.hasRendered) {
      return;
    }

    const listbox = this.template.querySelector('[role="listbox"]');
    const input = this.template.querySelector(".slds-combobox__input-value");
    input.setAttribute("aria-controls", listbox.id);

    this.hasRendered = true;
  }

  @api reportValidity() {
    const state = this.validity;

    this.validation = state.valid;
    this.validationMessage = state.valid
      ? ""
      : state.customError
      ? this.validationCustomMessage
      : this.messageWhenValueMissing;

    if (this.validation) {
      this.classList.remove("slds-has-error");
    } else {
      this.classList.add("slds-has-error");
    }

    return state.valid;
  }

  @api setCustomValidity(message) {
    this.validationCustomMessage = message;
  }
}
