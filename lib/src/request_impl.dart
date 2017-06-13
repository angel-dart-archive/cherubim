import 'apply_map.dart';
import 'request.dart';

class RequestImpl extends Request {
  @override
  String id, method;

  @override
  final Map<String, String> metaData = {};

  RequestImpl({this.id, this.method, Map<String, String> metaData: const {}}) {
    this.metaData.addAll(metaData ?? {});
  }

  static Request parse(Map map) {
    var request = new RequestImpl();
    if (map['id'] is String) request.id = map['id'];
    if (map['method'] is String) request.method = map['method'];
    if (map['meta_data'] is Map) applyMap(request.metaData, map['meta_data']);
    return request;
  }
}
