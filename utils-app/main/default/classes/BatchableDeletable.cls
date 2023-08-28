/**
 * @description An implementation of <code>Database.Batchable&lt:SObject&gt;</code> for deleting
 * records en masse.
 *
 * @since 1.0.15
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class BatchableDeletable implements Database.Batchable<SObject> {
  global class Parameters {
    global Boolean emptyRecycleBin;
    global String query;
  }

  private final Parameters params;

  /**
   * @description It creates an instance that will delete records returned by the specified query.
   *
   * @param params the JSON-serialized parameters
   * @see #BatchableDeletable(String)
   * @since 1.0.15
   */
  global BatchableDeletable(String params) {
    Utils.requireNonNull(params, 'Params cannot be null');

    this.params = (Parameters) JSON.deserialize(params, Parameters.class);

    if (this.params.query == null) {
      throw new IllegalArgumentException('Parameter query cannot be null');
    }
  }

  global void execute(Database.BatchableContext context, List<SObject> records) {
    final Sec.DmlResponse response = Sec.deleteMany(records, new Sec.DmlRequest().any());

    if (
      params.emptyRecycleBin != null &&
      params.emptyRecycleBin &&
      !response.getSucceeded().isEmpty()
    ) {
      Database.emptyRecycleBin(response.getSucceeded());
    }
  }

  @SuppressWarnings('PMD.EmptyStatementBlock')
  global void finish(Database.BatchableContext context) {
  }

  global Database.QueryLocator start(Database.BatchableContext context) {
    return Database.getQueryLocator(params.query);
  }
}
