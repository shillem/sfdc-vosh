@isTest(isParallel=true)
public class PkgTest {
  @isTest
  static void main() {
    System.assert(Pkg.getInstance().getNamespace() != null);
    System.assert(Pkg.getInstance().getVersion() != null);
  }
}
