/// Represents a response, A.K.A. data sent from the server to a client.
abstract class Response {
  /// The status of this response.
  int get statusCode;

  /// The ID of the original request to which this is a response.
  String get requestId;

  /// Arbitrary metadata associated with this response.
  Map<String, String> get metaData;

  /// The result of running a server-side operation.
  Map<String, String> get body;

  /// Converts this response into a representation suitable for JSON encoding.
  Map<String, dynamic> toJson() {
    return {
      'status_code': statusCode,
      'request_id': requestId,
      'meta_data': metaData,
      'body': body
    };
  }
}
