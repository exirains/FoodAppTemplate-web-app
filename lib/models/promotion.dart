class Promotion {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final int priority;

  Promotion({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.isActive = true,
    this.startDate,
    this.endDate,
    this.priority = 0,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      priority: json['priority'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'is_active': isActive,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'priority': priority,
    };
  }
}
