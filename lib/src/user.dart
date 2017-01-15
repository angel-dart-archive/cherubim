import 'dart:async';
import 'endpoint.dart';
import 'message.dart';

abstract class User {
  String get id;
  Endpoint get endpoint;
  Stream<Message> get onMessage;
}