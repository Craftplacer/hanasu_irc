import 'dart:async';

import 'package:collection/collection.dart';
import 'package:hanasu_irc/irc/src/events/channel_membership.dart';
import 'package:hanasu_irc/irc/src/events/message.dart';
import 'package:hanasu_irc/irc/src/exceptions/authentication.dart';
import 'package:hanasu_irc/irc/src/raw/client.dart';
import 'package:hanasu_irc/irc/src/raw/constants.dart';
import 'package:hanasu_irc/irc/src/raw/message.dart';
import 'package:logging/logging.dart';

const _endCapabilityNegotiation = RawIrcMessage("CAP", parameters: ["END"]);
const _listCapabilities = RawIrcMessage("CAP", parameters: ["LS", "302"]);

Map<String, String?> _parseCapabilities(String capabilities) {
  final entries = capabilities
      .split(" ")
      .map((e) => e.split("="))
      .map((e) => MapEntry(e[0], e.elementAtOrNull(1)));

  return Map.fromEntries(entries);
}

/// Feature-implementing IRC client.
class IrcClient {
  final _log = Logger('IrcClient');

  static const supportedCapabilities = {};

  final RawIrcClient rawClient = RawIrcClient();

  final Map<String, String?> _capabilities = {};

  final _onJoinController =
      StreamController<IrcChannelMembershipEvent>.broadcast();

  final _onMessageController = StreamController<IrcMessageEvent>.broadcast();

  final _onPartController =
      StreamController<IrcChannelMembershipEvent>.broadcast();

  String _nickname;

  String? username;

  String? realname;

  IrcClient({
    required String nickname,
    this.realname,
    this.username,
  }) : _nickname = nickname {
    rawClient.listen(_onMessage);
  }

  /// The capabilities supported by the server.
  Map<String, String?> get capabilities => _capabilities;

  String get nickname => _nickname;

