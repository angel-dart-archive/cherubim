import 'dart:async';

abstract class BaseClient {
  String get id;

  Future<String> connect();

  Future get(String store, String key, {Duration timeout});

  Future set(String store, String key, value, {Duration timeout});
}
