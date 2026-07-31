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

  Bread copyWith({
    bool? isFavorite,
  }) {
    return Bread(
      id: id,
      title: title,
      description: description,
      price: price,
      imageUrl: imageUrl,
      rating: rating,
      reviews: reviews,
      freshness: freshness,
      isFavorite: isFavorite ?? this.isFavorite,
      categoryId: categoryId,
    );
  }
}
