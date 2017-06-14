import 'apply_map.dart';
import 'response.dart';

class ResponseImpl extends Response {
  @override
  int statusCode;

  @override
  String requestId;

  @override
  final Map<String, String> body = {};

  @override
  final Map<String, String> metaData = {};

  ResponseImpl({this.statusCode,
    this.requestId,
    Map<String, String> body: const {},
    Map<String, String> metaData: const {}}) {
    this.body.addAll(body ?? {});
    this.metaData.addAll(metaData ?? {});
  }

  static Response parse(Map map) {
    var response = new ResponseImpl();

    if (map['status_code'] is int) response.statusCode = map['status_code'];
    if (map['request_id'] is String) response.requestId = map['request_id'];
    if (map['body'] is Map) applyMap(response.body, map['body']);
    if (map['meta_data'] is Map) applyMap(response.metaData, map['meta_data']);

    return response;
  }
}