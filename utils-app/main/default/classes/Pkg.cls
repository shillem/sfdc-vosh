/**
 * @description An utility object that provides eventual package information for the class passed in.
 *
 * @since 1.1
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class Pkg {
  private static Pkg instance;

  private System.Type t;

  private String v;
  private String n;

  /**
   * @description The parameterless constructor
   *
   * @param value the class the package information will be derived from
   * @since 1.1
   */
  private Pkg(System.Type t) {
    this.t = t;
  }

  /**
   * @description It returns the package namespace, if any
   *
   * @since 1.1
   */
  global String getNamespace() {
    if (n == null) {
      n = '';

      final List<String> classNameParts = String.valueOf(t).split('\\.', 2);

      if (classNameParts.size() > 1) {
        n = classNameParts[0];
      }
    }

    return n;
  }

  /**
   * @description It returns the package version, if applicable
   *
   * @since 1.1
   */
  @SuppressWarnings('PMD.ApexDmlViolation')
  global String getVersion() {
    if (v == null) {
      v = 'N/A';

      final String namespace = getNamespace();

      if (String.isNotEmpty(namespace)) {
        final List<Schema.Publisher> results = [
          SELECT MajorVersion, MinorVersion
          FROM Publisher
          WHERE NamespacePrefix = :namespace AND MajorVersion > 0
        ];

        if (!results.isEmpty()) {
          v = results[0].MajorVersion + '.' + results[0].MinorVersion;
        }
      }
    }

    return v;
  }

  /**
   * @description It returns the singleton instance. Information will be based on the current class
   *
   * @since 1.1
   */
  global static Pkg getInstance() {
    if (instance == null) {
      instance = newInstance(Pkg.class);
    }

    return instance;
  }

  /**
   * @description It returns a new instance. Information will be based on the passed class
   *
   * @since 1.1
   */
  global static Pkg newInstance(System.Type t) {
    Utils.requireNonNull(t, 'Type cannot be null');

    return new Pkg(t);
  }
}
