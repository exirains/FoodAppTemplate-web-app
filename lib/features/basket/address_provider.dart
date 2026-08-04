import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/address.dart';
import '../../services/address_repository.dart';
import '../auth/auth_provider.dart';

final addressRepositoryProvider = Provider((ref) => AddressRepository());

final savedAddressesProvider = FutureProvider<List<Address>>((ref) async {
  final user = ref.watch(authProvider).asData?.value;
  if (user == null) return [];

  final repo = ref.read(addressRepositoryProvider);
  return await repo.getSavedAddresses(user.id);
});

class AddressNotifier extends StateNotifier<AsyncValue<List<Address>>> {
  final Ref _ref;
  AddressNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final user = _ref.read(authProvider).asData?.value;
    if (user == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final addresses = await _ref.read(addressRepositoryProvider).getSavedAddresses(user.id);
      state = AsyncValue.data(addresses);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> saveAddress(Address address) async {
    final user = _ref.read(authProvider).asData?.value;
    if (user == null) {
      debugPrint('Address save skipped: No authenticated user');
      return;
    }

    try {
      debugPrint('Syncing address to Supabase for user: ${user.id}');
      final updatedAddress = address.copyWith(userId: user.id);
      
      await _ref.read(addressRepositoryProvider).saveAddress(updatedAddress);
      debugPrint('Address saved successfully to Supabase');
      
      await _loadAddresses();
    } catch (e) {
      debugPrint('CRITICAL Error saving address to Supabase: $e');
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      await _ref.read(addressRepositoryProvider).deleteAddress(addressId);
      await _loadAddresses();
    } catch (e) {
      // Log error but don't break UI
      debugPrint('Error background deleting address: $e');
    }
  }
}

final addressListProvider = StateNotifierProvider<AddressNotifier, AsyncValue<List<Address>>>((ref) {
  return AddressNotifier(ref);
});
