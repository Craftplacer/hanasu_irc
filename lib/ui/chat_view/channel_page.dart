import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanasu_irc/server_manager.dart';
import 'package:hanasu_irc/ui/server_wrapper.dart';
import 'package:hanasu_irc/ui/widgets/message.dart';

final channelProvider = Provider<Channel>(
  (_) => throw UnimplementedError(),
  dependencies: [serverProvider],
);

final channelUsersProvider = FutureProvider<List<String>>(
  (ref) async {
    final server = ref.watch(serverProvider);
    final channel = ref.watch(channelProvider);

    final membership = await server.client.getNames(channel.name).single;
    return membership.nicknames;
  },
  dependencies: [serverProvider, channelProvider],
);

class ChannelPage extends ConsumerStatefulWidget {
  const ChannelPage({super.key});

  @override
  ConsumerState<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends ConsumerState<ChannelPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // final server = ref.watch(serverProvider);
    final channel = ref.watch(channelProvider);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(channel.name),
        actions: [
          IconButton(
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
            icon: const Icon(Icons.people_outline),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: Consumer(builder: (context, ref, child) {
          final users = ref.watch(channelUsersProvider);
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    "Users",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              users.map(
                data: (data) {
                  final nicks = List.from(data.value)..sort();
                  return SliverList.builder(
                    itemCount: nicks.length,
                    itemBuilder: (context, i) {
                      return ListTile(title: Text(nicks[i]));
                    },
                  );
                },
                error: (e) => SliverToBoxAdapter(
                  child: Text(e.toString()),
                ),
                loading: (_) => SliverFillViewport(
                  delegate: SliverChildListDelegate([
                    const Center(child: CircularProgressIndicator()),
                  ]),
                ),
              ),
            ],
          );
        }),
      ),
      body: ChatView(controller: channel.messages),
    );
  }
}

class ChatView extends StatefulWidget {
  final ChatController controller;

  const ChatView({super.key, required this.controller});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final messages = widget.controller.messages;
    var channel = widget.controller.target;
    return Column(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              return SelectionArea(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  addSemanticIndexes: false,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final message = messages[(messages.length - 1) - i];
                    return MessageWidget(message);
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
          child: TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: "Message $channel",
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(
                onPressed: sendMessage,
                icon: const Icon(Icons.send),
              ),
            ),
            onSubmitted: (input) => sendMessage(input),
          ),
        ),
      ],
    );
  }

  Future<void> sendMessage([String? input]) async {
    input ??= _textController.text;
    await widget.controller.sendMessage(input);
    _textController.clear();
  }
}
