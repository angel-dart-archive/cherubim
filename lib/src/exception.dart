class CherubimException implements Exception {
  final String message;

  CherubimException(this.message);

  @override
  String toString() => 'Cherubim exception: $message';
}