import 'package:flutter/foundation.dart';

enum CustomizationCategory {
  base,
  seeds,
  extras,
}

class SangakCustomizationOption {
  final String id;
  final String name;
  final double price;
  final CustomizationCategory category;
  final int maxQuantity;
  /// Mapping from quantity/intensity level to asset path.
  /// 0 is usually 'none' (empty string or omitted).
  /// 1 -> 'assets/images/customization/sangak/sesame/sesame_normal.webp'
  final Map<int, String> layers;

  const SangakCustomizationOption({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.maxQuantity = 1,
    this.layers = const {},
  });

  String? getLayerForQuantity(int quantity) => layers[quantity];
}

class SangakCustomization {
  final String baseBreadId;
  final String baseBreadName;
  final double basePrice;
  final Map<String, int> selectedOptions; // optionId -> quantity
  final double extrasPrice; // Pre-calculated sum of all option prices

  const SangakCustomization({
    required this.baseBreadId,
    required this.baseBreadName,
    required this.basePrice,
    this.selectedOptions = const {},
    this.extrasPrice = 0.0,
  });

  double get totalPrice => basePrice + extrasPrice;

  SangakCustomization copyWith({
    String? baseBreadId,
    String? baseBreadName,
    double? basePrice,
    Map<String, int>? selectedOptions,
    double? extrasPrice,
  }) {
    return SangakCustomization(
      baseBreadId: baseBreadId ?? this.baseBreadId,
      baseBreadName: baseBreadName ?? this.baseBreadName,
      basePrice: basePrice ?? this.basePrice,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      extrasPrice: extrasPrice ?? this.extrasPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_bread_id': baseBreadId,
      'base_bread_name': baseBreadName,
      'base_price': basePrice,
      'selected_options': selectedOptions,
      'extras_price': extrasPrice,
    };
  }

  factory SangakCustomization.fromJson(Map<String, dynamic> json) {
    return SangakCustomization(
      baseBreadId: json['base_bread_id'] as String,
      baseBreadName: json['base_bread_name'] as String,
      basePrice: (json['base_price'] as num).toDouble(),
      selectedOptions: Map<String, int>.from(json['selected_options'] as Map),
      extrasPrice: (json['extras_price'] as num? ?? 0.0).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SangakCustomization &&
          runtimeType == other.runtimeType &&
          baseBreadId == other.baseBreadId &&
          mapEquals(selectedOptions, other.selectedOptions);

  @override
  int get hashCode => baseBreadId.hashCode ^ selectedOptions.hashCode;
}
