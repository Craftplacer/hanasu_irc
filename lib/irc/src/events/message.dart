import 'package:hanasu_irc/irc/src/events/event.dart';
import 'package:hanasu_irc/irc/src/raw/message.dart';

/// An event that is fired when the client receives a message.
class IrcMessageEvent extends IrcEvent {
  final String target;
  final IrcSource source;
  final String message;

  factory IrcMessageEvent.fromMessage(RawIrcMessage message) {
    final targets = message.parameters[0].split(",");
    assert(targets.length == 1, "Server sent multiple targets");
    final target = targets.first;
    return IrcMessageEvent._(
      target: target,
      message: message.parameters[1],
      source: message.source!,
      raw: message,
    );
  }

  const IrcMessageEvent._({
    required this.target,
    required this.source,
    required this.message,
    required super.raw,
  });
}
