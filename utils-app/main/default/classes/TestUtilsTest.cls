@isTest(isParallel=true)
public class TestUtilsTest {
  @isTest
  static void capturesRequestsInOrder() {
    final TestUtils.HttpResponseMock response = new TestUtils.HttpResponseMock(
        Pattern.compile('https://example.com/.*')
      )
      .add('POST', 201, 'created')
      .add('GET', 200, Blob.valueOf('fetched'));
    final TestUtils.HttpCalloutMock mock = new TestUtils.HttpCalloutMock().addResponse(response);
    Assert.isTrue(mock.getRequests().isEmpty());
    Assert.areEqual(0, response.getInvocations());
    Test.setMock(System.HttpCalloutMock.class, mock);

    final System.HttpRequest post = new System.HttpRequest();
    post.setEndpoint('https://example.com/first');
    post.setMethod('POST');
    post.setHeader('Authorization', 'Bearer test-token');
    post.setHeader('Content-Type', 'application/json');
    post.setBody('{"message":"hello"}');
    final System.HttpRequest get = new System.HttpRequest();
    get.setEndpoint('https://example.com/second');
    get.setMethod('GET');

    Test.startTest();
    final System.HttpResponse created = new Http().send(post);
    final System.HttpResponse fetched = new Http().send(get);
    Test.stopTest();

    Assert.areEqual(201, created.getStatusCode());
    Assert.areEqual('created', created.getBody());
    Assert.areEqual(200, fetched.getStatusCode());
    Assert.areEqual(Blob.valueOf('fetched'), fetched.getBodyAsBlob());
    Assert.areEqual(2, response.getInvocations());
    Assert.areEqual(2, mock.getRequests().size());
    final System.HttpRequest captured = mock.getRequests()[0];
    Assert.areEqual('https://example.com/first', captured.getEndpoint());
    Assert.areEqual('POST', captured.getMethod());
    Assert.areEqual('Bearer test-token', captured.getHeader('Authorization'));
    Assert.areEqual('application/json', captured.getHeader('Content-Type'));
    Assert.areEqual('{"message":"hello"}', captured.getBody());
    Assert.areEqual('https://example.com/second', mock.getRequests()[1].getEndpoint());
    Assert.areEqual('GET', mock.getRequests()[1].getMethod());
    Assert.areEqual('', mock.getRequests()[1].getBody());

    response.add('GET', 204);
    Assert.areEqual(1, response.getInvocations(), 'Replacing GET resets only its count');
    final System.HttpResponse empty = new Http().send(get);
    Assert.areEqual(204, empty.getStatusCode());
    Assert.areEqual('', empty.getBody());
    Assert.areEqual(2, response.getInvocations());
    Assert.areEqual(3, mock.getRequests().size(), 'Replacing a response retains request history');
    Assert.areEqual('https://example.com/second', mock.getRequests()[2].getEndpoint());
    Assert.areEqual('GET', mock.getRequests()[2].getMethod());
  }

  @isTest
  static void capturesUnmatchedRequestsWithoutCountingResponse() {
    final TestUtils.HttpResponseMock response = new TestUtils.HttpResponseMock(
        Pattern.compile('https://example.com/matched')
      )
      .add('POST');
    final TestUtils.HttpCalloutMock mock = new TestUtils.HttpCalloutMock().addResponse(response);
    final System.HttpRequest req = new System.HttpRequest();
    req.setEndpoint('https://example.com/unmatched');
    req.setMethod('GET');

    try {
      mock.respond(req);
      Assert.fail('An unmatched request must still throw');
    } catch (System.UnsupportedOperationException e) {
      Assert.areEqual(
        'No response implementation for [GET] https://example.com/unmatched',
        e.getMessage()
      );
    }
    Assert.areEqual(new List<System.HttpRequest>{ req }, mock.getRequests());
    Assert.areEqual(0, response.getInvocations());
  }
}
