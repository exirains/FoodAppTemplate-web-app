import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/supabase_service.dart';
import 'auth_provider.dart';
import 'models/user_profile.dart';

/// Provider that fetches the current user's profile from the 'profiles' table.
/// This ensures we get the most up-to-date role and metadata from the database.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authProvider);
  final user = authState.asData?.value;

  if (user == null) {
    return Stream.value(null);
  }

  try {
    return SupabaseService.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((data) {
          if (data.isEmpty) return null;
          return UserProfile.fromJson(data.first);
        })
        .handleError((error) {
          // Silent fail to avoid debugPrint dependency issues during build
          return null; 
        });
  } catch (e) {
    return Stream.value(null);
  }
});
