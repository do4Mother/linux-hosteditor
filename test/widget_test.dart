import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hosteditor/models/host.dart';
import 'package:hosteditor/providers/providers.dart';
import 'package:hosteditor/services/apply_status.dart';
import 'package:hosteditor/services/helper_client.dart';
import 'package:hosteditor/services/host_store.dart';
import 'package:hosteditor/widgets/host_editor_app.dart';

class _NoopStore implements HostStore {
  @override
  String get path => '';
  @override
  Future<List<Host>> load() async => const [];
  @override
  Future<void> save(List<Host> hosts) async {}
}

class _NoopClient implements HelperClient {
  @override
  Future<void> start() async {}
  @override
  Future<void> apply(String body, {Duration timeout = const Duration(seconds: 10)}) async {}
  @override
  Future<String> readHostsFile() async => '';
  @override
  void dispose() {}
  @override
  Stream<ApplyStatus> get status => const Stream.empty();
  @override
  ProcessFactory get processFactory => () => throw UnimplementedError();
}

void main() {
  testWidgets('Host Editor renders', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        hostStoreProvider.overrideWithValue(_NoopStore()),
        helperClientProvider.overrideWithValue(_NoopClient()),
      ],
      child: const HostEditorApp(),
    ));
    await tester.pump();
    expect(find.text('Host Editor'), findsWidgets);
    expect(find.text('All hosts'), findsOneWidget);
  });
}
