import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/address.dart';
import '../../services/location_service.dart';

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
  CheckoutNotifier() : super(CheckoutState());

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
}

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  return CheckoutNotifier();
});

final locationServiceProvider = Provider((ref) => LocationService());
