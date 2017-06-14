import 'dart:async';
import 'dart:convert';
import 'package:pool/pool.dart';
import 'adapter.dart';
import 'request.dart';
import 'request_method.dart' as method;
import 'response.dart';
import 'response_impl.dart';
import 'response_status.dart' as status;
import 'store.dart';
import 'user.dart';

/// A lightweight caching system for Dart.
class Server {
  final List<Adapter> _adapters = [];
  Pool _pool;
  bool _running = false;
  final Store _store = new Store();

  /// Initializes a Cherubim server.
  ///
  /// You can provide any number of [adapters].
  /// Requests will be mutually excluded at the given [concurrency] (default: `1`).
  Server({Iterable<Adapter> adapters: const [], int concurrency}) {
    _adapters.addAll(adapters ?? []);
    _pool = new Pool(concurrency ?? 1);
  }

  /// Shuts down the server, along with any of its adapters.
  Future close() async {
    await Future.wait(_adapters.map((a) => a.close()));
  }

  /// Starts the server listening.
  void start() {
    _running = true;
    _adapters.forEach(_listenToAdapter);
  }

  /// Adds an adapter, after the server has already started.
  void addAdapter(Adapter adapter) {
    if (!_running)
      throw new StateError(
          'You cannot use `addAdapter()` until the server has started listening.');
    _adapters.add(adapter);
    _listenToAdapter(adapter);
  }

  _listenToAdapter(Adapter adapter) {
    adapter.start();
    adapter.onRequest.listen((t) => handleRequest(t.item2, t.item1));
  }

  /// Handles an incoming [request] from a specific [user].
  Future handleRequest(Request request, User user) async {
    var resx = await _pool.request();

    void sendMalformed() {
      user.send(new ResponseImpl(
          statusCode: status.MALFORMED, requestId: request.id));
    }

    try {
      // TODO: Authorization
      switch (request.method) {
        case method.GET:
          if (request.metaData['key'] is String) {
            var key = request.metaData['key'];
            user.send(new ResponseImpl(
                statusCode: status.OK,
                requestId: request.id,
                body: {'result': JSON.encode(_store.get(key))}));
          } else
            sendMalformed();
          break;
        case method.SET:
          if (request.metaData['key'] is String &&
              request.metaData.containsKey('value')) {
            var key = request.metaData['key'];
            var value = request.metaData['value'];
            user.send(new ResponseImpl(
                statusCode: status.OK,
                requestId: request.id,
                body: {'result': JSON.encode(_store.set(key, value))}));
          } else
            sendMalformed();
          break;
        case method.EXISTS:
          if (request.metaData['key'] is String) {
            var key = request.metaData['key'];
            user.send(new ResponseImpl(
                statusCode:
                    _store.exists(key) ? status.FOUND : status.NOT_FOUND,
                requestId: request.id));
          } else
            sendMalformed();
          break;
        case method.INCREMENT:
          if (request.metaData['key'] is String) {
            var key = request.metaData['key'];
            user.send(new ResponseImpl(
                statusCode: status.OK,
                requestId: request.id,
                body: {'result': JSON.encode(_store.increment(key))}));
          } else
            sendMalformed();
          break;
        case method.DECREMENT:
          if (request.metaData['key'] is String) {
            var key = request.metaData['key'];
            user.send(new ResponseImpl(
                statusCode: status.OK,
                requestId: request.id,
                body: {'result': JSON.encode(_store.decrement(key))}));
          } else
            sendMalformed();
          break;
        case method.DELETE:
          if (request.metaData['key'] is String) {
            var key = request.metaData['key'];
            user.send(new ResponseImpl(
                statusCode: status.OK,
                requestId: request.id,
                body: {'result': JSON.encode(_store.delete(key))}));
          } else
            sendMalformed();
          break;
        case method.LIST_ADD:
          if (request.metaData['key'] is String &&
              request.metaData.containsKey('value')) {
            var key = request.metaData['key'];
            var value = request.metaData['value'];
            user.send(new ResponseImpl(
                statusCode: status.OK,
                requestId: request.id,
                body: {'result': JSON.encode(_store.listAdd(key, value))}));
          } else
            sendMalformed();
          break;
        case method.LIST_REMOVE:
          if (request.metaData['key'] is String &&
              request.metaData.containsKey('value')) {
            var key = request.metaData['key'];
            var value = request.metaData['value'];
            user.send(new ResponseImpl(
                statusCode: status.OK,
                requestId: request.id,
                body: {'result': JSON.encode(_store.listRemove(key, value))}));
          } else
            sendMalformed();
          break;
        default:
          sendMalformed();
          break;
      }
    } on ResponseImpl catch (response) {
      user.send(response..requestId = request.id);
    } on RangeError {
      user.send(new ResponseImpl(
          statusCode: status.MALFORMED,
          requestId: request.id,
          metaData: {'message': 'Index out of range.'}));
    } catch (e) {
      user.send(new ResponseImpl(
          statusCode: status.SERVER_ERROR, requestId: request.id));
    } finally {
      resx.release();
    }
  }

  /// Sends a real-time message to all connected clients.
  void broadcast(String key, value) {
    var response = new ResponseImpl(
        statusCode: status.BROADCAST, body: {'key': key, 'value': value});
    _adapters.forEach((a) => a.broadcast(response));
  }
}
