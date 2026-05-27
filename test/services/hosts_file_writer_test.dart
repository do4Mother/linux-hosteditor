import 'package:flutter_test/flutter_test.dart';
import 'package:hosteditor/models/host.dart';
import 'package:hosteditor/services/hosts_file_writer.dart';

Host _h({
  int id = 1,
  String hostname = 'api.dev.local',
  String target = '10.0.0.1',
  bool active = true,
  Env env = Env.dev,
}) => Host(id: id, hostname: hostname, target: target, env: env, active: active, updated: 'now');

void main() {
  group('HostsFileWriter.render', () {
    test('empty list → empty string', () {
      expect(HostsFileWriter.render(const []), '');
    });

    test('all inactive → empty string', () {
      expect(HostsFileWriter.render([_h(active: false)]), '');
    });

    test('single active IPv4 host', () {
      expect(
        HostsFileWriter.render([_h()]),
        '10.0.0.1\tapi.dev.local\n',
      );
    });

    test('IPv6 target is accepted', () {
      expect(
        HostsFileWriter.render([_h(target: '::1', hostname: 'v6.local')]),
        '::1\tv6.local\n',
      );
    });

    test('multiple hosts preserve list order', () {
      final out = HostsFileWriter.render([
        _h(id: 1, hostname: 'a', target: '10.0.0.1'),
        _h(id: 2, hostname: 'b', target: '10.0.0.2'),
      ]);
      expect(out, '10.0.0.1\ta\n10.0.0.2\tb\n');
    });

    test('mix of active/inactive emits only active', () {
      final out = HostsFileWriter.render([
        _h(id: 1, hostname: 'a', target: '10.0.0.1', active: false),
        _h(id: 2, hostname: 'b', target: '10.0.0.2', active: true),
      ]);
      expect(out, '10.0.0.2\tb\n');
    });

    test('invalid target throws with offending ids', () {
      expect(
        () => HostsFileWriter.render([_h(id: 7, target: 'not-an-ip')]),
        throwsA(isA<InvalidHostException>()
            .having((e) => e.offenders, 'offenders', [const InvalidTarget(7, 'not-an-ip')])),
      );
    });

    test('collects all offenders before throwing', () {
      try {
        HostsFileWriter.render([
          _h(id: 1, target: 'bad-1'),
          _h(id: 2, target: 'bad-2'),
        ]);
        fail('should have thrown');
      } on InvalidHostException catch (e) {
        expect(e.offenders.length, 2);
        expect(e.offenders.map((o) => o.id), [1, 2]);
      }
    });
  });
}
