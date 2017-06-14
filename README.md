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
a stream of [Cherubim protocol](PROTOCOL.md) requests. The following adapters are available:
* [x] Isolate messaging (`SendPort` and `ReceivePort`)
* [ ] TCP Sockets
* [ ] WebSockets
* [ ] REST