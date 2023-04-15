import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanasu_irc/server_manager.dart';
import 'package:hanasu_irc/ui/chat_view/channel_list_tile.dart';
import 'package:hanasu_irc/ui/extensions.dart';

final serverProvider = Provider<Server>((_) => throw UnimplementedError());

final channelsProvider = Provider<List<Channel>>(
  (r) => r.watch(serverProvider.select((v) => v.channels)),
  dependencies: [serverProvider],
);

class ServerWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final String? location;

  const ServerWrapper({
    super.key,
    required this.child,
    this.location,
  });

  @override
  ConsumerState<ServerWrapper> createState() => _ServerWrapperState();
}

class _ServerWrapperState extends ConsumerState<ServerWrapper> {
  TextEditingController? _nicknameController;

  @override
  Widget build(BuildContext context) {
    final server = ref.watch(serverProvider);
    final channels = ref.watch(channelsProvider);

    _nicknameController ??= TextEditingController(text: server.client.nickname);

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 200,
            child: Material(
              elevation: 1,
              surfaceTintColor: Theme.of(context).colorScheme.primary,
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: InkWell(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              server.host,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                          const SizedBox(width: 8),
                        ],
                      ),
                      onTap: () {},
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      child: Column(
                        children: [
                          ChannelListTile(
                            leading: const Icon(Icons.search),
                            title: const Text("Browse Channels"),
                            selected: true,
                            onTap: () {},
                          ),
                          const Divider(
                            height: 17,
                          ),
                          for (final channel in channels)
                            ChannelListTile(
                              leading: const Icon(Icons.tag),
                              title: Text(channel.name),
                              selected: false,
                              onTap: () => context.push(
                                "/servers/${server.host}/channels/${channel.name.substring(1)}",
                              ),
                            ),
                        ].spaced(1, Axis.vertical),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        isDense: true,
                        focusedBorder: OutlineInputBorder(),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
