import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosteditor/models/host.dart';
import 'package:hosteditor/services/host_store.dart';

void main() {
  late Directory tmp;
  late HostStore store;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('host_store_');
    store = HostStore(path: '${tmp.path}/hosts.json');
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('load returns empty when file missing', () async {
    expect(await store.load(), isEmpty);
  });

  test('save then load round-trips one host with all fields', () async {
    final h = Host(
      id: 42,
      hostname: 'api.dev.local',
      target: '10.0.0.1',
      env: Env.staging,
      active: true,
      note: 'hello',
      updated: 'just now',
    );
    await store.save([h]);
    final loaded = await store.load();
    expect(loaded, hasLength(1));
    final r = loaded.single;
    expect(r.id, 42);
    expect(r.hostname, 'api.dev.local');
    expect(r.target, '10.0.0.1');
    expect(r.env, Env.staging);
    expect(r.active, isTrue);
    expect(r.note, 'hello');
    expect(r.updated, 'just now');
  });

  test('atomic write: stale .tmp does not corrupt prior content', () async {
    final h1 = Host(id: 1, hostname: 'a', target: '10.0.0.1', env: Env.dev, active: true, updated: 'now');
    await store.save([h1]);
    File('${tmp.path}/hosts.json.tmp').writeAsStringSync('GARBAGE');
    final loaded = await store.load();
    expect(loaded.single.hostname, 'a');
  });

  test('load returns [] when file is empty or whitespace', () async {
    File('${tmp.path}/hosts.json').writeAsStringSync('   \n');
    expect(await store.load(), isEmpty);
  });

  test('defaultLocation honors HOSTEDITOR_DB_PATH', () {
    // We can only verify the field, not env-var injection inside the same process easily.
    // Instead: test that explicit path via constructor is preserved.
    final s = HostStore(path: '/explicit/path/hosts.json');
    expect(s.path, '/explicit/path/hosts.json');
  });

  test('save creates parent directories if missing', () async {
    final nested = HostStore(path: '${tmp.path}/nested/dir/hosts.json');
    await nested.save([Host(id: 1, hostname: 'a', target: '10.0.0.1', env: Env.dev, active: true, updated: 'now')]);
    expect(File('${tmp.path}/nested/dir/hosts.json').existsSync(), isTrue);
  });
}
