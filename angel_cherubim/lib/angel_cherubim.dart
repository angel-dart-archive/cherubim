import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:cherubim/cherubim.dart' as cherubim;

class CherubimService extends Service {
  final cherubim.Client client;
  final String key;

  CherubimService(this.client, this.key);

  @override
  Future index([Map params]) => client.pull(key);
}