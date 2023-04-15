import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanasu_irc/server_manager.dart';
import 'package:hanasu_irc/ui/widgets/server_selector.dart';

class MainScreen extends ConsumerWidget {
  final Widget child;

  const MainScreen({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).location;
    // print(location);
    final servers = ref.watch(serverManagerProvider).servers;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            elevation: 2,
            surfaceTintColor: Theme.of(context).colorScheme.primary,
            color: Theme.of(context).colorScheme.surface,
            child: ServerSelector(
              children: [
                ServerDestination(
                  name: "Direct Messages",
                  icon: const Icon(Icons.people),
                  selected: false,
                  onTap: () {},
                ),
                for (final server in servers)
                  ServerDestination(
                    name: server.host,
                    selected: location == "/servers/${server.host}",
                    onTap: () => context.push("/servers/${server.host}"),
                  ),
                ServerDestination(
                  name: "Add server",
                  icon: const Icon(Icons.add),
                  selected: location == "/add-server",
                  onTap: () => context.push("/add-server"),
                ),
              ],
            ),
          ),
          // Material(
          //   elevation: 1,
          //   surfaceTintColor: Theme.of(context).colorScheme.primary,
          //   color: Theme.of(context).colorScheme.surface,
          //   child: const SecondarySidebar(),
          // ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
