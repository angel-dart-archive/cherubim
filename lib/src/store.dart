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
      } else
        search = search[sub];
    }

    return search[split[split.length - 1]] = value;
  }

  delete(String key) {
    Map search = _state;
    var split = key.split('.');

    for (int i = 0; i < split.length - 1; i++) {
      var sub = split[i];
      if (!search.containsKey(sub) || search[sub] is! Map) return null;
      search = search[sub];
    }

    return search.remove(split[split.length - 1]);
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

  increment(String key) {
    var cur = get(key);
    if (cur is int) return set(key, cur + 1);
    return set(key, 1);
  }

  decrement(String key) {
    var cur = get(key);
    if (cur is int) return set(key, cur - 1);
    return set(key, 1);
  }

  listAdd(String key, value) {
    var cur = get(key);
    if (cur is List)
      return cur..add(value);
    else
      return set(key, [value]);
  }

  listRemove(String key, value) {
    var cur = get(key);
    if (cur is List) {
      if (value is Map) {
        var removed = null;

        for (int i = 0; i < cur.length; i++) {
          var v = cur[i];
          if (v is Map) {
            // `value` doesn't have to complete match the removed value,
            // but all the provided values must match.
            if (value.isNotEmpty && value.keys.every((k) => value[k] == v[k])) {
              removed = cur.removeAt(i);
              break;
            }
          }
        }

        return removed;
      } else
        return cur..remove(value);
    } else
      return set(key, []);
  }
}
