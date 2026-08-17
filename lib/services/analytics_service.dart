import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: _analytics);

  /// Log custom event
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      debugPrint('📊 [Analytics] Logging event: $name with params: $parameters');
      await _analytics.logEvent(
        name: name,
        parameters: parameters?.cast<String, Object>(),
      );
    } catch (e) {
      debugPrint('🚨 [Analytics] Failed to log event $name: $e');
    }
  }

  /// Log delivery notification received
  Future<void> logDeliveryNotificationReceived({
    required String orderId,
    required String orderStatus,
    String? notificationType,
  }) async {
    await logEvent('delivery_notification_received', parameters: {
      'order_id': orderId,
      'order_status': orderStatus,
      'notification_type': notificationType ?? 'new_delivery_order',
    });
  }

  /// Log delivery notification opened
  Future<void> logDeliveryNotificationOpened({
    required String orderId,
    required String orderStatus,
    String? notificationType,
  }) async {
    await logEvent('delivery_notification_opened', parameters: {
      'order_id': orderId,
      'order_status': orderStatus,
      'notification_type': notificationType ?? 'new_delivery_order',
    });
  }

  /// Log delivery pickup started
  Future<void> logDeliveryPickupStarted({
    required String orderId,
  }) async {
    await logEvent('delivery_notification_pickup_started', parameters: {
      'order_id': orderId,
      'notification_type': 'new_delivery_order',
    });
  }

  /// Log delivery completed
  Future<void> logDeliveryCompleted({
    required String orderId,
  }) async {
    await logEvent('delivery_notification_delivery_completed', parameters: {
      'order_id': orderId,
    });
  }

  /// Set user ID for analytics
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      debugPrint('🚨 [Analytics] Failed to set user ID: $e');
    }
  }

  /// Set user property
  Future<void> setUserProperty({required String name, required String value}) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('🚨 [Analytics] Failed to set user property $name: $e');
    }
  }
}

final analyticsServiceProvider = Provider((ref) => AnalyticsService());
