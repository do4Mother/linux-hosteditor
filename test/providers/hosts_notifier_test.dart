import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosteditor/models/host.dart';
import 'package:hosteditor/providers/providers.dart';
import 'package:hosteditor/services/apply_status.dart';
import 'package:hosteditor/services/helper_client.dart';
import 'package:hosteditor/services/host_store.dart';

class _FakeStore implements HostStore {
  List<Host> stored = [];
  @override
  String get path => '';
  @override
  Future<List<Host>> load() async => stored;
  @override
  Future<void> save(List<Host> hosts) async {
    stored = List.of(hosts);
  }
}

class _FakeClient implements HelperClient {
  final List<String> applied = [];
  bool failNext = false;

  @override
  Future<void> apply(String body, {Duration timeout = const Duration(seconds: 10)}) async {
    if (failNext) {
      failNext = false;
      throw const HelperError('nope', 'fake');
    }
    applied.add(body);
  }

  @override
  Future<void> start() async {}
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
  test('add triggers persist + apply after debounce', () async {
    final store = _FakeStore();
    final client = _FakeClient();
    final container = ProviderContainer(overrides: [
      hostStoreProvider.overrideWithValue(store),
      helperClientProvider.overrideWithValue(client),
    ]);
    addTearDown(container.dispose);

    // Let the initial async load settle.
    await Future<void>.delayed(Duration.zero);

    container.read(hostsProvider.notifier).add(
      Host(id: 10, hostname: 'a.local', target: '10.0.0.1', env: Env.dev, active: true, updated: 'now'),
    );

    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(store.stored.single.hostname, 'a.local');
    expect(client.applied.single, contains('10.0.0.1'));
  });

  test('helper failure sets applyStatusProvider to ApplyError but state remains', () async {
    final store = _FakeStore();
    final client = _FakeClient()..failNext = true;
    final container = ProviderContainer(overrides: [
      hostStoreProvider.overrideWithValue(store),
      helperClientProvider.overrideWithValue(client),
    ]);
    addTearDown(container.dispose);

    await Future<void>.delayed(Duration.zero);

    container.read(hostsProvider.notifier).add(
      Host(id: 11, hostname: 'b.local', target: '10.0.0.2', env: Env.dev, active: true, updated: 'now'),
    );

    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(container.read(hostsProvider), hasLength(1));
    expect(container.read(applyStatusProvider), isA<ApplyError>());
  });

  test('initial async load replaces empty state', () async {
    final store = _FakeStore()
      ..stored = [
        Host(id: 1, hostname: 'preloaded', target: '10.0.0.5', env: Env.dev, active: true, updated: 'old'),
      ];
    final client = _FakeClient();
    final container = ProviderContainer(overrides: [
      hostStoreProvider.overrideWithValue(store),
      helperClientProvider.overrideWithValue(client),
    ]);
    addTearDown(container.dispose);

    // Synchronous build returns [].
    expect(container.read(hostsProvider), isEmpty);

    // After microtask, loaded list is present.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(hostsProvider).single.hostname, 'preloaded');
  });
}
