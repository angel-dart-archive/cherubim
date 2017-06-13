/// Stores the data within a Cherubim instance.
class Store {
  final Map<String, dynamic> _state = {};

  get(String key) {
    Map search = _state;
    var split = key.split('.');

    for (int i = 0; i < split.length - 1; i++) {
      var sub = split[i];
      if (!search.containsKey(sub) || search[sub] is! Map) return null;
      search = search[sub];
    }

    return search[split[split.length - 1]];
  }

  set(String key, value) {
    Map search = _state;
    var split = key.split('.');

    for (int i = 0; i < split.length - 1; i++) {
      var sub = split[i];
      if (!search.containsKey(sub) || search[sub] is! Map) {
        search = search[sub] = {};
      } else search = search[sub];
    }

    return search[split[split.length - 1]] = value;
  }

  /// Returns true if the given [key] exists.
  bool exists(String key) {
    Map search = _state;
    var split = key.split('.');

    for (int i = 0; i < split.length - 1; i++) {
      var sub = split[i];
      if (!search.containsKey(sub) || search[sub] is! Map) return false;
      search = search[sub];
    }

    return search.containsKey(split[split.length - 1]);
  }
}
