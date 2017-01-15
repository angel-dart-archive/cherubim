import 'package:cherubim/cherubim.dart';
import 'package:cherubim/isolate.dart';

main() async {
  var server = new Server(debug: true);
  var client = new Client(await serve(server));
  await client.connect();

  var result = await client.set('hello', 'foo', 'bar');
  print(result);
}
