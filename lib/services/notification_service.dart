import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:sangak/services/supabase_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  static const String _vapidKey = "BNHrwRsL1x2epjPB3wbQeIPMWYHjG-eJoz-KX9srAO_jPyC_2uMWXuXgPt_qR5UnEdp104L6y7Hvr4753-kxgUs";

  static Future<void> initialize() async {
    try {
      // Note: On web, ensure you've added the Firebase SDK and Service Worker
      // For mobile, ensure google-services.json and GoogleService-Info.plist are present
      
      // Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Request permissions (especially important for iOS)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('🔔 FCM: User granted permission');
        
        // Get token
        String? token = await _messaging.getToken(
          vapidKey: kIsWeb ? _vapidKey : null,
        );
        if (token != null) {
          debugPrint('🔔 FCM Token: $token');
          await _saveTokenToSupabase(token);
        }
      } else {
        debugPrint('🔔 FCM: User declined or has not accepted permission');
      }

      // Handle token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToSupabase(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 FCM Foreground Message: ${message.notification?.title}');
        // You can show a local notification here if needed
      });

      // Handle background message clicks
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 FCM Message opened app: ${message.notification?.title}');
      });

    } catch (e) {
      debugPrint('🚨 FCM Initialization Error: $e');
    }
  }

  static Future<void> _saveTokenToSupabase(String token) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        // We store tokens in a separate table 'user_push_tokens' or update profile
        // Assuming a table structure for multiple devices per user
        await SupabaseService.client.from('profiles').update({
          'fcm_token': token,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
        debugPrint('🔔 FCM: Token synced with Supabase profile');
      }
    } catch (e) {
      debugPrint('🚨 FCM: Error saving token to Supabase: $e');
    }
  }

  /// Optional: Get token manually if needed
  static Future<String?> getToken() async => await _messaging.getToken(
    vapidKey: kIsWeb ? _vapidKey : null,
  );
}
