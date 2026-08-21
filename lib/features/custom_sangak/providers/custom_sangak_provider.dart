import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/bread.dart';
import '../../../models/sangak_customization.dart';
import '../data/sangak_customization_options.dart';

class CustomSangakNotifier extends StateNotifier<SangakCustomization> {
  CustomSangakNotifier(Bread baseBread)
      : super(SangakCustomization(
          baseBreadId: baseBread.id,
          baseBreadName: baseBread.name,
          basePrice: baseBread.price,
        ));

  void updateOption(String optionId, int quantity) {
    final option = sangakCustomizationOptions.firstWhere((o) => o.id == optionId);
    final newQuantity = quantity.clamp(0, option.maxQuantity);

    final updatedOptions = Map<String, int>.from(state.selectedOptions);
    if (newQuantity == 0) {
      updatedOptions.remove(optionId);
    } else {
      updatedOptions[optionId] = newQuantity;
    }

    // Recalculate extras price
    double newExtrasPrice = 0.0;
    for (final entry in updatedOptions.entries) {
      final opt = sangakCustomizationOptions.firstWhere((o) => o.id == entry.key);
      newExtrasPrice += opt.price * entry.value;
    }

    state = state.copyWith(
      selectedOptions: updatedOptions,
      extrasPrice: newExtrasPrice,
    );
  }

  void changeBase(Bread newBase) {
    // Preserve compatible options if needed, but for now simple swap
    state = state.copyWith(
      baseBreadId: newBase.id,
      baseBreadName: newBase.name,
      basePrice: newBase.price,
    );
  }
}

final customSangakProvider = StateNotifierProvider.autoDispose.family<CustomSangakNotifier, SangakCustomization, Bread>((ref, baseBread) {
  return CustomSangakNotifier(baseBread);
});

/// Resolved layers for the current customization.
final sangakLayersProvider = Provider.family<Map<String, String?>, Bread>((ref, baseBread) {
  final customization = ref.watch(customSangakProvider(baseBread));
  final Map<String, String?> layers = {};

  // 1. Base layer
  layers['base'] = 'lib/assets/images/customization/sangak/base/sangak_plain.png';

  // 2. Ingredient layers
  for (final option in sangakCustomizationOptions) {
    final quantity = customization.selectedOptions[option.id] ?? 0;
    layers[option.id] = option.getLayerForQuantity(quantity);
  }

  return layers;
});
