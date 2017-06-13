# cherubim
Lightweight caching system for Dart. Cherubim is capable of operation across
both isolates, TCP sockets, and HTTP alike.

Use `cherubim` to maintain a shared state among multiple instances of an
application.

Supports:
* get/set, increment/decrement, etc.
* broadcast
* persisting to a file
* authentication+authorization