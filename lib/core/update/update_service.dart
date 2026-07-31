import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/version_config.dart';
import 'update_repository.dart';
import 'update_model.dart';

class UpdateService {
  final UpdateRepository _repository = UpdateRepository();

  Future<UpdateModel?> checkForUpdates() async {
    // Only Android should check for APK updates
    if (kIsWeb || !Platform.isAndroid) return null;

    final updateInfo = await _repository.fetchUpdateInfo();
    if (updateInfo == null) return null;

    // Use VersionConfig as the primary source of truth
    final currentVersion = Version.parse(VersionConfig.version);
    final latestVersion = Version.parse(updateInfo.version);
    
    final currentBuild = VersionConfig.buildNumber;
    final latestBuild = updateInfo.buildNumber;

    // PackageInfo used as fallback/verification
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      debugPrint('System reported version: ${packageInfo.version}+${packageInfo.buildNumber}');
    } catch (e) {
      debugPrint('Failed to get PackageInfo: $e');
    }

    if (latestVersion > currentVersion) {
      return updateInfo;
    } else if (latestVersion == currentVersion && latestBuild > currentBuild) {
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
