import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'apply_status.dart';

typedef ProcessFactory = Future<Process> Function();

class HelperError implements Exception {
  final String message;
  final String code;
  const HelperError(this.message, this.code);

  @override
  String toString() => 'HelperError($code): $message';
}

class _PendingRequest {
  final Map<String, dynamic> payload;
  final Completer<Map<String, dynamic>> completer = Completer();
  final Duration timeout;
  Timer? timer;
  _PendingRequest(this.payload, this.timeout);
}

class HelperClient {
  final ProcessFactory processFactory;
  Process? _process;
  final Queue<_PendingRequest> _queue = Queue();
  _PendingRequest? _inflight;
  final _statusCtl = StreamController<ApplyStatus>.broadcast(sync: true);
  bool _disposed = false;
  bool _processDone = false;
  Future<void>? _starting;

  HelperClient({required this.processFactory});

  Stream<ApplyStatus> get status => _statusCtl.stream;

  /// Starts the helper process if not already running.
  /// Safe to call concurrently — only one spawn attempt runs at a time.
  Future<void> start() {
    // Already have a live process.
    if (_process != null && !_processDone) return Future.value();
    // Memoize in-progress start so concurrent callers wait on the same future.
    return _starting ??= _startInternal();
  }

  Future<void> _startInternal() async {
    _processDone = false; // reset stale state from previous run
    _statusCtl.add(const Authenticating());
    try {
      _process = await processFactory();
    } catch (e) {
      _starting = null;
      _statusCtl.add(ApplyError(e.toString()));
      rethrow;
    }
    _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_onLine, onDone: _onProcessDone);
    unawaited(_process!.exitCode.then((_) => _onProcessDone()));
    try {
      // Extended timeout: pkexec auth dialog can take several seconds.
      final reply = await _sendRaw({'op': 'ping'}, timeout: const Duration(seconds: 30));
      if (reply['ok'] != true) {
        throw HelperError('ping failed', 'ping_failed');
      }
      _statusCtl.add(const Idle());
    } catch (e) {
      _starting = null;
      _statusCtl.add(ApplyError(e.toString()));
      rethrow;
    }
    _starting = null;
  }

  Future<void> apply(
    String blockBody, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await start(); // auto-restart if helper died
    _statusCtl.add(const Writing());
    try {
      final reply = await _sendRaw({'op': 'apply', 'block': blockBody}, timeout: timeout);
      if (reply['ok'] != true) {
        throw HelperError(
          reply['error']?.toString() ?? 'unknown',
          reply['code']?.toString() ?? 'unknown',
        );
      }
      _statusCtl.add(const Idle());
    } on HelperError catch (e) {
      _statusCtl.add(ApplyError(e.message));
      rethrow;
    }
  }

  Future<String> readHostsFile() async {
    await start(); // auto-restart if helper died
    final reply = await _sendRaw({'op': 'read'}, timeout: const Duration(seconds: 10));
    if (reply['ok'] != true) {
      throw HelperError(
        reply['error']?.toString() ?? 'unknown',
        reply['code']?.toString() ?? 'unknown',
      );
    }
    return reply['content'] as String;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    try {
      _process?.stdin.close();
    } catch (_) {}
    _process = null;
    if (!_statusCtl.isClosed) _statusCtl.close();
  }

  Future<Map<String, dynamic>> _sendRaw(
    Map<String, dynamic> payload, {
    required Duration timeout,
  }) {
    final req = _PendingRequest(payload, timeout);
    _queue.add(req);
    _pump();
    return req.completer.future;
  }

  void _pump() {
    if (_inflight != null || _queue.isEmpty) return;
    if (_processDone || _process == null) {
      // Drain the queue with helper_died errors.
      while (_queue.isNotEmpty) {
        final q = _queue.removeFirst();
        if (!q.completer.isCompleted) {
          q.completer.completeError(
            const HelperError('helper process exited', 'helper_died'),
          );
        }
      }
      return;
    }
    final req = _queue.removeFirst();
    _inflight = req;
    try {
      _process!.stdin.writeln(json.encode(req.payload));
    } catch (e) {
      if (!req.completer.isCompleted) {
        req.completer.completeError(HelperError('stdin write failed: $e', 'io_error'));
      }
      _inflight = null;
      _pump();
      return;
    }
    req.timer = Timer(req.timeout, () {
      if (_inflight != req) return;
      if (!req.completer.isCompleted) {
        req.completer.completeError(
          const HelperError('helper did not reply in time', 'timeout'),
        );
      }
      _inflight = null;
      _pump();
    });
  }

  void _onLine(String line) {
    final req = _inflight;
    if (req == null) return;
    try {
      final reply = json.decode(line) as Map<String, dynamic>;
      req.timer?.cancel();
      if (!req.completer.isCompleted) req.completer.complete(reply);
    } catch (e) {
      if (!req.completer.isCompleted) {
        req.completer.completeError(
          HelperError('bad json reply: $line', 'bad_reply'),
        );
      }
    }
    _inflight = null;
    _pump();
  }

  void _onProcessDone() {
    if (_processDone) return;
    _processDone = true;
    _starting = null; // allow next start() to spawn a fresh process
    final req = _inflight;
    if (req != null && !req.completer.isCompleted) {
      req.timer?.cancel();
      req.completer.completeError(
        const HelperError('helper process exited', 'helper_died'),
      );
    }
    _inflight = null;
    while (_queue.isNotEmpty) {
      final q = _queue.removeFirst();
      if (!q.completer.isCompleted) {
        q.completer.completeError(
          const HelperError('helper process exited', 'helper_died'),
        );
      }
    }
    _process = null;
  }
}
