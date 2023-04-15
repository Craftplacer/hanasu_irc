import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanasu_irc/routes.dart';
import 'package:logging/logging.dart';

void main() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    log(
      record.message,
      name: record.loggerName,
      error: record.error,
      stackTrace: record.stackTrace,
      level: record.level.value,
      time: record.time,
      zone: record.zone,
      sequenceNumber: record.sequenceNumber,
    );
  });

  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.from(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: router,
    );
  }
}
