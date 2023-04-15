import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanasu_irc/irc/irc.dart';
import 'package:hanasu_irc/server_manager.dart';

class AddServerPage extends ConsumerStatefulWidget {
  const AddServerPage({super.key});

  @override
  ConsumerState<AddServerPage> createState() => _AddServerPageState();
}

class _AddServerPageState extends ConsumerState<AddServerPage> {
  late final TextEditingController _hostController;
  late final TextEditingController _nicknameController;

  bool useSSL = false;

  @override
  void initState() {
    super.initState();

    _hostController = TextEditingController();
    _nicknameController = TextEditingController(
      text: 'hanasu-irc-${Random().nextInt(100)}',
    );
  }

  bool get canToggleSSL => !kIsWeb;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Let's add a server",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 64),
            SizedBox(
              width: 8 * 48,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _hostController,
                          decoration: const InputDecoration(
                            labelText: "Address",
                            border: OutlineInputBorder(),
                          ),
                          autofocus: true,
                        ),
                      ),
                      if (canToggleSSL) ...[
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () => setState(() => useSSL = !useSSL),
                          icon: const Icon(Icons.lock_open),
                          selectedIcon: const Icon(Icons.lock),
                          isSelected: useSSL,
                          tooltip: "Use SSL",
                        ),
                      ],
                    ],
                  ),
                  //const Divider(height: 33),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: "Nickname",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // DropdownButtonFormField(
                  //   items: const [
                  //     DropdownMenuItem(child: Text("None")),
                  //   ],
                  //   decoration: const InputDecoration(
                  //     border: OutlineInputBorder(),
                  //     labelText: "Authentication Method",
                  //   ),
                  //   onChanged: (value) {},
                  // ),
                  // const SizedBox(height: 8),
                  // const TextField(
                  //   decoration: InputDecoration(
                  //     hintText: "Username",
                  //     border: OutlineInputBorder(),
                  //   ),
                  // ),
                  // const SizedBox(height: 8),
                  // const TextField(
                  //   decoration: InputDecoration(
                  //     hintText: "Password",
                  //     border: OutlineInputBorder(),
                  //   ),
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 64),
            FilledButton(
              onPressed: () async {
                final client = IrcClient(
                  nickname: _nicknameController.text,
                );

                final host = _hostController.text;
                final server = Server(client, host);

                final registration = client.connect(
                  host,
                  null,
                  null,
                  ConnectionType.ssl,
                );

                await for (var state in registration) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.toString()),
                    ),
                  );
                }

                ref.read(serverManagerProvider).addServer(server);
              },
              style: const ButtonStyle(
                visualDensity: VisualDensity.comfortable,
              ),
              child: const Text("Connect"),
            ),
          ],
        ),
      ),
    );
  }
}
