public inherited sharing class HttpAppender implements Queueable, Database.AllowsCallouts {
  private final List<String> serializedEntries;

  public HttpAppender(List<Schema.Pe_Logger__e> events) {
    Utils.requireNonNull(events, 'Events cannot be null');

    serializedEntries = new List<String>();

    for (Schema.Pe_Logger__e e : events) {
      serializedEntries.add(e.Payload__c);
    }
  }

  @SuppressWarnings('PMD.ApexInsecureEndpoint')
  private HttpRequest createRequest() {
    final HttpRequest req = new HttpRequest();

    req.setEndpoint('http://api.webhookinbox.com/i/ypsNUrjA/in/');
    // req.setEndpoint('https://sfdc-vosh.free.beeceptor.com/my/salesforce');
    // req.setEndpoint('https://hookb.in/Lg3OpWXQpZC1lrp1aYN2');
    req.setMethod('POST');
    req.setTimeout(60000);

    final Map<String, String> headers = new Map<String, String>{
      'Content-Encoding' => 'gzip',
      'Content-Type' => 'application/json',
      'X-Sfdc-Org-Id' => UserInfo.getOrganizationId(),
      'X-Sfdc-Org-Name' => UserInfo.getOrganizationName(),
      'X-Sfdc-User-Id' => UserInfo.getUserId()
    };

    for (String key : headers.keySet()) {
      req.setHeader(key, headers.get(key));
    }

    return req;
  }

  public void execute(QueueableContext context) {
    try {
      final HttpRequest req = createRequest();

      for (String s : serializedEntries) {
        req.setBody(s);

        final HttpResponse res = new Http().send(req);

        if (res.getStatusCode() != 200) {
          System.debug(
            System.LoggingLevel.ERROR,
            String.format('[{0}] {1}', new List<Object>{ res.getStatusCode(), res.getBody() })
          );
        }
      }
    } catch (System.Exception e) {
      System.debug(System.LoggingLevel.ERROR, e);
    }
  }
}
