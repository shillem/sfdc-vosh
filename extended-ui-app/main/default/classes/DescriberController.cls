@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class DescriberController {
  private static final Logger.Instance LOG = Logger.getInstance(DescriberController.class);

  global class SObjectDescriptorQuery {
    global String type;
  }

  @AuraEnabled(cacheable=true)
  global static String getSObjectDescriptor(String query) {
    try {
      final SObjectDescriptorQuery q = (SObjectDescriptorQuery) JSON.deserialize(
        Utils.optStringOrElse(query, '{}'),
        SObjectDescriptorQuery.class
      );

      Utils.requireNonNull(q.type, 'Type cannot be null');

      final Schema.SObjectType type = Describer.getInstance().getGlobal().get(q.type);

      if (type == null) {
        throw new IllegalArgumentException('SObjectType ' + q.type + ' does not exist');
      }

      return JSON.serialize(new UI.SObjectDescriptor(type), true);
    } catch (System.Exception e) {
      LOG.error('getSObjectDescriptor()', e);

      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  global static String getSObjectFields(String query) {
    try {
      final Describer.SObjectFieldFilter filter = (Describer.SObjectFieldFilter) JSON.deserialize(
        Utils.optStringOrElse(query, '{}'),
        Describer.SObjectFieldFilter.class
      );

      return JSON.serialize(getSObjectFields(filter), true);
    } catch (System.Exception e) {
      LOG.error('getSObjectFields(String)', e);

      throw new AuraHandledException(e.getMessage());
    }
  }

  global static List<UI.ListboxItem> getSObjectFields(Describer.SObjectFieldFilter filter) {
    Utils.requireNonNull(filter, 'Filter cannot be null');

    final List<UI.ListboxItem> results = new List<UI.ListboxItem>();

    for (Schema.SObjectField f : Describer.getInstance().querySObjectFields(filter)) {
      results.add(new UI.ListboxItem(String.valueOf(f)));
    }

    results.sort();

    return results;
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
