({
  getNavigator: function (cmp) {
    return cmp.find("navigator");
  },
  goToObject: function (cmp) {
    const props = {
      type: "standard__objectPage",
      attributes: {
        actionName: cmp.get("v.actionName"),
        filterName: cmp.get("v.filterName"),
        objectApiName: cmp.get("v.objectApiName")
      }
    };

    if (!["home", "list", "new"].includes(props.attributes.actionName)) {
      throw new Error("Invalid action name");
    }

    if (!props.attributes.objectApiName) {
      throw new Error("Missing Object API name");
    }

    this.getNavigator(cmp).navigate(props);
  },
  goToRecord: function (cmp) {
    const props = {
      type: "standard__recordPage",
      attributes: {
        actionName: cmp.get("v.actionName"),
        recordId: cmp.get("v.recordId")
      }
    };

    if (!["clone", "edit", "view"].includes(props.attributes.actionName)) {
      throw new Error("Invalid action name");
    }

    if (!props.attributes.recordId) {
      throw new Error("Missing record Id");
    }

    this.getNavigator(cmp).navigate(props);
  },
  goToRecordRelationship: function (cmp) {
    const props = {
      type: "standard__recordRelationshipPage",
      attributes: {
        actionName: cmp.get("v.actionName"),
        recordId: cmp.get("v.recordId"),
        relationshipApiName: cmp.get("v.relationshipApiName")
      }
    };

    if ("view" !== props.attributes.actionName) {
      throw new Error("Invalid action name");
    }

    if (!props.attributes.recordId) {
      throw new Error("Missing record Id");
    }

    if (!props.attributes.relationshipApiName) {
      throw new Error("Missing relationship API name");
    }

    this.getNavigator(cmp).navigate(props);
  },
  goToWeb: function (cmp) {
    const props = {
      type: "standard__webPage",
      attributes: {
        url: cmp.get("v.url")
      }
    };

    if (!props.attributes.url) {
      throw new Error("Missing url");
    }

    this.getNavigator(cmp).navigate(props);
  }
});
