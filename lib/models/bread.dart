import 'package:hive/hive.dart';
import '../core/design_system/sangak_tokens.dart';

part 'bread.g.dart';

@HiveType(typeId: 0)
class Bread {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String categoryId;
  @HiveField(2)
  final String name; // Original/Fallback name
  @HiveField(3)
  final String description; // Original/Fallback description
  @HiveField(4)
  final double price;
  @HiveField(5)
  final String imageUrl;
  @HiveField(6)
  final bool available;
  @HiveField(7)
  final String? tag;
  @HiveField(8)
  final int prepTime;
  @HiveField(9)
  final int calories;
  @HiveField(10)
  final bool isOrganic;
  @HiveField(11)
  final DateTime? createdAt;
  @HiveField(12)
  final DateTime? updatedAt;
  @HiveField(13)
  final double rating;
  @HiveField(14)
  final int reviews;
  @HiveField(15)
  final Map<String, dynamic>? translations; // { 'en': {'name': '...', 'description': '...'}, ... }
  
  final FreshnessToken? freshness;
  final bool isFavorite;

  const Bread({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.available = true,
    this.tag,
    this.prepTime = 20,
    this.calories = 250,
    this.isOrganic = false,
    this.createdAt,
    this.updatedAt,
    this.rating = 0.0,
    this.reviews = 0,
    this.translations,
    this.freshness,
    this.isFavorite = false,
  });

  String localizedName(String locale) {
    if (translations == null) return name;
    final lang = locale.split('_')[0].split('-')[0];
    return translations![lang]?['name'] ?? 
           translations!['tr']?['name'] ?? 
           translations!['en']?['name'] ?? 
           name;
  }

  String localizedDescription(String locale) {
    if (translations == null) return description;
    final lang = locale.split('_')[0].split('-')[0];
    return translations![lang]?['description'] ?? 
           translations!['tr']?['description'] ?? 
           translations!['en']?['description'] ?? 
           description;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'available': available,
      'tag': tag,
      'prep_time': prepTime,
      'calories': calories,
      'is_organic': isOrganic,
      'translations': translations,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  factory Bread.fromJson(Map<String, dynamic> json) {
    // Handle translations from Supabase
    Map<String, dynamic>? translationsMap;
    final rawTranslations = json['product_translations'];
    
    if (rawTranslations is Iterable) {
      translationsMap = {};
      for (final t in rawTranslations) {
        if (t is Map) {
          final code = t['language_code']?.toString();
          if (code == null || code.isEmpty) continue;
          translationsMap[code] = {
            'name': t['name']?.toString(),
            'description': t['description']?.toString(),
          };
        }
      }
    }

    return Bread(
      id: json['id'] as String,
      categoryId: json['category_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: _toDouble(json['price']),
      imageUrl: json['image_url'] as String? ?? '',
      available: json['available'] as bool? ?? true,
      tag: json['tag'] as String?,
      prepTime: _toInt(json['prep_time'], 20),
      calories: _toInt(json['calories'], 250),
      isOrganic: json['is_organic'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      rating: _toDouble(json['rating']),
      reviews: _toInt(json['reviews'], 0),
      translations: translationsMap,
    );
  }

  Bread copyWith({
    bool? isFavorite,
    String? tag,
    Map<String, dynamic>? translations,
  }) {
    return Bread(
      id: id,
      categoryId: categoryId,
      name: name,
      description: description,
      price: price,
      imageUrl: imageUrl,
      available: available,
      tag: tag ?? this.tag,
      prepTime: prepTime,
      calories: calories,
      isOrganic: isOrganic,
      createdAt: createdAt,
      updatedAt: updatedAt,
      rating: rating,
      reviews: reviews,
      translations: translations ?? this.translations,
      freshness: freshness,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
