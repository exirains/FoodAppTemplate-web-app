import 'package:flutter/foundation.dart';
import '../models/address.dart';
import 'supabase_service.dart';

class AddressRepository {
  final _client = SupabaseService.client;

  /// Fetches saved addresses for a user from Supabase
  Future<List<Address>> getSavedAddresses(String userId) async {
    try {
      final response = await _client
          .from('user_addresses')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      return (response as List).map((e) => Address.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching addresses from Supabase: $e');
      rethrow;
    }
  }

  /// Saves or updates an address in Supabase
  Future<Address> saveAddress(Address address) async {
    try {
      final data = address.toJson();
      
      // Explicitly handle conflict on (user_id, label) to prevent 23505 errors
      final response = await _client
          .from('user_addresses')
          .upsert(data, onConflict: 'user_id,label')
          .select();

      if (response.isEmpty) {
        throw Exception('No data returned from address upsert');
      }

      return Address.fromJson(response.first);
    } catch (e) {
      debugPrint('Error saving address to Supabase: $e');
      rethrow;
    }
  }

  /// Deletes an address from Supabase
  Future<void> deleteAddress(String addressId) async {
    try {
      await _client.from('user_addresses').delete().eq('id', addressId);
    } catch (e) {
      debugPrint('Error deleting address from Supabase: $e');
      rethrow;
    }
  }
}
