import '../../../models/sangak_customization.dart';

final List<SangakCustomizationOption> sangakCustomizationOptions = [
  const SangakCustomizationOption(
    id: 'sesame',
    name: 'Sesame',
    price: 5.0,
    category: CustomizationCategory.seeds,
    maxQuantity: 2,
    layers: {
      1: 'lib/assets/images/customization/sangak/sesame/sesame_normal.png',
      2: 'lib/assets/images/customization/sangak/sesame/sesame_extra.png',
    },
  ),
  const SangakCustomizationOption(
    id: 'nigella',
    name: 'Nigella',
    price: 4.0,
    category: CustomizationCategory.seeds,
    maxQuantity: 2,
    layers: {
      1: 'lib/assets/images/customization/sangak/nigella/nigella_normal.png',
      2: 'lib/assets/images/customization/sangak/nigella/nigella_extra.png',
    },
  ),
  const SangakCustomizationOption(
    id: 'cheese',
    name: 'Cheese',
    price: 15.0,
    category: CustomizationCategory.extras,
    maxQuantity: 1,
    layers: {
      1: 'lib/assets/images/customization/sangak/cheese/cheese.png',
    },
  ),
  const SangakCustomizationOption(
    id: 'herbs',
    name: 'Herbs',
    price: 10.0,
    category: CustomizationCategory.extras,
    maxQuantity: 1,
    layers: {
      1: 'lib/assets/images/customization/sangak/herbs/herbs.png',
    },
  ),
];
