import 'package:flutter/material.dart';
import 'package:hanasu_irc/irc/src/raw/message.dart';
import 'package:intl/intl.dart';

class MessageWidget extends StatelessWidget {
  final RawIrcMessage message;

  const MessageWidget(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    final time = DateTime.now();
    switch (message.command) {
      case "PRIVMSG":
      case "NOTICE":
        return buildTextMessage(context, time);
      case "JOIN":
      case "PART":
      case "QUIT":
        return buildActionMessage(context, time);
      default:
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: _getTimeString(time),
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
              const WidgetSpan(child: SizedBox(width: 8)),
              TextSpan(
                text: message.command,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const WidgetSpan(
                child: SizedBox(width: 8),
              ),
              TextSpan(text: message.parameters.join(" ")),
            ],
          ),
        );
    }
  }

  Widget buildTextMessage(BuildContext context, DateTime time) {
    var content = message.parameters[1];
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: _getTimeString(time),
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
          const WidgetSpan(child: SizedBox(width: 8)),
          TextSpan(
            text: message.source!.nickname,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const WidgetSpan(
            child: SizedBox(width: 8),
          ),
          TextSpan(text: content),
        ],
      ),
    );
  }

  String _getTimeString(DateTime date) {
    return DateFormat.Hms().format(date);
  }

  Widget buildActionMessage(BuildContext context, DateTime time) {
    Icon? icon;
    List<InlineSpan> content = [TextSpan(text: message.parameters.join(" "))];

    switch (message.command) {
      case "JOIN":
        icon = Icon(Icons.login, color: Colors.greenAccent.shade100);
        content = [
          TextSpan(
            text: message.source!.nickname,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: " joined "),
          TextSpan(
            text: message.parameters[0],
            style: const TextStyle(fontWeight: FontWeight.bold),
          )
        ];
        break;
      case "PART":
        icon = Icon(Icons.logout, color: Colors.redAccent.shade100);
        content = [
          TextSpan(
            text: message.source!.nickname,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: " left "),
          TextSpan(
            text: message.parameters[0],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const WidgetSpan(child: SizedBox(width: 8)),
          TextSpan(
            text: message.parameters[1],
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontStyle: FontStyle.italic,
            ),
          )
        ];
        break;
      case "QUIT":
        icon = const Icon(Icons.logout);
        content = [
          TextSpan(
            text: message.source!.nickname,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: " disconnected"),
          const WidgetSpan(child: SizedBox(width: 8)),
          TextSpan(
            text: message.parameters[1],
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontStyle: FontStyle.italic,
            ),
          )
        ];
        break;
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: _getTimeString(time),
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
          const WidgetSpan(child: SizedBox(width: 8)),
          if (icon != null) ...[
            WidgetSpan(
              child: IconTheme.merge(
                data: const IconThemeData(size: 18),
                child: icon,
              ),
              alignment: PlaceholderAlignment.middle,
            ),
            const WidgetSpan(
              child: SizedBox(width: 8),
            ),
          ],
          ...content,
        ],
      ),
    );
  }
}
