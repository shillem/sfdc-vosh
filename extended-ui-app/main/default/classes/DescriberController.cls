global inherited sharing class DescriberController {
  private static final Logger.Instance LOG = Logger.getInstance(DescriberController.class);

  @AuraEnabled(cacheable=true)
  global static String getSObjectFields(String query) {
    try {
      final Describer.SObjectFieldFilter filter = (Describer.SObjectFieldFilter) JSON.deserialize(
        Utils.optStringOrElse(query, '{}'),
        Describer.SObjectFieldFilter.class
      );

      final List<UI.ListboxItem> results = new List<UI.ListboxItem>();

      for (Schema.SObjectField f : Describer.getInstance().querySObjectFields(filter)) {
        results.add(new UI.ListboxItem(String.valueOf(f)));
      }

      results.sort();

      return JSON.serialize(results, true);
    } catch (System.Exception e) {
      LOG.error('getSObjectFields()', e);

      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  global static String getSObjectTypes(String query) {
    try {
      final Describer.SObjectTypeFilter filter = (Describer.SObjectTypeFilter) JSON.deserialize(
        Utils.optStringOrElse(query, '{}'),
        Describer.SObjectTypeFilter.class
      );

      final List<UI.ListboxItem> results = new List<UI.ListboxItem>();

      for (Schema.SObjectType t : Describer.getInstance().querySObjectTypes(filter)) {
        results.add(new UI.ListboxItem(String.valueOf(t)));
      }

      results.sort();

      return JSON.serialize(results, true);
    } catch (System.Exception e) {
      LOG.error('getSObjectTypes()', e);

      throw new AuraHandledException(e.getMessage());
    }
  }
}
