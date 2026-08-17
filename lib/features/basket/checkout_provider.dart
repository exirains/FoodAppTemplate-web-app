import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/address.dart';
import '../../services/location_service.dart';
import '../../services/order_repository.dart';
import '../../services/options_repository.dart';
import 'basket_provider.dart';
import '../auth/auth_provider.dart';
import '../orders/orders_provider.dart';

enum PaymentMethod { cash, card, online }

class CheckoutState {
  final Address? selectedAddress;
  final PaymentMethod paymentMethod;
  final bool isSubmitting;
  final int estimatedPrepMinutes;

  CheckoutState({
    this.selectedAddress,
    this.paymentMethod = PaymentMethod.cash,
    this.isSubmitting = false,
    this.estimatedPrepMinutes = 0,
  });

  CheckoutState copyWith({
    Address? selectedAddress,
    PaymentMethod? paymentMethod,
    bool? isSubmitting,
    int? estimatedPrepMinutes,
  }) {
    return CheckoutState(
      selectedAddress: selectedAddress ?? this.selectedAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      estimatedPrepMinutes: estimatedPrepMinutes ?? this.estimatedPrepMinutes,
    );
  }
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final Ref _ref;
  CheckoutNotifier(this._ref) : super(CheckoutState());

  void selectAddress(Address address) {
    state = state.copyWith(selectedAddress: address);
  }

  void selectPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setSubmitting(bool value) {
    state = state.copyWith(isSubmitting: value);
  }

  void setEstimatedPrepMinutes(int minutes) {
    state = state.copyWith(estimatedPrepMinutes: minutes);
  }

  Future<String?> placeOrder() async {
    final user = _ref.read(authProvider).asData?.value;
    if (user == null) throw Exception('User must be logged in to place order');
    if (state.selectedAddress == null) throw Exception('No address selected');
    
    final basket = _ref.read(basketProvider);
    final basketTotal = _ref.read(basketTotalProvider);

    // Minimum Order Limit Check
    final options = _ref.read(appOptionsProvider).value ?? {};
    final minLimit = int.tryParse(options['min_order_limit']?.toString() ?? '0') ?? 0;
    if (basketTotal < minLimit) {
      throw Exception('Minimum order amount is $minLimit TL');
    }

    final total = basketTotal + (double.tryParse(options['delivery_fee']?.toString() ?? '0') ?? 0.0);

    // Generate 2-digit PIN (10-99)
    final deliveryCode = (Random().nextInt(90) + 10).toString();

    setSubmitting(true);
    try {
      final order = await _ref.read(sangakOrderRepositoryProvider).createOrder(
        userId: user.id,
        items: basket,
        address: state.selectedAddress!,
        paymentMethod: state.paymentMethod.name,
        totalPrice: total,
        deliveryCode: deliveryCode,
        estimatedPrepTime: state.estimatedPrepMinutes,
      );
      
      // Clear basket and refresh orders list
      _ref.read(basketProvider.notifier).clear();
      _ref.invalidate(myOrdersProvider);
      return order.id;
    } finally {
      setSubmitting(false);
    }
  }
}

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  return CheckoutNotifier(ref);
});

final locationServiceProvider = Provider((ref) => LocationService());
