import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'providers/providers.dart';
import 'services/helper_client.dart';
import 'services/host_store.dart';
import 'widgets/host_editor_app.dart';

void main() async {
  final store = HostStore.defaultLocation();
  final client = HelperClient(processFactory: _defaultHelperFactory);
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720), // Initial size
    minimumSize: Size(1280, 720), // Minimum width and height
    center: true,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    ProviderScope(
      overrides: [hostStoreProvider.overrideWithValue(store), helperClientProvider.overrideWithValue(client)],
      child: const HostEditorApp(),
    ),
  );
}

Future<Process> _defaultHelperFactory() {
  final helperPath = Platform.environment['HOSTEDITOR_HELPER_PATH'] ?? '/usr/libexec/hosteditor-helper';
  return Process.start('pkexec', [helperPath]);
}
