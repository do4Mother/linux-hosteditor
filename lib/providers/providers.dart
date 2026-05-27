import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/host.dart';
import '../models/ping.dart';
import '../services/apply_status.dart';
import '../services/helper_client.dart';
import '../services/host_store.dart';
import '../services/hosts_file_writer.dart';

final hostStoreProvider = Provider<HostStore>(
  (ref) => throw UnimplementedError('hostStoreProvider must be overridden'),
);

final helperClientProvider = Provider<HelperClient>(
  (ref) => throw UnimplementedError('helperClientProvider must be overridden'),
);

final applyStatusProvider = StateProvider<ApplyStatus>((ref) => const Idle());

class HostsNotifier extends Notifier<List<Host>> {
  int _nextId = 100;
  Timer? _debounce;

  @override
  List<Host> build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(() async {
      final loaded = await ref.read(hostStoreProvider).load();
      if (loaded.isNotEmpty) {
        state = loaded;
        _nextId = loaded.map((h) => h.id).fold<int>(0, (a, b) => a > b ? a : b) + 1;
      }
    });
    return const [];
  }

  void add(Host h) {
    state = [h.copyWith(updated: 'just now'), ...state];
    _scheduleSync();
  }

  void update(Host h) {
    final updated = h.copyWith(updated: 'just now');
    state = [
      for (final x in state)
        if (x.id == updated.id) updated else x,
    ];
    _scheduleSync();
  }

  void toggle(int id) {
    state = [
      for (final h in state)
        if (h.id == id) h.copyWith(active: !h.active, updated: 'just now') else h,
    ];
    _scheduleSync();
  }

  void bulkSetActive(Set<int> ids, bool active) {
    state = [
      for (final h in state)
        if (ids.contains(h.id)) h.copyWith(active: active, updated: 'just now') else h,
    ];
    _scheduleSync();
  }

  void duplicate(int id) {
    final h = state.firstWhere((x) => x.id == id);
    final dup = Host(
      id: _nextId++,
      hostname: '${h.hostname}.copy',
      target: h.target,
      env: h.env,
      active: h.active,
      note: h.note,
      updated: 'just now',
    );
    state = [dup, ...state];
    _scheduleSync();
  }

  List<Host> deleteOne(int id) {
    final backup = List<Host>.from(state);
    state = state.where((x) => x.id != id).toList();
    _scheduleSync();
    return backup;
  }

  List<Host> deleteMany(Set<int> ids) {
    final backup = List<Host>.from(state);
    state = state.where((x) => !ids.contains(x.id)).toList();
    _scheduleSync();
    return backup;
  }

  void restore(List<Host> backup) {
    state = backup;
    _scheduleSync();
  }

  int nextId() => _nextId++;

  Future<void> retrySync() => _syncNow();

  void _scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _syncNow);
  }

  Future<void> _syncNow() async {
    final snapshot = state;
    try {
      await ref.read(hostStoreProvider).save(snapshot);
      final body = HostsFileWriter.render(snapshot);
      await ref.read(helperClientProvider).apply(body);
      ref.read(applyStatusProvider.notifier).state = const Idle();
    } catch (e) {
      ref.read(applyStatusProvider.notifier).state = ApplyError(e.toString());
    }
  }
}

final hostsProvider = NotifierProvider<HostsNotifier, List<Host>>(HostsNotifier.new);

final activeNavProvider = StateProvider<String>((ref) => 'all');
final filterStatusProvider = StateProvider<String>((ref) => 'all');
final searchProvider = StateProvider<String>((ref) => '');
final firstWriteBannerDismissedProvider = StateProvider<bool>((ref) => false);

class SelectedNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => <int>{};

  void toggle(int id) {
    final next = Set<int>.from(state);
    if (!next.add(id)) next.remove(id);
    state = next;
  }

  void clear() => state = <int>{};

  void toggleAll(Set<int> visibleIds) {
    final all = visibleIds.isNotEmpty && visibleIds.every(state.contains);
    final next = Set<int>.from(state);
    if (all) {
      next.removeAll(visibleIds);
    } else {
      next.addAll(visibleIds);
    }
    state = next;
  }
}

final selectedProvider = NotifierProvider<SelectedNotifier, Set<int>>(SelectedNotifier.new);

class PingsNotifier extends Notifier<Map<int, Ping>> {
  final Map<int, Timer> _timers = {};
  final _rand = Random();

  @override
  Map<int, Ping> build() {
    ref.onDispose(() {
      for (final t in _timers.values) {
        t.cancel();
      }
      _timers.clear();
    });
    return <int, Ping>{};
  }

  void start(int id) {
    _timers[id]?.cancel();
    state = {...state, id: const Ping('pending')};
    final ms = 200 + _rand.nextInt(700);
    _timers[id] = Timer(Duration(milliseconds: ms), () {
      final ok = _rand.nextDouble() > 0.18;
      state = {...state, id: Ping(ok ? 'ok' : 'fail', ms)};
      _timers[id] = Timer(const Duration(milliseconds: 4500), () {
        final next = Map<int, Ping>.from(state)..remove(id);
        state = next;
      });
    });
  }
}

final pingsProvider = NotifierProvider<PingsNotifier, Map<int, Ping>>(PingsNotifier.new);

final filteredHostsProvider = Provider<List<Host>>((ref) {
  final hosts = ref.watch(hostsProvider);
  final activeNav = ref.watch(activeNavProvider);
  final filterStatus = ref.watch(filterStatusProvider);
  final search = ref.watch(searchProvider);
  return hosts.where((h) {
    if (activeNav == 'inactive') {
      if (h.active) return false;
    } else if (activeNav != 'all') {
      final navEnv = Env.values.firstWhere((e) => e.name == activeNav);
      if (h.env != navEnv) return false;
    }
    if (filterStatus == 'active' && !h.active) return false;
    if (filterStatus == 'inactive' && h.active) return false;
    if (search.isNotEmpty) {
      final q = search.toLowerCase();
      if (!h.hostname.toLowerCase().contains(q) && !h.target.toLowerCase().contains(q) && !h.note.toLowerCase().contains(q)) {
        return false;
      }
    }
    return true;
  }).toList();
});
