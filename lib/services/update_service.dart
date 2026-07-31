import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher.dart';
import 'update_repository.dart';
import '../models/update_model.dart';

class UpdateService {
  final UpdateRepository _repository = UpdateRepository();

  Future<UpdateModel?> checkForUpdates() async {
    final updateInfo = await _repository.fetchUpdateInfo();
    if (updateInfo == null) return null;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = Version.parse(packageInfo.version);
    final latestVersion = Version.parse(updateInfo.version);

    if (latestVersion > currentVersion) {
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
