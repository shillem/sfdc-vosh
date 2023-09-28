({
  invoke: function (cmp, event, helper) {
    const type = cmp.get("v.type");

    switch (type) {
      case "object":
        helper.goToObject(cmp);
        break;
      case "record":
        helper.goToRecord(cmp);
        break;
      case "recordRelationship":
        helper.goToRecordRelationship(cmp);
        break;
      case "web":
        helper.goToWeb(cmp);
        break;
      default:
        throw new Error("Invalid type");
    }
  }
});
