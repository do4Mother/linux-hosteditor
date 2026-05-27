import 'package:hosteditor_helper/marker_block.dart';
import 'package:test/test.dart';

void main() {
  group('MarkerBlock.replace', () {
    test('appends block with markers when absent', () {
      const input = '127.0.0.1 localhost\n::1 ip6-localhost\n';
      final out = MarkerBlock.replace(input, '10.0.0.1\tapi.dev.local\n');
      expect(out, contains('# BEGIN hosteditor'));
      expect(out, contains('# END hosteditor'));
      expect(out, contains('10.0.0.1\tapi.dev.local'));
      expect(out, startsWith('127.0.0.1 localhost\n::1 ip6-localhost\n'));
    });

    test('replaces existing block, leaves surrounding lines untouched', () {
      const input =
          '127.0.0.1 localhost\n'
          '# BEGIN hosteditor\n'
          'OLD CONTENT\n'
          '# END hosteditor\n'
          '# trailing user comment\n';
      final out = MarkerBlock.replace(input, '10.0.0.1\tnew.local\n');
      expect(
        out,
        '127.0.0.1 localhost\n'
        '# BEGIN hosteditor — DO NOT EDIT THIS BLOCK BY HAND\n'
        '10.0.0.1\tnew.local\n'
        '# END hosteditor\n'
        '# trailing user comment\n',
      );
    });

    test('empty body collapses to just the markers', () {
      const input = 'x\n# BEGIN hosteditor\nfoo\n# END hosteditor\ny\n';
      final out = MarkerBlock.replace(input, '');
      expect(
        out,
        'x\n'
        '# BEGIN hosteditor — DO NOT EDIT THIS BLOCK BY HAND\n'
        '# END hosteditor\n'
        'y\n',
      );
    });
  });
}
