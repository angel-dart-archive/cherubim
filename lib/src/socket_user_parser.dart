import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cherubim/src/message.dart';
import 'package:cherubim/src/endpoint.dart';
import 'package:uuid/uuid.dart';
import 'message_parser.dart';
import 'user.dart';

class SocketUserParser implements StreamTransformer<Socket, User> {
  final Uuid _uuid = new Uuid();

  @override
  Stream<User> bind(Stream<Socket> stream) {
    var ctrl = new StreamController();

    stream.listen((socket) {
      var user = new _SocketUserImpl(
          socket, new Endpoint.fromSocket(socket), _uuid.v4());
      ctrl.add(user);
    })
      ..onDone(ctrl.close)
      ..onError(ctrl.addError);

    return ctrl.stream;
  }
}

class _SocketUserImpl implements User {
  Stream<Message> _onMessage;

  @override
  final Endpoint endpoint;

  @override
  final String id;

  @override
  Stream<Message> get onMessage => _onMessage;

  _SocketUserImpl(Socket socket, this.endpoint, this.id) {
    var parser = new MessageParser();
    _onMessage = socket
        .transform(UTF8.decoder)
        .transform(JSON.decoder)
        .transform(parser);
  }
}
