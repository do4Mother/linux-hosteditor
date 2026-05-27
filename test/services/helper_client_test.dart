import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hosteditor/services/apply_status.dart';
import 'package:hosteditor/services/helper_client.dart';

class _CapturingSink implements IOSink {
  final List<String> writes = [];
  bool closed = false;

  @override
  Encoding encoding = utf8;

  @override
  void add(List<int> data) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future addStream(Stream<List<int>> stream) async {}
  @override
  Future close() async {
    closed = true;
  }
  @override
  Future get done => Future.value();
  @override
  Future flush() async {}
  @override
  void write(Object? o) => writes.add(o.toString());
  @override
  void writeAll(Iterable objects, [String separator = '']) {}
  @override
  void writeCharCode(int charCode) {}
  @override
  void writeln([Object? o = '']) => writes.add('$o\n');
}

class _FakeProcess implements Process {
  final _stdin = _CapturingSink();
  final _stdoutCtl = StreamController<List<int>>();
  final _stderrCtl = StreamController<List<int>>();
  final _exit = Completer<int>();

  void reply(Map<String, dynamic> msg) {
    _stdoutCtl.add(utf8.encode('${json.encode(msg)}\n'));
  }

  void die(int code) {
    if (!_stdoutCtl.isClosed) _stdoutCtl.close();
    if (!_stderrCtl.isClosed) _stderrCtl.close();
    if (!_exit.isCompleted) _exit.complete(code);
  }

  @override
  Stream<List<int>> get stdout => _stdoutCtl.stream;
  @override
  Stream<List<int>> get stderr => _stderrCtl.stream;
  @override
  IOSink get stdin => _stdin;
  @override
  Future<int> get exitCode => _exit.future;
  @override
  int get pid => 1;
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    die(-1);
    return true;
  }
}

Future<void> _startClient(HelperClient c, _FakeProcess fake) async {
  final s = c.start();
  await Future<void>.delayed(Duration.zero);
  fake.reply({'ok': true, 'version': '1.0.0'});
  await s;
}

void main() {
  late _FakeProcess fake;
  late HelperClient client;

  setUp(() {
    fake = _FakeProcess();
    client = HelperClient(processFactory: () async => fake);
  });

  test('start sends ping and resolves on ok', () async {
    await _startClient(client, fake);
    expect(fake._stdin.writes.any((w) => w.contains('"op":"ping"')), isTrue);
  });

  test('apply sends block and resolves on ok', () async {
    await _startClient(client, fake);
    final f = client.apply('10.0.0.1\ta\n');
    await Future<void>.delayed(Duration.zero);
    fake.reply({'ok': true, 'backup': '/tmp/x.bak'});
    await f;
    expect(fake._stdin.writes.any((w) => w.contains('"op":"apply"')), isTrue);
  });

  test('apply propagates helper error', () async {
    await _startClient(client, fake);
    final f = client.apply('bad');
    await Future<void>.delayed(Duration.zero);
    fake.reply({'ok': false, 'error': 'validation_failed', 'code': 'validation_failed'});
    await expectLater(f, throwsA(isA<HelperError>()));
  });

  test('apply throws on timeout', () async {
    await _startClient(client, fake);
    final f = client.apply('x', timeout: const Duration(milliseconds: 50));
    await expectLater(
      f,
      throwsA(isA<HelperError>().having((e) => e.code, 'code', 'timeout')),
    );
  });

  test('helper dying mid-request fails the in-flight call', () async {
    await _startClient(client, fake);
    final f = client.apply('x');
    await Future<void>.delayed(Duration.zero);
    fake.die(127);
    await expectLater(
      f,
      throwsA(isA<HelperError>().having((e) => e.code, 'code', 'helper_died')),
    );
  });

  test('concurrent applies are queued', () async {
    await _startClient(client, fake);
    final f1 = client.apply('a');
    final f2 = client.apply('b');
    await Future<void>.delayed(Duration.zero);
    fake.reply({'ok': true, 'backup': '/tmp/1.bak'});
    await f1;
    fake.reply({'ok': true, 'backup': '/tmp/2.bak'});
    await f2;
    // Both apply ops should have been written to stdin.
    final applyWrites = fake._stdin.writes.where((w) => w.contains('"op":"apply"')).toList();
    expect(applyWrites.length, 2);
  });

  test('status stream emits Writing then Idle on successful apply', () async {
    await _startClient(client, fake);
    final emitted = <ApplyStatus>[];
    final sub = client.status.listen(emitted.add);
    final f = client.apply('x');
    await Future<void>.delayed(Duration.zero);
    fake.reply({'ok': true, 'backup': '/tmp/x.bak'});
    await f;
    await sub.cancel();
    expect(emitted.whereType<Writing>(), isNotEmpty);
    expect(emitted.whereType<Idle>(), isNotEmpty);
  });

  test('status stream emits ApplyError on failure', () async {
    await _startClient(client, fake);
    final emitted = <ApplyStatus>[];
    final sub = client.status.listen(emitted.add);
    final f = client.apply('bad');
    await Future<void>.delayed(Duration.zero);
    fake.reply({'ok': false, 'error': 'nope', 'code': 'validation_failed'});
    await f.catchError((_) {});
    await sub.cancel();
    expect(emitted.whereType<ApplyError>(), isNotEmpty);
  });
}
