class UpdateModel {
  final String appName;
  final String version;
  final int buildNumber;
  final bool forceUpdate;
  final String apkUrl;
  final List<String> notes;

  UpdateModel({
    required this.appName,
    required this.version,
    required this.buildNumber,
    required this.forceUpdate,
    required this.apkUrl,
    required this.notes,
  });

  factory UpdateModel.fromJson(Map<String, dynamic> json) {
    return UpdateModel(
      appName: json['app_name'] as String,
      version: json['version'] as String,
      buildNumber: json['build_number'] as int,
      forceUpdate: json['force_update'] as bool,
      apkUrl: json['apk_url'] as String,
      notes: (json['notes'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }
}
