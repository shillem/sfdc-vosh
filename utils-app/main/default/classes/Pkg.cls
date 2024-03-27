/**
 * @description An utility object that provides eventual package information for the class passed in.
 *
 * @since 1.1
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class Pkg {
  private static Pkg instance;

  private System.Type t;

  private String license;
  private String namespace;
  private String version;

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
    if (namespace == null) {
      namespace = '';

      final List<String> classNameParts = String.valueOf(t).split('\\.', 2);

      if (classNameParts.size() > 1) {
        namespace = classNameParts[0];
      }
    }

    return namespace;
  }

  /**
   * @description It returns the package license status
   *
   * @since 1.1
   */
  @SuppressWarnings('PMD.ApexCRUDViolation')
  private String getLicense() {
    if (license == null) {
      final List<Schema.PackageLicense> records = [
        SELECT Status
        FROM PackageLicense
        WHERE NamespacePrefix = :getNamespace()
      ];

      license = records.isEmpty() ? 'N/A' : records[0].Status;
    }

    return license;
  }

  /**
   * @description It returns the package version, if applicable
   *
   * @since 1.1
   */
  @SuppressWarnings('PMD.ApexCRUDViolation')
  global String getVersion() {
    if (version == null) {
      version = 'N/A';

      final String namespace = getNamespace();

      if (String.isNotEmpty(namespace)) {
        final List<Schema.Publisher> results = [
          SELECT MajorVersion, MinorVersion
          FROM Publisher
          WHERE NamespacePrefix = :namespace
        ];

        if (!results.isEmpty()) {
          version = results[0].MajorVersion + '.' + results[0].MinorVersion;
        }
      }
    }

    return version;
  }

  /**
   * @description Check if the license is valid
   *
   * @since 1.1
   */
  public Boolean isLicensed() {
    final String value = getLicense();

    return !value.equals('N/A') && !value.equals('Free');
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
