@isTest(isParallel=true)
public class DescriberControllerTest {
  @isTest
  static void getSObjectFields() {
    insert LoggerTest.createDefaultProfile();

    final Describer.SObjectFieldFilter filter = new Describer.SObjectFieldFilter();
    filter.setObjectName(String.valueOf(Schema.Account.SObjectType));

    final List<String> results = (List<String>) JSON.deserialize(
      DescriberController.getSObjectFields(JSON.serialize(filter)),
      List<String>.class
    );

    final String fieldName = String.valueOf(Schema.Account.Name);

    System.assert(results.contains(fieldName), 'It should have contained ' + fieldName);
  }

  @isTest
  static void getSObjectTypes() {
    insert LoggerTest.createDefaultProfile();

    final Describer.SObjectTypeFilter filter = new Describer.SObjectTypeFilter();
    filter.setRegex('^Acc.+');

    final List<String> results = (List<String>) JSON.deserialize(
      DescriberController.getSObjectTypes(JSON.serialize(filter)),
      List<String>.class
    );

    final String objectName = String.valueOf(Schema.Account.SObjectType);

    System.assert(results.contains(objectName), 'It should have contained ' + objectName);
  }
}
