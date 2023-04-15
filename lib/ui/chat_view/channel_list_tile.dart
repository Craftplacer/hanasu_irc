import 'package:flutter/material.dart';

class ChannelListTile extends StatelessWidget {
  final Widget title;
  final Widget leading;
  final VoidCallback? onTap;
  final bool selected;

  const ChannelListTile({
    super.key,
    required this.title,
    required this.leading,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onTap,
      color: selected ? Theme.of(context).colorScheme.surfaceVariant : null,
      height: 40,
      child: Row(
        children: [
          leading,
          const SizedBox(width: 8),
          Expanded(child: title),
        ],
      ),
    );
  }
}
