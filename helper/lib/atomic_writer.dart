import 'dart:io';

class AtomicWriter {
  final String targetPath;
  final Directory backupsDir;
  final int retainBackups;
  int _seq = 0;

  AtomicWriter({
    required this.targetPath,
    required this.backupsDir,
    this.retainBackups = 10,
  });

  /// Returns the backup file path that was created.
  String write(String content) {
    final target = File(targetPath);
    final existing = target.existsSync() ? target.readAsStringSync() : '';
    final ts = DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    var backupPath = '${backupsDir.path}/etc-hosts-$ts.bak';
    while (File(backupPath).existsSync()) {
      _seq++;
      backupPath = '${backupsDir.path}/etc-hosts-$ts-$_seq.bak';
    }
    final backup = File(backupPath)..writeAsStringSync(existing);
    _trimBackups();

    final tmp = File('$targetPath.hosteditor.tmp');
    tmp.writeAsStringSync(content, flush: true);
    tmp.renameSync(targetPath);
    return backup.path;
  }

  void cleanupStaleTmp() {
    final dir = Directory(File(targetPath).parent.path);
    if (!dir.existsSync()) return;
    for (final f in dir.listSync().whereType<File>()) {
      if (f.path.endsWith('.hosteditor.tmp')) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
  }

  void _trimBackups() {
    final files = backupsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.bak'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    while (files.length > retainBackups) {
      try {
        files.removeAt(0).deleteSync();
      } catch (_) {}
    }
  }
}
