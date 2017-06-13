void applyMap(Map to, Map from) {
  from.forEach((k, v) {
    if (k is String) {
      to[k] = v.toString();
    }
  });
}
