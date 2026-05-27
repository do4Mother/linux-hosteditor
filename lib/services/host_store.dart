import 'dart:convert';
import 'dart:io';

import '../models/host.dart';

class HostStore {
  final String path;

  HostStore({required this.path});

  factory HostStore.defaultLocation() {
    final override = Platform.environment['HOSTEDITOR_DB_PATH'];
    if (override != null) return HostStore(path: override);
    final home = Platform.environment['HOME']!;
    return HostStore(path: '$home/.config/hosteditor/hosts.json');
  }

  Future<List<Host>> load() async {
    final f = File(path);
    if (!await f.exists()) return [];
    final raw = await f.readAsString();
    if (raw.trim().isEmpty) return [];
    final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(Host.fromJson).toList();
  }

  Future<void> save(List<Host> hosts) async {
    final f = File(path);
    await f.parent.create(recursive: true);
    final tmp = File('$path.tmp');
    final encoded = const JsonEncoder.withIndent('  ')
        .convert(hosts.map((h) => h.toJson()).toList());
    await tmp.writeAsString(encoded, flush: true);
    await tmp.rename(path);
  }
}
