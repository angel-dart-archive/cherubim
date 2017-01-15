class Store {
  final Map<String, Map<String, dynamic>> _data = {};

  get(String key) {
    var search = _data;
    var split = key.split('.').where((s) => s.isNotEmpty);

    if (split.isEmpty) return null;

    for (var s in split) {
      if (search is Map)
        search = search[s];
      else
        return null;
    }
  }

  void set(String key, value) {
    var search = _data;
    var spl = key.split('.').where((s) => s.isNotEmpty);
    var split = spl.take(spl.length - 1);
    var setter = spl.last;

    if (split.isEmpty) return null;

    for (var s in split) {
      if (search is Map)
        search = search[s] ?? (search[s] = {});
      else
        return null;
    }

    if (search != null) {
      search[setter] = value;
    }
  }
}
