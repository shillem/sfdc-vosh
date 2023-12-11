/**
 * @description An utility object that provides org instance information.
 *
 * @since 1.1
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class Ins {
  global class SensitivityLevel {
    global final String name;
    global final String label;
    global final Integer order;

    private SensitivityLevel(String name, String label, Integer order) {
      this.name = name;
      this.label = label;
      this.order = order;
    }
  }

  private static Ins instance;

  private Boolean sandbox;
  private List<SensitivityLevel> sensitivies;

  @SuppressWarnings('PMD.EmptyStatementBlock')
  private Ins() {
  }

  /**
   * @description It returns whether the instance the code is running is a Sandbox instance.
   *
   * @since 1.1
   */
  @SuppressWarnings('PMD.ApexCRUDViolation')
  global Boolean isSandbox() {
    if (sandbox == null) {
      final Schema.Organization record = [SELECT IsSandBox FROM Organization LIMIT 1];

      sandbox = record.IsSandbox;
    }

    return sandbox;
  }

  @SuppressWarnings('PMD.ApexCRUDViolation')
  global List<SensitivityLevel> getSensitivityLevels() {
    if (sensitivies == null) {
      sensitivies = new List<SensitivityLevel>();

      for (Schema.FieldSecurityClassification record : [
        SELECT ApiName, MasterLabel, SortOrder
        FROM FieldSecurityClassification
        ORDER BY SortOrder
        LIMIT 100
      ]) {
        sensitivies.add(new SensitivityLevel(record.ApiName, record.MasterLabel, record.SortOrder));
      }
    }

    return new List<SensitivityLevel>(sensitivies);
  }

  /**
   * @description It returns the singleton instance. Information will be based on the current class
   *
   * @since 1.1
   */
  global static Ins getInstance() {
    if (instance == null) {
      instance = new Ins();
    }

    return instance;
  }
}
