import 'package:hanasu_irc/irc/src/raw/message_codec.dart';

class RawIrcMessage {
  final IrcSource? source;
  final String command;
  final List<String> parameters;
  final Map<IrcTagKey, String?> tags;

  const RawIrcMessage(
    this.command, {
    this.parameters = const [],
    this.tags = const {},
    this.source,
  });

  factory RawIrcMessage.fromString(String input) {
    return const IrcMessageDecoder().convert(input);
  }

  @override
  String toString() => const IrcMessageEncoder().convert(this);
}

class IrcTagKey {
  final bool clientOnly;
  final String? vendor;
  final String name;

  static const _clientPrefix = "+";
  static const _vendorSuffix = "/";

  const IrcTagKey(this.name, {this.vendor, this.clientOnly = false});

  factory IrcTagKey.fromString(String input) {
    bool clientOnly = false;

    int i = 0;

    if (input[i] == _clientPrefix) {
      clientOnly = true;
      i++;
    }

    String? vendor;
    final vendorSplit = input.substring(i).split(_vendorSuffix);
    if (vendorSplit.length >= 2) {
      vendor = vendorSplit.first;
      i += vendor.length;
    }

    final name = input.substring(i);
    return IrcTagKey(name, vendor: vendor, clientOnly: clientOnly);
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    if (clientOnly) buffer.write(_clientPrefix);

    if (vendor != null) {
      buffer.write(vendor);
      buffer.write(_vendorSuffix);
    }

    buffer.write(name);

    return buffer.toString();
  }
}

class IrcSource {
  final String nickname;
  final String? user;
  final String? host;

  const IrcSource(this.nickname, [this.user, this.host]);

  factory IrcSource.fromString(String source) {
    final userSplit = source.split("!");

    final nickname = userSplit[0];

    String? user, host;

    if (userSplit.length == 2) {
      final hostSplit = userSplit[1].split("@");
      if (hostSplit.length == 2) {
        user = hostSplit[0];
        host = hostSplit[1];
      } else {
        user = userSplit[1];
      }
    }

    return IrcSource(nickname, user, host);
  }

  @override
  String toString() {
    final buffer = StringBuffer(nickname);
    if (user != null) buffer.writeAll(["!", user]);
    if (host != null) buffer.writeAll(["@", host]);
    return buffer.toString();
  }

  bool matches(IrcSource other) {
    return nickname == other.nickname &&
        (user == null || user == other.user) &&
        (host == null || host == other.host);
  }
}
