@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class SchemaUtils {
  /**
   * @description It returns the profile id of the profile name provided.
   *
   * @param name the profile name
   * @return the profile id
   * @since 1.1
   */
  global static Id getProfileId(String name) {
    Utils.requireNonNull(name, 'Name cannot be null');

    return getProfileIds(new Set<String>{ name }).get(name);
  }

  /**
   * @description It returns a map of profile names and respective ids for the names provided.
   *
   * @param names the profile names
   * @return the map with names and ids
   * @since 1.1
   */
  global static Map<String, Id> getProfileIds(Set<String> names) {
    Utils.requireNonNull(names, 'Names cannot be null');

    final Map<String, Id> values = new Map<String, Id>();

    final Soqler soql = new Soqler(Schema.Profile.SObjectType);
    soql.fields().add(Schema.Profile.Id).add(Schema.Profile.Name);
    soql.wheres().addAnd(new Soqler.IWhereVariable(Schema.Profile.Name, 'IN', 'names'));

    for (Schema.Profile record : Database.query(soql.queryToString())) {
      values.put(record.Name, record.Id);
    }

    return values;
  }

  /**
   * @description It assigns the user the permission set provided.
   *
   * @param userId the user id
   * @param name the permission name
   * @since 1.1
   */
  global static void permissionSetAssign(Id userId, String name) {
    Utils.requireNonNull(userId, 'User Id cannot be null');
    Utils.requireNonNull(name, 'Name cannot be null');

    final List<Schema.PermissionSet> records;

    {
      final Soqler soql = new Soqler(Schema.PermissionSet.SObjectType);
      soql.fields().add(Schema.PermissionSet.Id);

      permissionSetNameAddClause(name, soql);

      records = (List<Schema.PermissionSet>) soql.query();
    }

    if (records.isEmpty()) {
      throw new System.QueryException('Could not find permission set with name ' + name);
    }

    Sec.insertOne(
      new Schema.PermissionSetAssignment(AssigneeId = userId, PermissionSetId = records[0].Id),
      new Sec.DmlRequest().all()
    );
  }

  /**
   * @description It checks whether a user has the permission set provided.
   *
   * @param userId the user id
   * @param name the permission name
   * @return whether the user has permission set or not
   * @since 1.1
   */
  global static Boolean permissionSetAssigned(Id userId, String name) {
    Utils.requireNonNull(userId, 'User Id cannot be null');
    Utils.requireNonNull(name, 'Name cannot be null');

    final Soqler soql = new Soqler(Schema.PermissionSetAssignment.SObjectType);
    soql.fields().add(Schema.PermissionSetAssignment.Id);
    soql.wheres()
      .addAnd(new Soqler.IWhereName(Schema.PermissionSetAssignment.AssigneeId, '=', userId));

    permissionSetNameAddClause(name, soql);

    return soql.queryCount() > 0;
  }

  private static void permissionSetNameAddClause(String name, Soqler soql) {
    final String[] parts = name.split('\\.');

    if (parts.size() > 1) {
      soql.wheres()
        .addAnd(
          new Soqler.IWhereName(
            'PermissionSet',
            Schema.PermissionSet.NamespacePrefix,
            '=',
            parts[0]
          )
        )
        .addAnd(new Soqler.IWhereName('PermissionSet', Schema.PermissionSet.Name, '=', parts[1]));
    } else {
      soql.wheres()
        .addAnd(new Soqler.IWhereName('PermissionSet', Schema.PermissionSet.Name, '=', parts[0]));
    }
  }
}
