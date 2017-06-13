import 'response.dart';

/// Represents a client trying to access the server.
abstract class User {
  /// Sends a [response] to the user.
  void send(Response response);
}
