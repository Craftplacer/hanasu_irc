import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanasu_irc/irc/irc.dart';
import 'package:hanasu_irc/irc/src/events/channel_membership.dart';
import 'package:hanasu_irc/irc/src/events/message.dart';
import 'package:hanasu_irc/irc/src/raw/constants.dart';
import 'package:hanasu_irc/irc/src/raw/message.dart';

final serverManagerProvider = ChangeNotifierProvider((_) => ServerManager());

class ServerManager extends ChangeNotifier {
  List<Server> servers = [];

  void addServer(Server server) {
    servers.add(server);
    notifyListeners();
  }
}

class Server extends ChangeNotifier {
  final IrcClient client;
  final String host;
  List<Channel> channels = [];

  Server(
    this.client,
    this.host,
  ) {
    client.onJoin.listen((event) {
      if (event.source.nickname != client.nickname) return;
      if (channels.any((e) => e.name == event.channel)) return;

      final channel = Channel(this, event.channel);
      channels.add(channel);
      notifyListeners();
    });

    client.onPart.listen((event) {
      if (event.source.nickname != client.nickname) return;
      final index = channels.indexWhere((e) => e.name == event.channel);
      channels.removeAt(index);
      notifyListeners();
    });
  }

  Future<void> joinChannel(String name) async {
    await client.joinChannel(name);
  }
}

class DirectChat extends ChangeNotifier {
  final Server server;
  final String nickname;

  late final ChatController messages;

  DirectChat(this.server, this.nickname) {
    final source = IrcSource(nickname);
    messages = ChatController.ofUser(server, source);
  }
}

class Channel extends ChangeNotifier {
  final Server server;
  final String name;
  String? topic;
  late final ChatController messages;

  Channel(this.server, this.name, {this.topic}) {
    messages = ChatController.ofChannel(server, name);
  }
}

class ChatController extends ChangeNotifier {
  final Server _server;
  final String? target;
  final IrcSource? source;

  final List<RawIrcMessage> messages = [];

  ChatController.ofUser(this._server, IrcSource this.source) : target = null {
    _server.client.onMessage.listen(_onMessage);
  }

  ChatController.ofChannel(this._server, String this.target) : source = null {
    _server.client.onMessage.listen(_onMessage);
    _server.client.onJoin.listen(_onMembershipEvent);
    _server.client.onPart.listen(_onMembershipEvent);
  }

  bool _shouldDropEvent(IrcMessageEvent event) {
    if (target != null) return event.target != target;

    final source = this.source;
    if (source != null) {
      return !event.source.matches(source) || event.target != source.nickname;
    }

    throw StateError("Should not reach here");
  }

  void _onMessage(IrcMessageEvent event) {
    if (_shouldDropEvent(event)) return;
    messages.add(event.raw);
    notifyListeners();
  }

  Future<void> sendMessage(String message) async {
    final messageTarget = (target ?? source?.nickname)!;
    await _server.client.sendMessage(messageTarget, message);
    messages.add(
      RawIrcMessage(
        IrcCommand.privMsg,
        source: IrcSource(_server.client.nickname),
        parameters: [
          messageTarget,
          message,
        ],
      ),
    );
    notifyListeners();
  }

  void _onMembershipEvent(IrcChannelMembershipEvent event) {
    if (event.channel != target) return;
    messages.add(event.raw);
    notifyListeners();
  }
}
