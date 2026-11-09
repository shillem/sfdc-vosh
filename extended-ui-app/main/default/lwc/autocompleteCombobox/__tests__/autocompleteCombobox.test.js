import { createElement } from "lwc";
import AutocompleteCombobox from "c/autocompleteCombobox";

const flush = () => Promise.resolve();

function mount(props = {}) {
  const element = createElement("c-autocomplete-combobox", { is: AutocompleteCombobox });
  Object.assign(element, { delay: 0, minimum: 0, ...props });
  document.body.appendChild(element);
  return element;
}

// Opens the listbox and answers the lookup with the given results.
async function open(element, results) {
  element.addEventListener("lookup", (event) => event.detail.success(results));
  element.shadowRoot.querySelector(".slds-combobox__input").click();
  jest.runAllTimers();
  await flush();
}

const label = (element) => element.shadowRoot.querySelector("label");
const items = (element) =>
  [...element.shadowRoot.querySelectorAll(".slds-listbox__item")]
    .slice(1)
    .map((item) => item.querySelector("h3")?.textContent ?? item.firstChild.dataset.value);

describe("c-autocomplete-combobox", () => {
  beforeEach(() => jest.useFakeTimers());

  afterEach(() => {
    while (document.body.firstChild) document.body.removeChild(document.body.firstChild);
    jest.useRealTimers();
  });

  it("names the combobox with a visible label", () => {
    const element = mount({ label: "Lead Field" });

    expect(label(element).classList).not.toContain("slds-assistive-text");
    expect(
      element.shadowRoot.querySelector('[role="combobox"]').getAttribute("aria-labelledby")
    ).toBe(label(element).id);
  });

  it("keeps a hidden label for assistive technology", () => {
    const element = mount({ label: "Lead Field", variant: "label-hidden" });

    expect(label(element).textContent.trim()).toBe("Lead Field");
    expect(label(element).classList).toContain("slds-assistive-text");
  });

  it("heads each run of grouped results and leaves ungrouped results bare", async () => {
    const element = mount();

    await open(element, [
      { label: "Plain", value: "plain" },
      { label: "Email", value: "Email", group: "Contact" },
      { label: "Name", value: "Name", group: "Contact" },
      { label: "Revenue", value: "Account.AnnualRevenue", group: "Related Account" }
    ]);

    expect(items(element)).toEqual([
      "plain",
      "Contact",
      "Email",
      "Name",
      "Related Account",
      "Account.AnnualRevenue"
    ]);
  });

  it("does not select a group header", async () => {
    const element = mount();
    const change = jest.fn();
    element.addEventListener("change", change);

    await open(element, [{ label: "Email", value: "Email", group: "Contact" }]);
    element.shadowRoot
      .querySelector(".slds-listbox__option-header")
      .dispatchEvent(new CustomEvent("mousedown", { bubbles: true }));

    expect(change).not.toHaveBeenCalled();
  });
});
