import 'dart:async';
import 'dart:isolate';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';
import 'src/request_impl.dart';
import 'cherubim.dart';

/// Enables a [Server] to communicate over [SendPort]s.
class IsolateAdapter implements Adapter {
  final Map<String, User> _users = {};
  bool _closed = false, _opened = false;
  final StreamController<Tuple2<User, Request>> _onRequest =
      new StreamController<Tuple2<User, Request>>();
  final Uuid _uuid = new Uuid();

  /// A [ReceivePort] that listens for messages from clients.
  final ReceivePort receivePort = new ReceivePort();

  @override
  Stream<Tuple2<User, Request>> get onRequest => _onRequest.stream;

  @override
  void broadcast(Response response) {
    _users.values.forEach((u) => u.send(response));
  }

  @override
  Future close() async {
    _closed = true;
    _onRequest.close();
    receivePort.close();
    _users.clear();
  }

  @override
  void start() {
    if (_closed || _opened)
      throw new StateError('Cannot re-open an IsolateAdapter.');
    receivePort.listen(_handleMessage);
  }

  _handleMessage(message) {
    if (message is List &&
        message.length >= 2 &&
        message[0] is String &&
        message[1] is Map) {
      var clientId = message[0] as String;
      if (_users.containsKey(clientId)) {
        var request = RequestImpl.parse(message[1]);
        var user = _users[clientId];
        _onRequest.add(new Tuple2(user, request));
      }
    } else if (message is SendPort) {
      var clientId = _uuid.v4();
      _users[clientId] = new _IsolateUserImpl(message);
      message.send(clientId);
    }
  }
}

class _IsolateUserImpl implements User {
  final SendPort sendPort;

  _IsolateUserImpl(this.sendPort);

  @override
  void send(Response response) {
    sendPort.send(response.toJson());
  }
}
