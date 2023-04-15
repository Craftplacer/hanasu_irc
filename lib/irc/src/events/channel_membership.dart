import 'package:hanasu_irc/irc/src/events/event.dart';
import 'package:hanasu_irc/irc/src/raw/message.dart';

/// An event that is fired when a user joins or parts a channel.
class IrcChannelMembershipEvent extends IrcEvent {
  final String channel;
  final IrcSource source;

  factory IrcChannelMembershipEvent.fromMessage(RawIrcMessage message) {
    final channels = message.parameters.first.split(",");
    assert(channels.length == 1, "Server sent multiple channels");
    final channel = channels.first;
    return IrcChannelMembershipEvent._(
      channel: channel,
      source: message.source!,
      raw: message,
    );
  }

  const IrcChannelMembershipEvent._({
    required this.channel,
    required this.source,
    required super.raw,
  });
}
