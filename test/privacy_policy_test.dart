import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public privacy policy matches the local-first release', () {
    final policy = File('docs/privacy-policy.md').readAsStringSync();

    expect(policy, contains('We do not collect or transmit your personal'));
    expect(policy, contains('encrypted by default'));
    expect(policy, contains('cannot recover it if forgotten'));
    expect(policy, contains('App Lock is optional'));
    expect(policy, contains('does not receive, collect, or store'));
    expect(policy, contains('Backups are not automatically uploaded'));
    expect(policy, contains('sagarkalel4141@gmail.com'));
  });
}
