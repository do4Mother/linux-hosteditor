import 'dart:convert';
import 'dart:io';

import 'package:hosteditor_helper/atomic_writer.dart';
import 'package:hosteditor_helper/host_line_validator.dart';
import 'package:hosteditor_helper/marker_block.dart';

const _version = '1.0.0';

Future<void> main() async {
  final targetPath = Platform.environment['HOSTEDITOR_TARGET_HOSTS'] ?? '/etc/hosts';
  final backupsDir = _resolveBackupsDir();
  if (!backupsDir.existsSync()) backupsDir.createSync(recursive: true);

  final writer = AtomicWriter(targetPath: targetPath, backupsDir: backupsDir);
  writer.cleanupStaleTmp();

  await for (final line
      in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.trim().isEmpty) continue;
    Map<String, dynamic> req;
    try {
      req = json.decode(line) as Map<String, dynamic>;
    } catch (_) {
      stdout.writeln(json.encode({
        'ok': false,
        'error': 'invalid json',
        'code': 'bad_request',
      }));
      await stdout.flush();
      continue;
    }
    final op = req['op'];
    try {
      switch (op) {
        case 'ping':
          stdout.writeln(json.encode({'ok': true, 'version': _version}));
        case 'read':
          final content = File(targetPath).existsSync()
              ? File(targetPath).readAsStringSync()
              : '';
          stdout.writeln(json.encode({'ok': true, 'content': content}));
        case 'apply':
          final body = (req['block'] as String?) ?? '';
          final errors = HostLineValidator.validate(body);
          if (errors.isNotEmpty) {
            stdout.writeln(json.encode({
              'ok': false,
              'error': errors.join('; '),
              'code': 'validation_failed',
            }));
            break;
          }
          final existing = File(targetPath).existsSync()
              ? File(targetPath).readAsStringSync()
              : '';
          final next = MarkerBlock.replace(existing, body);
          final backup = writer.write(next);
          stdout.writeln(json.encode({'ok': true, 'backup': backup}));
        case 'quit':
          stdout.writeln(json.encode({'ok': true}));
          await stdout.flush();
          exit(0);
        default:
          stdout.writeln(json.encode({
            'ok': false,
            'error': 'unknown op: $op',
            'code': 'bad_request',
          }));
      }
    } catch (e) {
      stdout.writeln(json.encode({
        'ok': false,
        'error': '$e',
        'code': 'io_error',
      }));
    }
    await stdout.flush();
  }
}

Directory _resolveBackupsDir() {
  final uidStr = Platform.environment['PKEXEC_UID'];
  if (uidStr != null) {
    try {
      final pw = File('/etc/passwd').readAsLinesSync();
      for (final line in pw) {
        final parts = line.split(':');
        if (parts.length >= 6 && parts[2] == uidStr) {
          return Directory('${parts[5]}/.config/hosteditor/backups');
        }
      }
    } catch (_) {}
  }
  final sudoUser = Platform.environment['SUDO_USER'];
  if (sudoUser != null) {
    return Directory('/home/$sudoUser/.config/hosteditor/backups');
  }
  // For tests / non-pkexec invocations, prefer HOME.
  final home = Platform.environment['HOME'];
  if (home != null) {
    return Directory('$home/.config/hosteditor/backups');
  }
  return Directory('/var/backups/hosteditor');
}
