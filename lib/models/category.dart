import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 1)
class Category {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name; // Original/Fallback name
  @HiveField(2)
  final String imageUrl;
  @HiveField(3)
  final Map<String, String>? translations; // { 'en': '...', 'tr': '...', 'fa': '...' }

  const Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.translations,
  });

  String localizedName(String locale) {
    if (translations == null) return name;
    final lang = locale.split('_')[0].split('-')[0];
    return translations![lang] ?? 
           translations!['tr'] ?? 
           translations!['en'] ?? 
           name;
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    Map<String, String>? translationsMap;
    final rawTranslations = json['category_translations'];
    
    if (rawTranslations is Iterable) {
      translationsMap = {};
      for (final t in rawTranslations) {
        if (t is Map) {
          final code = t['language_code']?.toString();
          final name = t['name']?.toString();
          if (code != null && code.isNotEmpty && name != null) {
            translationsMap[code] = name;
          }
        }
      }
    }

    return Category(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      translations: translationsMap,
    );
  }
}
