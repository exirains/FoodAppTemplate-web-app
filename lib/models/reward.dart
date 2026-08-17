class Reward {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final bool isActive;
  final String? imageUrl;
  final DateTime createdAt;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    this.isActive = true,
    this.imageUrl,
    required this.createdAt,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      pointsCost: json['points_cost'] as int,
      isActive: json['is_active'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'points_cost': pointsCost,
      'is_active': isActive,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
