import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';
import 'src/exception.dart';
import 'src/request_impl.dart';
import 'src/request_method.dart' as method;
import 'src/response_impl.dart';
import 'src/response_status.dart' as status;
import 'cherubim.dart';

/// Queries a Cherubim server over a [SendPort].
class IsolateClient implements Client {
  final Map<String, Completer> _awaiting = {};
  final Map<String, Timer> _timers = {};
  final Completer _connect = new Completer();
  Timer _connectTimer;
  String _id;
  final StreamController<Tuple2<String, dynamic>> _onBroadcast =
      new StreamController<Tuple2<String, dynamic>>();
  final Uuid _uuid = new Uuid();

  /// A [ReceivePort] that listens for messages from the server.
  final ReceivePort receivePort = new ReceivePort();

  /// The remote server to connect to.
  final SendPort server;

  IsolateClient(this.server);

  @override
  Stream<Tuple2<String, dynamic>> get onBroadcast => _onBroadcast.stream;

  @override
  Future connect({Duration timeout}) {
    receivePort.listen(_handleMessage);

    if (timeout != null) {
      _connectTimer = new Timer(timeout, () {
        if (!_connect.isCompleted) {
          _connect.completeError(new TimeoutException(
              'Connect timeout of ${timeout.inMilliseconds}ms exceeded',
              timeout));
        }
      });
    }

    server.send(receivePort.sendPort);
    return _connect.future;
  }

  Future close() async {
    receivePort.close();
    _onBroadcast.close();
    _awaiting.values.forEach((c) => c.completeError(
        new StateError('The client was closed before the request completed.')));
    _timers.values.forEach((t) => t.cancel());
  }

  void _send(RequestImpl request, Completer c, Duration timeout) {
    if (!_connect.isCompleted)
      throw new StateError(
          'Cannot send messages before the client has connected.');
    request.id = _uuid.v4();
    server.send([_id, request.toJson()]);

    if (timeout != null) {
      new Timer(timeout, () {
        if (!c.isCompleted) {
          c.completeError(new TimeoutException(
              'Timeout of ${timeout.inMilliseconds}ms exceeded', timeout));
        }
      });
    }

    _awaiting[request.id] = c;
  }

  void _handleMessage(data) {
    if (data is String && !_connect.isCompleted) {
      _connectTimer?.cancel();
      _connect.complete(_id = data);
    } else if (data is Map) {
      var response = ResponseImpl.parse(data);
      _handleResponse(response);
    }
  }

  void _handleResponse(Response response) {
    if (response.statusCode == status.BROADCAST) {
      if (response.body['key'] is String &&
          response.body.containsKey('value')) {
        _onBroadcast.add(new Tuple2<String, dynamic>(
            response.body['key'], response.body['value']));
      } else
        _onBroadcast.addError(new CherubimException(
            'The server reported a broadcasted message, but did not provide both a key and value.'));
    }

    if (_awaiting.containsKey(response.requestId)) {
      var completer = _awaiting.remove(response.requestId);
      if (completer.isCompleted)
        return;
      else if (_timers.containsKey(response.requestId)) {
        var timer = _timers.remove(response.requestId);
        timer.cancel();
      }

      var errorMessage = response.metaData['message'];
      switch (response.statusCode) {
        case status.OK:
          if (!response.body.containsKey('result'))
            completer.completeError(new CherubimException(errorMessage ??
                'The server reported a successful operation, but did not return any value.'));
          completer.complete(JSON.decode(response.body['result']));
          break;
        case status.CREATED:
          completer.complete(true);
          break;
        case status.FOUND:
          completer.complete(true);
          break;
        case status.MALFORMED:
          completer.completeError(new CherubimException(errorMessage ??
              'Your request was malformed, and thus the server refused to process it.'));
          break;
        case status.NO_SUCH_KEY:
          completer.completeError(
              errorMessage ?? 'You tried to read or write a nonexistent key.');
          break;
        case status.NOT_FOUND:
          completer.complete(false);
          break;
        case status.SERVER_ERROR:
          completer.completeError(new CherubimException(
              errorMessage ?? 'An internal server error occurred.'));
          break;
        default:
          completer.completeError(new CherubimException(
              'Invalid response status code: ${response.statusCode}'));
          break;
      }
    }
  }

  @override
  Future<T> pull<T>(String key, {Duration timeout}) {
    var c = new Completer<T>();
    _send(new RequestImpl(method: method.GET, metaData: {'key': key}), c,
        timeout);
    return c.future;
  }

  @override
  Future<bool> push<T>(String key, T value, {Duration timeout}) {
    var c = new Completer<T>();
    _send(
        new RequestImpl(
            method: method.SET, metaData: {'key': key, 'value': value}),
        c,
        timeout);
    return c.future;
  }

  @override
  Future<bool> exists(String key, {Duration timeout}) {
    var c = new Completer<bool>();
    _send(new RequestImpl(method: method.EXISTS, metaData: {'key': key}), c,
        timeout);
    return c.future;
  }

  @override
  Future<T> delete<T>(String key, {Duration timeout}) {
    var c = new Completer<T>();
    _send(new RequestImpl(method: method.DELETE, metaData: {'key': key}), c,
        timeout);
    return c.future;
  }

  @override
  Future<T> increment<T>(String key, {Duration timeout}) {
    var c = new Completer<T>();
    _send(new RequestImpl(method: method.INCREMENT, metaData: {'key': key}), c,
        timeout);
    return c.future;
  }

  @override
  Future<T> decrement<T>(String key, {Duration timeout}) {
    var c = new Completer<T>();
    _send(new RequestImpl(method: method.DECREMENT, metaData: {'key': key}), c,
        timeout);
    return c.future;
  }

  @override
  Future<List<T>> add<T>(String key, T value, {Duration timeout}) {
    var c = new Completer<List<T>>();
    _send(
        new RequestImpl(
            method: method.LIST_ADD, metaData: {'key': key, 'value': value}),
        c,
        timeout);
    return c.future;
  }

  @override
  Future<List<T>> remove<T>(String key, T value, {Duration timeout}) {
    var c = new Completer<List<T>>();
    _send(
        new RequestImpl(
            method: method.LIST_REMOVE, metaData: {'key': key, 'value': value}),
        c,
        timeout);
    return c.future;
  }
}
