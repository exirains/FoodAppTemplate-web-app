import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sangak/services/supabase_service.dart';
import 'package:sangak/services/analytics_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static GlobalKey<NavigatorState>? _navigatorKey;
  static final AnalyticsService _analytics = AnalyticsService();
  
  static const String _vapidKey = "BNHrwRsL1x2epjPB3wbQeIPMWYHjG-eJoz-KX9srAO_jPyC_2uMWXuXgPt_qR5UnEdp104L6y7Hvr4753-kxgUs";

  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('🔔 FCM: User granted permission');
        
        String? token = await _messaging.getToken(
          vapidKey: kIsWeb ? _vapidKey : null,
        );
        if (token != null) {
          debugPrint('🔔 FCM Token: $token');
          await _syncToken(token);
        }
      }

      _messaging.onTokenRefresh.listen((newToken) {
        _syncToken(newToken);
      });

      // Handle background message clicks when app was in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 FCM Message opened app: ${message.data}');
        _logNotificationOpen(message);
        _handleMessageNavigation(message);
      });

      // Handle message when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 FCM Foreground Message: ${message.notification?.title}');
        _logNotificationReceived(message);
        // We don't necessarily need to show an OS notification if user is in app
      });

      // Check if app was opened from a terminated state via notification
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🔔 FCM Initial Message (Terminated): ${initialMessage.data}');
        _logNotificationOpen(initialMessage);
        // Note: Delay slightly to ensure navigation is ready
        Future.delayed(const Duration(seconds: 1), () => _handleMessageNavigation(initialMessage));
      }

    } catch (e) {
      debugPrint('🚨 FCM Initialization Error: $e');
    }
  }

  static void _handleMessageNavigation(RemoteMessage message) {
    final type = message.data['type'];
    if (type == 'new_delivery_order' || message.data['status'] == 'ready') {
      _navigatorKey?.currentState?.pushNamed('/delivery');
    }
  }

  static void _logNotificationReceived(RemoteMessage message) {
    final orderId = message.data['order_id']?.toString();
    final status = message.data['status']?.toString();
    if (orderId != null) {
      _analytics.logDeliveryNotificationReceived(
        orderId: orderId,
        orderStatus: status ?? 'unknown',
        notificationType: message.data['type']?.toString(),
      );
    }
  }

  static void _logNotificationOpen(RemoteMessage message) {
    final orderId = message.data['order_id']?.toString();
    final status = message.data['status']?.toString();
    if (orderId != null) {
      _analytics.logDeliveryNotificationOpened(
        orderId: orderId,
        orderStatus: status ?? 'unknown',
        notificationType: message.data['type']?.toString(),
      );
    }
  }

  static Future<void> _syncToken(String token) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        // Sync to profiles: the single source of truth
        await SupabaseService.client.from('profiles').update({
          'fcm_token': token,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
        
        debugPrint('🔔 FCM: Token synced with Supabase profile');
      }
    } catch (e) {
      debugPrint('🚨 FCM: Error syncing token: $e');
    }
  }

  static Future<String?> getToken() async => await _messaging.getToken(
    vapidKey: kIsWeb ? _vapidKey : null,
  );
}
