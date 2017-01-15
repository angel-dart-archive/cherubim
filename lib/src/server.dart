import 'dart:async';
import 'package:angel_validate/angel_validate.dart';
import 'constants.dart' as constants;
import 'message.dart';
import 'user.dart';
import 'store.dart';

final Validator _getValidator = new Validator({
  '${constants.STORE}*': [isString, isNotEmpty],
  '${constants.KEY}*': [isString, isNotEmpty]
});

final Validator _getHeaderValidator = new Validator({
  '${constants.RETURN_ID}*': [isString, isNotEmpty]
});

final Validator _setValidator = new Validator({
  '${constants.STORE}*': [isString, isNotEmpty],
  '${constants.KEY}*': [isString, isNotEmpty],
  '${constants.VALUE}*': [isNotNull]
});

class Server implements StreamConsumer<User> {
  bool _closed = false;
  final StreamController<Message> _onBroadcast =
      new StreamController<Message>();
  final Map<String, Store> _stores = {};
  final bool debug;

  Stream<Message> get onBroadcast => _onBroadcast.stream;

  Server({this.debug: false});

  void printDebug(msg) {
    if (debug == true)
      print(msg);
  }

  @override
  Future addStream(Stream<User> stream) {
    if (_closed)
      throw new StateError('Server is already listening to a stream.');

    var c = new Completer();

    stream.listen(handleUser)
      ..onDone(c.complete)
      ..onError(c.completeError);

    return c.future;
  }

  @override
  Future close() async {
    _closed = true;
  }

  void handleUser(User user) {
    user.onMessage.listen((message) => handleMessage(message, user));
  }

  void handleMessage(Message message, User user) {
    printDebug('Message from user #${user.id}: ${message.toJson()}');
    
    if (message.header[constants.METHOD] == constants.GET) {
      handleGet(message, user);
    } else if (message.header[constants.METHOD] == constants.SET) {
      handleSet(message, user);
    }
  }

  Future handleGet(Message message, User user) async {
    var data = _getValidator.enforce(message.body);
    var returnId =
        _getHeaderValidator.enforce(message.body)[constants.RETURN_ID];
    String name = data['store'];
    Store store;

    if (_stores.containsKey(name))
      store = _stores[name];
    else
      store = _stores[name] = new Store();

    var result = store.get(data['key']);

    _onBroadcast.add(new Message(header: {
      constants.VERSION: constants.CURRENT_VERSION,
      constants.EVENT: constants.GET,
      constants.RETURN_ID: returnId
    }, body: {
      'result': result
    }));
  }

  Future handleSet(Message message, User user) async {
    var data = _setValidator.enforce(message.body);
    String name = data['store'];
    Store store;

    if (_stores.containsKey(name))
      store = _stores[name];
    else
      store = _stores[name] = new Store();

    store.set(data['key'], data['value']);
    var result = store.get(data['key']);

    _onBroadcast.add(new Message(header: {
      constants.VERSION: constants.CURRENT_VERSION,
      constants.EVENT: constants.SET
    }, body: {
      'result': result
    }));

    if (message.header.containsKey(constants.RETURN_ID)) {
      var returnId = message.header[constants.RETURN_ID];

      _onBroadcast.add(new Message(header: {
        constants.VERSION: constants.CURRENT_VERSION,
        constants.EVENT: constants.SET,
        constants.RETURN_ID: returnId
      }, body: {
        'result': result
      }));
    }
  }
}
