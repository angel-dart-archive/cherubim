import 'dart:io';
import 'dart:isolate';

final RegExp _endpoint =
    new RegExp(r'(([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)):([0-9]+)');

class Endpoint {
  final InternetAddress address;
  final int port;
  final Isolate isolate;

  Endpoint(this.address, this.port, {this.isolate});

  factory Endpoint.fromIsolate(Isolate isolate) =>
      new Endpoint(null, null, isolate: isolate);

  factory Endpoint.fromSocket(Socket socket) =>
      new Endpoint(socket.remoteAddress, socket.remotePort);

  /// Parses an endpoint from an `IP:port` string.
  factory Endpoint.parse(String endpoint) {
    var match = _endpoint.firstMatch(endpoint);

    if (match == null)
      throw new ArgumentError(
          'Invalid endpoint string. Expected IP:port format.');

    return new Endpoint(new InternetAddress(match[1]), int.parse(match[2]));
  }

  @override
  String toString() => '${address.address}:$port';
}
