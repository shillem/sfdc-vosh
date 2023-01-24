/**
 * @description An utility object that provides org instance information.
 *
 * @since 1.1
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class Ins {
  private static Ins instance;

  private Boolean sandbox;

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
