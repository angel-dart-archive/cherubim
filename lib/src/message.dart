class Message {
  final Map<String, dynamic> header = {};
  final Map<String, dynamic> body = {};

  Message(
      {Map<String, dynamic> header: const {},
      Map<String, dynamic> body: const {}}) {
    this.header.addAll(header ?? {});
    this.body.addAll(body ?? {});
  }

  factory Message.fromJson(Map<String, dynamic> data) =>
      new Message(header: data['header'], body: data['body']);

  Map<String, dynamic> toJson() {
    return {'header': header, 'body': body};
  }
}
