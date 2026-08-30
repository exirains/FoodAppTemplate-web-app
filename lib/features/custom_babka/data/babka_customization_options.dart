import '../../../models/babka_customization.dart';

final List<BabkaCustomizationOption> babkaCustomizationOptions = [
  const BabkaCustomizationOption(
    id: 'sesame',
    name: 'Sesame',
    price: 5.0,
    category: CustomizationCategory.seeds,
    maxQuantity: 2,
    layers: {
      1: 'lib/assets/images/customization/babka/sesame/sesame_normal.png',
      2: 'lib/assets/images/customization/babka/sesame/sesame_extra.png',
    },
  ),
  const BabkaCustomizationOption(
    id: 'nigella',
    name: 'Nigella',
    price: 4.0,
    category: CustomizationCategory.seeds,
    maxQuantity: 2,
    layers: {
      1: 'lib/assets/images/customization/babka/nigella/nigella_normal.png',
      2: 'lib/assets/images/customization/babka/nigella/nigella_extra.png',
    },
  ),
  const BabkaCustomizationOption(
    id: 'cheese',
    name: 'Cheese',
    price: 15.0,
    category: CustomizationCategory.extras,
    maxQuantity: 1,
    layers: {
      1: 'lib/assets/images/customization/babka/cheese/cheese.png',
    },
  ),
  const BabkaCustomizationOption(
    id: 'herbs',
    name: 'Herbs',
    price: 10.0,
    category: CustomizationCategory.extras,
    maxQuantity: 1,
    layers: {
      1: 'lib/assets/images/customization/babka/herbs/herbs.png',
    },
  ),
];


