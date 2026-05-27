import 'dart:io';

class HostLineValidator {
  static final _hostnamePattern = RegExp(r'^[A-Za-z0-9._-]+$');

  /// Returns a list of human-readable errors. Empty list means valid.
  static List<String> validate(String blockBody) {
    final errors = <String>[];
    final lines = blockBody.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i];
      if (raw.trim().isEmpty) continue;
      final parts = raw.trim().split(RegExp(r'\s+'));
      if (parts.length < 2) {
        errors.add('line ${i + 1}: expected IP and hostname, got "$raw"');
        continue;
      }
      if (InternetAddress.tryParse(parts.first) == null) {
        errors.add('line ${i + 1}: "${parts.first}" is not a valid IP');
        continue;
      }
      for (final name in parts.skip(1)) {
        if (name.length > 253) {
          errors.add(
            'line ${i + 1}: hostname "$name" exceeds 253 chars (length=${name.length})',
          );
        } else if (!_hostnamePattern.hasMatch(name)) {
          errors.add('line ${i + 1}: hostname "$name" has invalid characters');
        }
      }
    }
    return errors;
  }
}
