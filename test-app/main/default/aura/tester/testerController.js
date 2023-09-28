({
  handleAutocompleteLookup: function (cmp, event, helper) {
    const { failure, success, term } = event.getParams();

    success([
      { value: "a", label: "a" },
      { value: "b", label: "b" }
    ]);
  }
});
