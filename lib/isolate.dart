library cherubim.isolate;

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:cherubim/cherubim.dart';
import 'package:cherubim/src/client.dart';
import 'package:cherubim/src/constants.dart' as constants;
import 'package:uuid/uuid.dart';

class Client extends BaseClient {
  String _id;
  String get id => _id;

  final Map<String, Completer> _waiting = {};
  final SendPort _serverPort;
  final ReceivePort _recv = new ReceivePort();
  final Uuid _uuid = new Uuid();

  Client(this._serverPort);

  @override
  connect() {
    var c = new Completer();

    _recv.listen((data) {
      if (data is List &&
          data.length >= 2 &&
          data[0] == 0 &&
          data[1] is String) {
        if (!c.isCompleted) c.complete(_id = data[1]);
      } else if (data is String) {
        var message = new Message.fromJson(JSON.decode(data));

        if (message.header.containsKey(constants.RETURN_ID)) {
          var returnId = message.header[constants.RETURN_ID];

          if (_waiting.containsKey(returnId)) {
            var c = _waiting[returnId];
            _waiting.remove(returnId);
            c.complete(message.body['result']);
          }
        }
      }
    });

    _serverPort.send(_recv.sendPort);
    return c.future;
  }

  @override
  Future get(String store, String key, {Duration timeout}) {
    var c = new Completer();
    var returnId = _uuid.v4();
    _waiting[returnId] = c;

    var message = new Message(header: {
      constants.VERSION: constants.CURRENT_VERSION,
      constants.METHOD: constants.GET,
      constants.RETURN_ID: returnId
    }, body: {
      constants.STORE: store,
      constants.KEY: key
    });

    _serverPort.send([id, JSON.encode(message)]);

    if (timeout != null) {
      new Future.delayed(timeout).then((_) {
        _waiting.remove(returnId);
        c.completeError(
            new TimeoutException('Timeout of ${timeout} exceeded', timeout));
      });
    }

    return c.future;
  }

  @override
  Future set(String store, String key, value, {Duration timeout}) {
    var c = new Completer();
    var returnId = _uuid.v4();
    _waiting[returnId] = c;

    var message = new Message(header: {
      constants.VERSION: constants.CURRENT_VERSION,
      constants.METHOD: constants.SET,
      constants.RETURN_ID: returnId
    }, body: {
      constants.STORE: store,
      constants.KEY: key,
      constants.VALUE: value
    });

    _serverPort.send([id, JSON.encode(message)]);

    if (timeout != null) {
      new Future.delayed(timeout).then((_) {
        _waiting.remove(returnId);
        c.completeError(
            new TimeoutException('Timeout of ${timeout} exceeded', timeout));
      });
    }

    return c.future;
  }
}

Future<SendPort> serve(Server server, {bool broadcast: true}) async {
  var uuid = new Uuid();
  List<SendPort> ports = [];
  List<_IsolateUserImpl> users = [];
  var ctrl = new StreamController<User>();
  var recv = new ReceivePort();

  recv.listen((data) {
    if (data is SendPort) {
      var user = new _IsolateUserImpl(uuid.v4());
      ports.add(data..send([0, user.id]));
      users.add(user);
      ctrl.add(user);
    } else if (data is List &&
        data.length >= 2 &&
        data[0] is String &&
        data[1] is String) {
      if (data[0].isNotEmpty) {
        var user = users.firstWhere((u) => u.id == data[0], orElse: () => null);

        if (user != null) {
          user._onMessage.add(new Message.fromJson(JSON.decode(data[1])));
        }
      }
    } else {
      throw new ArgumentError('Invalid data sent to Cherubim: $data');
    }
  })
    ..onDone(ctrl.close)
    ..onError(ctrl.addError);

  ctrl.stream.pipe(server);

  if (broadcast == true) {
    server.onBroadcast.listen((message) {
      for (var port in ports) {
        port.send(JSON.encode(message));
      }
    });
  }

  return recv.sendPort;
}

class _IsolateUserImpl implements User {
  Endpoint _endpoint;
  final StreamController<Message> _onMessage = new StreamController<Message>();

  _IsolateUserImpl(this.id);

  @override
  Endpoint get endpoint => _endpoint;

  @override
  final String id;

  @override
  Stream<Message> get onMessage => _onMessage.stream;
}
