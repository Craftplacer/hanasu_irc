import 'package:flutter/material.dart';
import 'package:hanasu_irc/ui/extensions.dart';

class ServerSelector extends StatelessWidget {
  final List<Widget> children;

  const ServerSelector({
    required this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: children.spaced(8, Axis.vertical),
      ),
    );
  }
}

class ServerDestination extends StatefulWidget {
  final String name;
  final Widget? icon;
  final bool? selected;
  final VoidCallback? onTap;

  const ServerDestination({
    super.key,
    required this.name,
    this.icon,
    this.selected,
    this.onTap,
  });

  @override
  State<ServerDestination> createState() => _ServerDestinationState();
}

class _ServerDestinationState extends State<ServerDestination>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(microseconds: 150),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ServerDestination oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selected == widget.selected) return;

    if (widget.selected!) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? body;

    if (widget.icon != null) {
      body = widget.icon!;
    } else {
      body = Text(widget.name.substring(0, 1).toLowerCase());
    }

    final backgroundColorTween = ColorTween(
      begin: Theme.of(context).colorScheme.surfaceVariant,
      end: Theme.of(context).colorScheme.primaryContainer,
    );

    return Tooltip(
      message: widget.name,
      child: AnimatedBuilder(
        animation: _controller,
        child: InkWell(
          onTap: widget.onTap,
          child: Center(child: body),
        ),
        builder: (context, child) {
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SizedBox.square(
                  dimension: 40.0,
                  child: Material(
                    clipBehavior: Clip.antiAlias,
                    color: backgroundColorTween.animate(_controller).value,
                    borderRadius: BorderRadius.circular(8.0),
                    child: child,
                  ),
                ),
              ),
              if (widget.selected!)
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8.0),
                        bottomRight: Radius.circular(8.0),
                      ),
                    ),
                    child: const SizedBox(
                      width: 4.0,
                      height: 40.0,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
