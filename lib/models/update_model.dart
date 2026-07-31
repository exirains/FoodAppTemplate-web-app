class UpdateModel {
  final String version;
  final int versionCode;
  final bool forceUpdate;
  final String apkUrl;
  final List<String> changelog;

  UpdateModel({
    required this.version,
    required this.versionCode,
    required this.forceUpdate,
    required this.apkUrl,
    required this.changelog,
  });

  factory UpdateModel.fromJson(Map<String, dynamic> json) {
    return UpdateModel(
      version: json['version'] as String,
      versionCode: json['versionCode'] as int,
      forceUpdate: json['forceUpdate'] as bool,
      apkUrl: json['apkUrl'] as String,
      changelog: (json['changelog'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }
}
