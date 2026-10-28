import 'package:package_info_plus/package_info_plus.dart';

/// Reads and caches package metadata exposed by the installed application.
class AppInfoService {
  AppInfoService._();

  static final AppInfoService instance = AppInfoService._();

  String _version = 'Unknown';
  String _buildNumber = 'Unknown';

  String get version => _version;
  String get buildNumber => _buildNumber;
  String get fullVersion {
    if (_version == 'Unknown' || _buildNumber == 'Unknown') return 'Unknown';
    return '$_version+$_buildNumber';
  }

  static Future<void> initialize({
    Future<PackageInfo> Function()? loader,
  }) async {
    try {
      final info = await (loader ?? PackageInfo.fromPlatform)();
      instance
        .._version = info.version.isEmpty ? 'Unknown' : info.version
        .._buildNumber = info.buildNumber.isEmpty
            ? 'Unknown'
            : info.buildNumber;
    } catch (_) {
      instance
        .._version = 'Unknown'
        .._buildNumber = 'Unknown';
    }
  }
}