  set nickname(String value) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, "nickname", "cannot be empty");
    }

    _nickname = value;
  }

  Stream<IrcChannelMembershipEvent> get onJoin => _onJoinController.stream;

  Stream<IrcChannelMembershipEvent> get onPart => _onPartController.stream;

  Stream<IrcMessageEvent> get onMessage => _onMessageController.stream;

  Future<void> authenticateAsOperator(String password) async {
    await rawClient.send(
      RawIrcMessage(IrcCommand.oper, parameters: [password]),
    );

    final response = await rawClient.firstWhereCommand([
      IrcReply.youreOper,
      IrcError.passwdMismatch,
      IrcError.noOperHost,
    ]);

    switch (response.command) {
      case IrcReply.youreOper:
        return;
      case IrcError.passwdMismatch:
        throw IrcAuthenticationException("password mismatch");
      case IrcError.noOperHost:
        throw IrcAuthenticationException("no oper host");
      default:
        throw IrcAuthenticationException("unknown error");
    }
  }

  Stream<Object> connect(
    String host, [
    int? port,
    String? password,
    ConnectionType type = ConnectionType.plain,
  ]) async* {
    await rawClient.connect(host, port, type);

    yield RegistrationState.registration;

    await rawClient.send(_listCapabilities);

    if (password != null) {
      await rawClient.send(RawIrcMessage("PASS", parameters: [password]));
    }

    await rawClient.send(RawIrcMessage("NICK", parameters: [nickname]));

    final username = this.username ?? nickname;
    final realname = this.realname ?? username;

    await rawClient.send(
      RawIrcMessage("USER", parameters: [username, "0", "*", realname]),
    );

    final response = await rawClient.firstWhereCommand([
      IrcCommand.cap,
      IrcReply.welcome,
      IrcError.alreadyRegistered,
      IrcError.nicknameInUse,
      IrcError.erroneusNickname,
      IrcError.nickCollision,
    ]);

    if (response.command == IrcCommand.cap) {
      yield RegistrationState.capabilityNegotiation;
      await _negotiateCapabilities(response);
    }

    switch (response.command) {
      case IrcReply.welcome:
        yield response.parameters.first;
        return;

      case IrcError.nicknameInUse:
        throw IrcAuthenticationException("nickname in use");
      case IrcError.erroneusNickname:
        throw IrcAuthenticationException("erroneous nickname");
      case IrcError.nickCollision:
        throw IrcAuthenticationException("nickname collision");
      case IrcError.noNicknameGiven:
        throw IrcAuthenticationException("no nickname given");
      default:
        return;
    }
  }

  Future<void> _negotiateCapabilities(RawIrcMessage response) async {
    var capabilities = _parseCapabilities(response.parameters[2]);

    final recognizedCapabilities = capabilities.keys
        .where((e) => supportedCapabilities.containsKey(e))
        .toList();

    if (recognizedCapabilities.isNotEmpty) {
      await rawClient.send(
        RawIrcMessage(
          "CAP",
          parameters: ["REQ", recognizedCapabilities.join(" ")],
        ),
      );
    }

    await rawClient.send(_endCapabilityNegotiation);
  }

  Stream<IrcListChannel> listChannels() async* {
    const request = RawIrcMessage(IrcCommand.list);
    await rawClient.send(request);

    yield* rawClient
        .where(
          (e) => e.command == IrcReply.list || e.command == IrcReply.listEnd,
        )
        .takeWhile((e) => e.command != IrcReply.listEnd)
        .map(IrcListChannel.fromMessage);
  }

  Stream<IrcChannelMemberships> getNames(String channel) async* {
    final request = RawIrcMessage(IrcCommand.names, parameters: [channel]);
    await rawClient.send(request);

    yield* rawClient
        .where(
          (e) =>
              e.command == IrcReply.namReply ||
              e.command == IrcReply.endOfNames,
        )
        .takeWhile((e) => e.command != IrcReply.endOfNames)
        .map(IrcChannelMemberships.fromMessage);
  }

  void _onMessage(RawIrcMessage message) {
    _log.finest(message);
    switch (message.command) {
      case IrcCommand.ping:
        rawClient.send(
          RawIrcMessage(IrcCommand.pong, parameters: message.parameters),
        );
        break;

      case IrcCommand.notice:
      case IrcReply.yourHost:
        break;

      case IrcCommand.join:
      case IrcCommand.part:
        final event = IrcChannelMembershipEvent.fromMessage(message);

        if (message.command == IrcCommand.join) {
          _onJoinController.add(event);
        } else if (message.command == IrcCommand.part) {
          _onPartController.add(event);
        } else {
          assert(false, "Unhandled command");
        }

        break;

      case IrcCommand.privMsg:
        _onMessageController.add(IrcMessageEvent.fromMessage(message));
        break;
    }
  }

  Future<void> joinChannel(String name) async {
    await rawClient.send(RawIrcMessage(IrcCommand.join, parameters: [name]));
    await rawClient.any(
      (e) => e.command == IrcCommand.join && e.source!.nickname == nickname,
    );
  }

  Future<void> sendMessage(String target, String message) async {
    await rawClient.send(
      RawIrcMessage(
        IrcCommand.privMsg,
        parameters: [target, message],
      ),
    );
  }
}

class IrcListChannel {
  final String name;
  final int clients;
  final String? topic;

  const IrcListChannel(this.name, this.clients, this.topic);

  factory IrcListChannel.fromMessage(RawIrcMessage message) {
    assert(message.command == IrcReply.list);
    return IrcListChannel(
      message.parameters[1],
      int.parse(message.parameters[2]),
      message.parameters.length >= 4 ? message.parameters[3] : null,
    );
  }
}

/// Represents the state of the registration process.
enum RegistrationState {
  capabilityNegotiation,
  authentication,
  registration,
}

class IrcChannelMemberships {
  final String channel;
  final List<String> channelPrefixes;
  final List<String> nicknames;

  const IrcChannelMemberships(
    this.channel,
    this.channelPrefixes,
    this.nicknames,
  );

  factory IrcChannelMemberships.fromMessage(RawIrcMessage message) {
    assert(message.command == IrcReply.namReply);
    final channelPrefixes = message.parameters[1].split("");
    final channel = message.parameters[2];
    final nicknames = message.parameters[3].split(" ");

    return IrcChannelMemberships(channel, channelPrefixes, nicknames);
  }
}
