import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/address.dart';
import '../../services/location_service.dart';
import '../../services/order_repository.dart';
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

  Future<void> placeOrder() async {
    final user = _ref.read(authProvider).asData?.value;
    if (user == null) throw Exception('User must be logged in to place order');
    if (state.selectedAddress == null) throw Exception('No address selected');
    
    final basket = _ref.read(basketProvider);
    final total = _ref.read(basketTotalProvider) + 15.0; // Including delivery fee

    setSubmitting(true);
    try {
      await _ref.read(orderRepositoryProvider).createOrder(
        userId: user.id,
        items: basket,
        address: state.selectedAddress!,
        paymentMethod: state.paymentMethod.name,
        totalPrice: total,
        estimatedPrepTime: state.estimatedPrepMinutes,
      );
      
      // Clear basket and refresh orders list
      _ref.read(basketProvider.notifier).clear();
      _ref.invalidate(myOrdersProvider);
    } finally {
      setSubmitting(false);
    }
  }
}

final orderRepositoryProvider = Provider((ref) => OrderRepository());

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  return CheckoutNotifier(ref);
});

final locationServiceProvider = Provider((ref) => LocationService());
