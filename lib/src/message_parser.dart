import 'dart:async';
import 'message.dart';

class MessageParser implements StreamTransformer<dynamic, Message> {
  @override
  Stream bind(Stream stream) {
    var ctrl = new StreamController();

    stream.listen((data) {
      if (data is Map<String, dynamic>)
        ctrl.add(new Message.fromJson(data));
      else
        throw new ArgumentError('Not a valid message: $data');
    })
      ..onDone(ctrl.close)
      ..onError(ctrl.addError);

    return ctrl.stream;
  }
}
