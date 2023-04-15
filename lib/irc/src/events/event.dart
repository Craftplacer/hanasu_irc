import 'package:hanasu_irc/irc/src/raw/message.dart';

abstract class IrcEvent {
  /// The protocol message that caused this event.
  final RawIrcMessage raw;

  const IrcEvent({required this.raw});
}
