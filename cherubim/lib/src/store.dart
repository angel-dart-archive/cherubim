import 'response_impl.dart';
import 'response_status.dart' as status;

final RegExp _rgxInt = new RegExp(r'[0-9]+');

/// Stores the data within a Cherubim instance.
class Store {
  final Map<String, dynamic> _state = {};

  _resolveSearchTarget(initial, List<String> split) {
    var search = initial;
    if (split.length <= 1) return initial;

    for (int i = 0; i < split.length - 1; i++) {
      var query = split[i];
      var intMatch = _rgxInt.firstMatch(query);

      if (intMatch != null) {
        if (search is List) {
          return search[int.parse(intMatch[0])];
        } else
          throw new ResponseImpl(
              statusCode: status.MALFORMED,
              metaData: {'message': 'Cannot take numerical index of $search.'});
      } else if (search is Map) {
        if (search.containsKey(query))
          return search[query];
        else
          search = (search[query] = {});
      } else
        return null;
    }
  }

  _resolveKey(search, String key) {
    if (search == null) return null;
    var intMatch = _rgxInt.firstMatch(key);

    if (intMatch != null) {
      if (search is List) {
        return search[int.parse(intMatch[0])];
      } else
        throw new ResponseImpl(
            statusCode: status.MALFORMED,
            metaData: {'message': 'Cannot take numerical index of $search.'});
    } else if (search is Map) {
      return search[key];
    } else
      throw new ResponseImpl(
          statusCode: status.MALFORMED,
          metaData: {'message': 'Cannot take index of $search.'});
  }

  get(String key) {
    var split = key.split('.');
    var target = _resolveSearchTarget(_state, split);
    var result = _resolveKey(target, split.last);
    if (result == null) throw new ResponseImpl(statusCode: status.NO_SUCH_KEY);
    return result;
  }

  set(String key, value) {
    var split = key.split('.');
    var target = _resolveSearchTarget(_state, split);

    if (target is List)
      throw new ResponseImpl(statusCode: status.MALFORMED, metaData: {
        'message':
            'Cannot `set` keys in a list. Send a LIST_ADD request instead.'
      });
    else if (target is Map)
      return target[split.last] = value;
    else
      throw new ResponseImpl(
          statusCode: status.MALFORMED,
          metaData: {'message': 'Cannot `set` values within $target.'});
  }

  delete(String key) {
    var split = key.split('.');
    var target = _resolveSearchTarget(_state, split);

    if (target is List) {
      var query = split.last;
      var intMatch = _rgxInt.firstMatch(query);
      if (intMatch != null) {
        return target.removeAt(int.parse(intMatch[0]));
      }
      throw new ResponseImpl(
          statusCode: status.MALFORMED,
          metaData: {'message': 'Cannot remove key "$query" from a list.'});
    } else if (target is Map) {
      return target.remove(split.last);
    } else
      throw new ResponseImpl(
          statusCode: status.MALFORMED,
          metaData: {'message': 'Cannot delete entry from $target.'});
  }

  /// Returns true if the given [key] exists.
  bool exists(String key) {
    var split = key.split('.');
    var target = _resolveSearchTarget(_state, split);

    if (target is Map)
      return target.containsKey(key);
    else if (target is List) {
      var intMatch = _rgxInt.firstMatch(key);
      if (intMatch != null) {
        int n = int.parse(intMatch[0]);
        return target.isNotEmpty && n < target.length;
      }
      return target.contains(key);
    } else {
      throw new ResponseImpl(
          statusCode: status.MALFORMED,
          metaData: {'message': 'Cannot take an index of $target.'});
    }
  }

  increment(String key) {
    if (!exists(key)) {
      return set(key, 1);
    }

    var cur = get(key);
    if (cur is int) return set(key, cur + 1);
    return set(key, 1);
  }

  decrement(String key) {
    if (!exists(key)) {
      return set(key, 1);
    }

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
