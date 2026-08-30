import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/bread.dart';
import '../../../models/babka_customization.dart';
import '../data/babka_customization_options.dart';

class CustomBabkaNotifier extends StateNotifier<BabkaCustomization> {
  CustomBabkaNotifier(Bread baseBread)
      : super(BabkaCustomization(
          baseBreadId: baseBread.id,
          baseBreadName: baseBread.name,
          basePrice: baseBread.price,
        ));

  void updateOption(String optionId, int quantity) {
    final option = babkaCustomizationOptions.firstWhere((o) => o.id == optionId);
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
      final opt = babkaCustomizationOptions.firstWhere((o) => o.id == entry.key);
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

final customBabkaProvider = StateNotifierProvider.autoDispose.family<CustomBabkaNotifier, BabkaCustomization, Bread>((ref, baseBread) {
  return CustomBabkaNotifier(baseBread);
});

/// Resolved layers for the current customization.
final babkaLayersProvider = Provider.family<Map<String, String?>, Bread>((ref, baseBread) {
  final customization = ref.watch(customBabkaProvider(baseBread));
  final Map<String, String?> layers = {};

  // 1. Base layer
  layers['base'] = 'lib/assets/images/customization/babka/base/babka_plain.png';

  // 2. Ingredient layers
  for (final option in babkaCustomizationOptions) {
    final quantity = customization.selectedOptions[option.id] ?? 0;
    layers[option.id] = option.getLayerForQuantity(quantity);
  }

  return layers;
});


