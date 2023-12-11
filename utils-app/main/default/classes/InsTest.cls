@isTest(isParallel=true)
public class InsTest {
  @isTest
  static void sandbox() {
    Assert.isNotNull(Ins.getInstance().isSandbox(), 'A boolean type should have returned');
  }

  @isTest
  static void sensitivities() {
    final List<Schema.FieldSecurityClassification> records = [
      SELECT ApiName
      FROM FieldSecurityClassification
      ORDER BY SortOrder
      LIMIT 100
    ];
    final List<Ins.SensitivityLevel> levels = Ins.getInstance().getSensitivityLevels();

    Assert.areEqual(records.size(), levels.size(), 'A boolean type should have returned');

    if (levels.size() > 0) {
      Assert.isNotNull(records[0].ApiName, levels[0].name);
    }
  }
}
