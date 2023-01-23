@isTest(isParallel=true)
public class InsTest {
  @isTest
  static void main() {
    System.assert(
      Ins.getInstance().isSandbox() != null,
      'A boolean type should have returned'
    );
  }
}
