library cherubim.io;

import 'dart:async';
import 'dart:io';
import 'src/socket_user_parser.dart';
import 'cherubim.dart';

Future<Server> _transform<T>(
    Stream<Socket> stream) async {
  var parser = new SocketUserParser();
  Stream<User> userStream = stream.transform(parser);
  var server = new Server();
  userStream.pipe(server);
  return server;
}

Future<Server> serve(address, int port) async {
  var socket = await ServerSocket.bind(address, port);
  return await _transform(socket);
}

Future<Server> serveSecure(
    address, int port, SecurityContext securityContext) async {
  var socket = await SecureServerSocket.bind(address, port, securityContext);
  return await _transform(socket);
}
