import 'package:flutter/foundation.dart';

/// Rate limiter for authentication attempts
/// Implements exponential backoff for failed attempts
class AuthRateLimiter {
  static const int maxAttempts = 5;
  static const Duration initialDelay = Duration(seconds: 60);
  static const Duration maxDelay = Duration(minutes: 30);
  static const double backoffMultiplier = 2.0;

  final Map<String, List<DateTime>> _attemptHistory = {};
  final Map<String, int> _failureCount = {};
  final Map<String, DateTime> _blockUntil = {};

  /// Check if an action (login/register) is allowed for a given key
  /// key: typically email address
  /// Returns true if action is allowed, false if rate limited
  bool isAllowed(String key) {
    final now = DateTime.now();

    // Check if currently blocked
    if (_blockUntil.containsKey(key)) {
      final blockTime = _blockUntil[key]!;
      if (now.isBefore(blockTime)) {
        return false;
      } else {
        // Block period expired, reset
        _blockUntil.remove(key);
        _failureCount[key] = 0;
        _attemptHistory.remove(key);
      }
    }

    return true;
  }

  /// Get remaining seconds until the user can try again
  /// Returns 0 if user is not blocked
  int getSecondsUntilRetry(String key) {
    if (!_blockUntil.containsKey(key)) return 0;

    final blockTime = _blockUntil[key]!;
    final now = DateTime.now();

    if (now.isAfter(blockTime)) return 0;

    return blockTime.difference(now).inSeconds;
  }

  /// Record a failed attempt
  /// Automatically blocks after maxAttempts with exponential backoff
  void recordFailure(String key) {
    _failureCount[key] = (_failureCount[key] ?? 0) + 1;
    final failureCount = _failureCount[key]!;

    if (failureCount >= maxAttempts) {
      // Calculate exponential backoff
      final delayMultiplier = 1 << (failureCount - maxAttempts); // 2^(failures - maxAttempts)
      var delay = initialDelay * delayMultiplier;

      // Cap at maxDelay
      if (delay > maxDelay) delay = maxDelay;

      _blockUntil[key] = DateTime.now().add(delay);

      if (kDebugMode) {
        print('AuthRateLimiter: Blocked $key for ${delay.inSeconds} seconds');
      }
    }
  }

  /// Record a successful attempt (resets counter)
  void recordSuccess(String key) {
    _failureCount[key] = 0;
    _attemptHistory.remove(key);
    _blockUntil.remove(key);

    if (kDebugMode) {
      print('AuthRateLimiter: Reset counter for $key');
    }
  }

  /// Get current failure count for a key
  int getFailureCount(String key) {
    return _failureCount[key] ?? 0;
  }

  /// Clear all history for a key
  void reset(String key) {
    _attemptHistory.remove(key);
    _failureCount.remove(key);
    _blockUntil.remove(key);
  }

  /// Clear all history
  void resetAll() {
    _attemptHistory.clear();
    _failureCount.clear();
    _blockUntil.clear();
  }
}

/// Global rate limiter instance
final authRateLimiter = AuthRateLimiter();
