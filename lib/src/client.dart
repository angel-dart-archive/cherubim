import 'dart:async';
import 'package:tuple/tuple.dart';

/// A class capable of querying a Cherubim server.
abstract class Client {
  /// Fired in real-time whenever the server broadcasts a message.
  Stream<Tuple2<String, dynamic>> get onBroadcast;

  /// Connects to a remote server.
  Future connect({Duration timeout});

  /// Disconnects from the remote server.
  Future close();

  /// Read the value of a key.
  Future<T> get<T>(String key, {Duration timeout});

  /// Assign a value to a key.
  Future<bool> set<T>(String key, T value, {Duration timeout});

  /// Determine if a key exists.
  Future<bool> exists(String key, {Duration timeout});

  /// Delete an entry for a key.
  Future<T> delete<T>(String key, {Duration timeout});

  /// Increment a value.
  Future<int> increment(String key, {Duration timeout});

  /// Decrement a value.
  Future<int> decrement(String key, {Duration timeout});

  /// Add to a list.
  Future<List<T>> add<T>(String key, T value, {Duration timeout});

  /// Remove from a list.
  Future<List<T>> remove<T>(String key, T value, {Duration timeout});
}
