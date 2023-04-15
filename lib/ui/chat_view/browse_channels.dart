import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanasu_irc/irc/src/client.dart';
import 'package:hanasu_irc/ui/server_wrapper.dart';

final availableChannels = StreamProvider<List<IrcListChannel>>(
  (ref) async* {
    final channels = <IrcListChannel>[];
    final server = ref.watch(serverProvider);

    await for (final channel in server.client.listChannels()) {
      channels.add(channel);
      debugPrint("adding ${channel.name}");
      yield channels;
    }
  },
  dependencies: [serverProvider],
);

class BrowseChannelsPage extends ConsumerWidget {
  const BrowseChannelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(availableChannels);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Browse channels"),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Manually join a channel",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: "channel",
                              prefixText: "#",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onSubmitted: (value) async {
                              await joinChannel(ref, "#$value");
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        FloatingActionButton.small(
                          onPressed: () {},
                          child: const Icon(Icons.check),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          channels.map(
            data: (e) => SliverList.separated(
              itemCount: e.value.length,
              itemBuilder: (context, i) {
                final item = e.value[i];
                return ListTile(
                  title: Text(item.name),
                  subtitle: item.topic == null ? null : Text(item.topic!),
                  titleAlignment: ListTileTitleAlignment.top,
                  trailing: Text(
                    "${item.clients} clients",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () async {
                    await ref.read(serverProvider).joinChannel(item.name);
                  },
                );
              },
              separatorBuilder: (_, __) => const Divider(height: 1),
            ),
            error: (_) =>
                const SliverToBoxAdapter(child: Text("oopsie woopsie")),
            loading: (_) => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator())),
          ),
        ],
      ),
    );
  }

  Future<void> joinChannel(WidgetRef ref, String channel) async {
    await ref.read(serverProvider).joinChannel(channel);
  }
}
