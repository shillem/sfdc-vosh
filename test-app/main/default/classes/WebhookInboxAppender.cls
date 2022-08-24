public inherited sharing class WebhookInboxAppender extends Logger.HttpPostAppender {
  public WebhookInboxAppender() {
    super(
      'http://api.webhookinbox.com/i/P6rGBvLq/in/',
      new Map<String, String>{
        'Content-Encoding' => 'gzip',
        'Content-Type' => 'application/json',
        'Sfdc-Org-Id' => UserInfo.getOrganizationId(),
        'Sfdc-Org-Name' => UserInfo.getOrganizationName(),
        'Sfdc-User-Id' => UserInfo.getUserId()
      },
      null
    );
  }
}
