@isTest(isParallel=true)
public class DescriberControllerTest {
  @isTest
  static void getSObjectFields() {
    insert LoggerTest.createDefaultProfile();

    final Describer.SObjectFieldFilter filter = new Describer.SObjectFieldFilter();
    filter.setObjectName(String.valueOf(Schema.Account.SObjectType));

    final List<Object> results = (List<Object>) JSON.deserializeUntyped(
      DescriberController.getSObjectFields(JSON.serialize(filter))
    );

    final String fieldName = String.valueOf(Schema.Account.Name);

    for (Object result : results) {
      final Map<String, Object> m = (Map<String, Object>) result;

      if (fieldName.equals((String) m.get('value'))) {
        return;
      }
    }

    System.assert(false, 'It should have contained ' + fieldName);
  }

  @isTest
  static void getSObjectTypes() {
    insert LoggerTest.createDefaultProfile();

    final Describer.SObjectTypeFilter filter = new Describer.SObjectTypeFilter();
    filter.setRegex('^Acc.+');

    final List<Object> results = (List<Object>) JSON.deserializeUntyped(
      DescriberController.getSObjectTypes(JSON.serialize(filter))
    );

    final String objectName = String.valueOf(Schema.Account.SObjectType);

    for (Object result : results) {
      final Map<String, Object> m = (Map<String, Object>) result;

      if (objectName.equals((String) m.get('value'))) {
        return;
      }
    }

    System.assert(false, 'It should have contained ' + objectName);
  }
}
