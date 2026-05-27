import 'dart:io';
import 'package:hosteditor_helper/atomic_writer.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('atomic_writer_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('writes new content via tmp+rename, leaves no tmp behind', () {
    final target = File('${tmp.path}/etc-hosts')..writeAsStringSync('OLD\n');
    final backupsDir = Directory('${tmp.path}/backups')..createSync();
    AtomicWriter(targetPath: target.path, backupsDir: backupsDir).write('NEW\n');
    expect(target.readAsStringSync(), 'NEW\n');
    final leftovers = Directory(target.parent.path)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.hosteditor.tmp'));
    expect(leftovers, isEmpty);
  });

  test('creates a backup before overwriting', () {
    final target = File('${tmp.path}/etc-hosts')..writeAsStringSync('OLD\n');
    final backupsDir = Directory('${tmp.path}/backups')..createSync();
    final backup = AtomicWriter(targetPath: target.path, backupsDir: backupsDir)
        .write('NEW\n');
    expect(File(backup).readAsStringSync(), 'OLD\n');
  });

  test('keeps at most 10 backups, deleting the oldest', () {
    final target = File('${tmp.path}/etc-hosts')..writeAsStringSync('OLD\n');
    final backupsDir = Directory('${tmp.path}/backups')..createSync();
    final writer = AtomicWriter(targetPath: target.path, backupsDir: backupsDir);
    for (var i = 0; i < 12; i++) {
      writer.write('round $i\n');
    }
    final backups = backupsDir.listSync().whereType<File>().toList();
    expect(backups.length, 10);
  });

  test('cleanupStaleTmp removes leftover *.hosteditor.tmp files', () {
    File('${tmp.path}/etc-hosts.hosteditor.tmp').writeAsStringSync('stale');
    final target = File('${tmp.path}/etc-hosts')..writeAsStringSync('OK\n');
    final backupsDir = Directory('${tmp.path}/backups')..createSync();
    AtomicWriter(targetPath: target.path, backupsDir: backupsDir).cleanupStaleTmp();
    expect(File('${tmp.path}/etc-hosts.hosteditor.tmp').existsSync(), isFalse);
  });
}
