# cherubim
Lightweight caching system for Dart. Cherubim is capable of operation across
both isolates, TCP sockets, WebSockets, and HTTP alike.

Use `cherubim` to maintain a shared state among multiple instances of an
application.

Supports:
* get/set, increment/decrement, etc.
* broadcast
* persisting to a file
* authentication+authorization

# Usage
There is only one `Server` class; however, there are multiple `Adapter` classes.
An adapter does just what its name says - it adapts input from an arbitrary source into
a stream of [Cherubim protocol](../PROTOCOL.md) requests. The following adapters are available:
* [x] Isolate messaging (`SendPort` and `ReceivePort`)
* [ ] TCP Sockets
* [ ] WebSockets
* [ ] REST

```dart
main() async {
  // Instantiate the desired adapter. You can add multiple.
  var isolateAdapter = new cherubim.IsolateAdapter();
  
  // Create a server.
  var server = new cherubim.Server(adapters: [isolateAdapter]);
  
  // Change the concurrency. Default: 1. Beware race conditions.
  var server = new cherubim.Server(adapters: [isolateAdapter], concurrency: 4);
  
  // Start listening.
  server.start();
  
  // Broadcast a message.
  server.broadcast('foo', {'bar': 'baz'});
  
  // You can query the server, from the server-side.
  //
  // Note: this is not controlled by the mutex.
  if (server.store.exists('quux')) {
    // Do something...
  }
  
  // Close the server.
  await server.close();
}
```

# Querying
A query key can look like:
* `foo` - Request the value of `foo`
* `foo.bar` - Request the value of the key `bar` within the map `foo`
* `foo.2` - Request the value of third item within the list `foo`
* `foo.2.bar.baz.0.quux` - These can be nested!!!s