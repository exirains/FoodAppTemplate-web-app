import 'package:flutter_test/flutter_test.dart';
import 'package:sangak/models/sangak_customization.dart';

void main() {
  group('SangakCustomization', () {
    const baseBreadId = 'plain-sangak';
    const baseBreadName = 'Plain Sangak';
    const basePrice = 50.0;

    test('should calculate total price correctly with no options', () {
      final customization = SangakCustomization(
        baseBreadId: baseBreadId,
        baseBreadName: baseBreadName,
        basePrice: basePrice,
      );

      expect(customization.totalPrice, basePrice);
    });

    test('should calculate total price correctly with multiple options', () {
      // Manual calculation: 50 + (5*2) + (4*1) = 64
      final customization = SangakCustomization(
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
