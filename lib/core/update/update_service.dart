import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher.dart';
import 'update_repository.dart';
import 'update_model.dart';

class UpdateService {
  final UpdateRepository _repository = UpdateRepository();

  Future<UpdateModel?> checkForUpdates() async {
    // Only Android should check for APK updates. Avoid Platform.isAndroid on Web.
    if (kIsWeb) return null;
    
    // Check platform without dart:io
    if (defaultTargetPlatform != TargetPlatform.android) return null;

    final updateInfo = await _repository.fetchUpdateInfo();
    if (updateInfo == null) return null;

    // Get local version from PackageInfo
    final packageInfo = await PackageInfo.fromPlatform();
    final localVersion = Version.parse(packageInfo.version);
    final localBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
    
    final remoteVersion = Version.parse(updateInfo.version);
    final remoteBuild = updateInfo.buildNumber;

    debugPrint('Local: $localVersion+$localBuild, Remote: $remoteVersion+$remoteBuild');

    if (remoteVersion > localVersion) {
      return updateInfo;
    } else if (remoteVersion == localVersion && remoteBuild > localBuild) {
      return updateInfo;
    }
    
    return null;
  }

  Future<void> launchUpdateUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
