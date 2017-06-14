import 'dart:async';
import 'package:tuple/tuple.dart';
import 'request.dart';
import 'response.dart';
import 'user.dart';

/// Processes messages from an external source, and organizes them into representations of users.
abstract class Adapter {
  /// A stream of requests users accessing the server.
  Stream<Tuple2<User, Request>> get onRequest;

  /// Sends a response to all users simultaneously.
  void broadcast(Response response);

  /// Starts listening for messages.
  void start();

  /// Shuts this adapter down.
  Future close();
}