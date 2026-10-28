import 'package:borrow_ledger/core/services/app_info_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  test('reads and formats installed package metadata', () async {
    await AppInfoService.initialize(
      loader: () async => PackageInfo(
        appName: 'HisaabMate',
        packageName: 'com.example.hisaabmate',
        version: '1.0.1',
        buildNumber: '2',
      ),
    );

    expect(AppInfoService.instance.version, '1.0.1');
    expect(AppInfoService.instance.buildNumber, '2');
    expect(AppInfoService.instance.fullVersion, '1.0.1+2');
  });

  test('falls back to Unknown when package metadata fails', () async {
    await AppInfoService.initialize(
      loader: () => Future<PackageInfo>.error(StateError('unavailable')),
    );

    expect(AppInfoService.instance.version, 'Unknown');
    expect(AppInfoService.instance.buildNumber, 'Unknown');
    expect(AppInfoService.instance.fullVersion, 'Unknown');
  });
}
