import '../core/design_system/sangak_tokens.dart';

class Bread {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool available;
  final String? tag;
  final int prepTime;
  final int calories;
  final bool isOrganic;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double rating;
  final int reviews;
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
    this.freshness,
    this.isFavorite = false,
  });

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
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory Bread.fromJson(Map<String, dynamic> json) {
    return Bread(
      id: json['id'] as String,
      categoryId: json['category_id'] as String? ?? '',
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: _toDouble(json['price']),
      imageUrl: json['image_url'] as String? ?? '',
      available: json['available'] as bool? ?? true,
      tag: json['tag'] as String?,
      prepTime: json['prep_time'] as int? ?? 20,
      calories: json['calories'] as int? ?? 250,
      isOrganic: json['is_organic'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      rating: _toDouble(json['rating']),
      reviews: json['reviews'] as int? ?? 0,
    );
  }

  Bread copyWith({
    bool? isFavorite,
    String? tag,
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
      freshness: freshness,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
