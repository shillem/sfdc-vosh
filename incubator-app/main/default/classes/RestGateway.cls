@RestResource(urlMapping='/*')
global with sharing class RestGateway {
  private static final Logger.Instance RG_LOG = Logger.getInstance(RestGateway.class);

  public abstract class AbstractPath implements Path {
    public void execute(System.RestRequest request, System.RestResponse response) {
      try {
        onExecute(request, response);
      } catch (System.Exception e) {
        onError(request, response, e);
      }
    }

    protected abstract String getUri();

    public virtual Boolean matches(String uri) {
      return uri.equals(Pkg.getInstance().getNamespace() + getUri());
    }

    public virtual void onError(
      System.RestRequest request,
      System.RestResponse response,
      System.Exception e
    ) {
      RG_LOG.error('onError()', e);

      response.statusCode = 500;
    }

    public virtual void onExecute(System.RestRequest request, System.RestResponse response) {
      response.statusCode = 405;
    }
  }

  public interface Path {
    void execute(System.RestRequest request, System.RestResponse response);
    Boolean matches(String resourcePath);
  }

  private static List<Path> paths;

  @HttpGet
  global static void doGet() {
    resolve();
  }

  @HttpPost
  global static void doPost() {
    resolve();
  }

  @HttpPut
  global static void doPut() {
    resolve();
  }

  private static List<Path> getPaths() {
    if (paths == null) {
      paths = new List<Path>();

      final ApexClass[] classes = (ApexClass[]) [
        FIND 'RestGateway.AbstractPath OR RestGateway.Path'
        IN ALL FIELDS
        RETURNING ApexClass(Name, NamespacePrefix)
      ][0];

      for (ApexClass cls : classes) {
        try {
          if (String.isEmpty(cls.NamespacePrefix)) {
            paths.add((Path) System.Type.forName(cls.Name));
          } else {
            paths.add((Path) System.Type.forName(cls.NamespacePrefix, cls.Name));
          }
        } catch (System.Exception e) {
          RG_LOG.error('onError()', e);
        }
      }
    }

    return paths;
  }

  private static void resolve() {
    final System.RestRequest request = RestContext.request;
    final System.RestResponse response = RestContext.response;

    for (Path p : getPaths()) {
      if (p.matches(request.requestURI)) {
        p.execute(request, response);

        return;
      }
    }

    response.statusCode = 404;
  }
}
