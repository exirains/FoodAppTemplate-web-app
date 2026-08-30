import 'package:flutter_test/flutter_test.dart';
import 'package:babka/models/babka_customization.dart';

void main() {
  group('BabkaCustomization', () {
    const baseBreadId = 'plain-Babka';
    const baseBreadName = 'Plain Babka';
    const basePrice = 50.0;

    test('should calculate total price correctly with no options', () {
      final customization = BabkaCustomization(
        baseBreadId: baseBreadId,
        baseBreadName: baseBreadName,
        basePrice: basePrice,
      );

      expect(customization.totalPrice, basePrice);
    });

    test('should calculate total price correctly with multiple options', () {
      // Manual calculation: 50 + (5*2) + (4*1) = 64
      final customization = BabkaCustomization(
        baseBreadId: baseBreadId,
        baseBreadName: baseBreadName,
        basePrice: basePrice,
        selectedOptions: {
          'sesame': 2,
          'nigella': 1,
        },
        extrasPrice: 14.0,
      );

      expect(customization.totalPrice, 64.0);
    });
  });
}

