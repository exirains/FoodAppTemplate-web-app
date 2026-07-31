import '../core/design_system/sangak_tokens.dart';

class Bread {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final double rating;
  final int reviews;
  final FreshnessToken? freshness;
  final bool isFavorite;
  final String categoryId;

  const Bread({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
    this.freshness,
    this.isFavorite = false,
    required this.categoryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviews': reviews,
      'categoryId': categoryId,
    };
  }

  factory Bread.fromJson(Map<String, dynamic> json) {
    return Bread(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviews: json['reviews'] as int,
      categoryId: json['categoryId'] as String,
    );
  }
}
