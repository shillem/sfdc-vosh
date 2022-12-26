import getSObjectFields from "@salesforce/apex/DescriberController.getSObjectFields";
import getSObjectTypes from "@salesforce/apex/DescriberController.getSObjectTypes";

class Describer {
  asyncGetSObjectFields(query) {
    return getSObjectFields({
      query: query ? JSON.stringify(query) : undefined
    }).then((results) => JSON.parse(results));
  }

  asyncGetSObjectTypes(query) {
    return getSObjectTypes({
      query: query ? JSON.stringify(query) : undefined
    }).then((results) => JSON.parse(results));
  }
}

const getInstance = function () {
  if (!Describer.instance) {
    Describer.instance = new Describer();
  }

  return Describer.instance;
};

export { getInstance };