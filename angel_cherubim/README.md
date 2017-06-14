# angel_cherubim
Cherubim-powered services for the Angel framework.
Finally, you can keep a service in perfect sync across
multiple instances of an application.

# Usage
```dart
import 'dart:isolate';
import 'package:angel_cherubim/angel_cherubim.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:cherubim/isolate_client.dart';

// Pseudo-code plug-in
AngelConfigurer connectCherubim(SendPort serverPort) {
  return (Angel app) async {
    var client = new cherubim.IsolateClient(serverPort);
    await client.connect(timeout: new Duration(seconds: 30));
    
    app.use('/api/todos', new CherubimService(client, 'todos'));
  };
}
```