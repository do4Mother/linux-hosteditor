import 'package:hosteditor_helper/host_line_validator.dart';
import 'package:test/test.dart';

void main() {
  group('HostLineValidator.validate', () {
    test('accepts IPv4 + hostname', () {
      expect(HostLineValidator.validate('10.0.0.1\tapi.dev.local\n'), isEmpty);
    });
    test('accepts IPv6 + hostname', () {
      expect(HostLineValidator.validate('::1 v6.local\n'), isEmpty);
    });
    test('accepts multiple aliases', () {
      expect(HostLineValidator.validate('10.0.0.1 a b c\n'), isEmpty);
    });
    test('rejects line with no IP', () {
      final errors = HostLineValidator.validate('notanip host\n');
      expect(errors, isNotEmpty);
      expect(errors.first, contains('notanip'));
    });
    test('rejects hostname with bad chars', () {
      final errors = HostLineValidator.validate('10.0.0.1 bad;rm\n');
      expect(errors, isNotEmpty);
    });
    test('rejects hostname over 253 chars', () {
      final long = 'a' * 254;
      final errors = HostLineValidator.validate('10.0.0.1 $long\n');
      expect(errors, isNotEmpty);
      expect(errors.first, contains('length'));
    });
    test('blank and whitespace-only lines are ignored', () {
      expect(HostLineValidator.validate('\n   \n'), isEmpty);
    });
  });
}
