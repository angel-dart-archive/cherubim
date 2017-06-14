/// Represents a request of data from a client to the server.
abstract class Request {
  /// A *unique* identifier for this request.
  String get id;

  /// A verb signifying the kind of action a server should take in response to this request.
  String get method;

  /// Arbitrary metadata associated with this request.
  Map<String, String> get metaData;

  /// Converts this request into a representation suitable for JSON encoding.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method,
      'meta_data': metaData
    };
  }
}