import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'message.dart';
import 'message_codec.dart';

/// IRC protocol layer
class RawIrcClient extends Stream<RawIrcMessage> {
  late Stream<RawIrcMessage> _messageStream;
  late StreamController<RawIrcMessage> _controller;
  late Socket _socket;

  RawIrcClient() {
    _controller = StreamController<RawIrcMessage>.broadcast();
  }

  void dispose() async {
    _socket.flush();
    _socket.close();
  }

  Future<void> connect(
    String host, [
    int? port,
    ConnectionType type = ConnectionType.plain,
  ]) async {
    port ??= type.port;

    switch (type) {
      case ConnectionType.plain:
        _socket = await Socket.connect(host, port);
        break;

      case ConnectionType.ssl:
        _socket = await SecureSocket.connect(host, port);
        break;

      default:
        throw UnimplementedError();
    }

    const messageDecoder = IrcMessageDecoder();

    _messageStream = const Utf8Decoder(allowMalformed: true)
        .bind(_socket)
        .transform(const LineSplitter())
        .map(messageDecoder.convert)
        .asBroadcastStream();

    _controller.addStream(_messageStream);
  }

  Future<void> send(RawIrcMessage message) async {
    _socket
      ..write(message.toString())
      ..write("\r\n");
    await _socket.flush();
  }

  Future<RawIrcMessage> firstWhereCommand(List<String> commands) async {
    return _controller.stream.firstWhere((e) => commands.contains(e.command));
  }

  @override
  StreamSubscription<RawIrcMessage> listen(
    void Function(RawIrcMessage event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

enum ConnectionType {
  plain(6667),
  ssl(6697),
  webSocket(443);

  final int port;

  const ConnectionType(this.port);
}
