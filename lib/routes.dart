import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanasu_irc/server_manager.dart';
import 'package:hanasu_irc/ui/add_server.dart';
import 'package:hanasu_irc/ui/chat_view/browse_channels.dart';
import 'package:hanasu_irc/ui/chat_view/channel_page.dart';
import 'package:hanasu_irc/ui/main/screen.dart';
import 'package:hanasu_irc/ui/server_wrapper.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _mainNavigatorKey = GlobalKey<NavigatorState>();
// final _serverNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: "/add-server",
  routes: [
    ShellRoute(
      navigatorKey: _mainNavigatorKey,
      builder: (context, state, child) => MainScreen(child: child),
      routes: [
        GoRoute(
          path: '/add-server',
          builder: (_, __) => const AddServerPage(),
        ),
        GoRoute(
          path: '/servers/:server',
          builder: (context, state) {
            final host = state.params["server"]!;
            return ProviderScope(
              overrides: [
                serverProvider.overrideWith(
                  (ref) => ref
                      .watch(serverManagerProvider)
                      .servers
                      .firstWhere((e) => e.host == host),
                ),
              ],
              child: ServerWrapper(
                location: state.location,
                child: const BrowseChannelsPage(),
              ),
            );
          },
          routes: [
            GoRoute(
              path: 'channels/:channel',
              builder: (context, state) {
                final host = state.params["server"]!;
                final channel = "#${state.params["channel"]!}";
                return ProviderScope(
                  overrides: [
                    serverProvider.overrideWith(
                      (ref) => ref
                          .watch(serverManagerProvider)
                          .servers
                          .firstWhere((e) => e.host == host),
                    ),
                    channelProvider.overrideWith(
                      (ref) => ref
                          .watch(serverProvider)
                          .channels
                          .firstWhere((e) => e.name == channel),
                    ),
                  ],
                  child: ServerWrapper(
                    location: state.location,
                    child: const ChannelPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
