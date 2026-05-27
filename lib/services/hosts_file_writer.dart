import 'dart:io';

import '../models/host.dart';

class InvalidTarget {
  final int id;
  final String target;
  const InvalidTarget(this.id, this.target);

  @override
  bool operator ==(Object other) =>
      other is InvalidTarget && other.id == id && other.target == target;

  @override
  int get hashCode => Object.hash(id, target);

  @override
  String toString() => 'InvalidTarget(id=$id, target=$target)';
}

class InvalidHostException implements Exception {
  final List<InvalidTarget> offenders;
  const InvalidHostException(this.offenders);

  @override
  String toString() =>
      'InvalidHostException: ${offenders.length} invalid target(s): $offenders';
}

class HostsFileWriter {
  static String render(List<Host> hosts) {
    final offenders = <InvalidTarget>[];
    final buf = StringBuffer();
    for (final h in hosts) {
      if (!h.active) continue;
      if (InternetAddress.tryParse(h.target) == null) {
        offenders.add(InvalidTarget(h.id, h.target));
        continue;
      }
      buf.write(h.target);
      buf.write('\t');
      buf.write(h.hostname);
      buf.write('\n');
    }
    if (offenders.isNotEmpty) throw InvalidHostException(offenders);
    return buf.toString();
  }
}
