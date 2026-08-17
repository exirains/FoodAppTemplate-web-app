import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AlertService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _debounceTimer;

  AlertService() {
    _audioPlayer.audioCache.prefix = '';
  }

  /// Triggers a chime sound and vibration with debouncing
  void triggerNewOrderAlert({
    String assetPath = 'lib/assets/audio/sangak_chime.mp3',
    int vibrationDuration = 500,
    int debounceMs = 600,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: debounceMs), () async {
      try {
        debugPrint('🔔 [AlertService] Alert triggered!');
        
        // Play chime
        await _audioPlayer.play(
          AssetSource(assetPath),
          volume: 1.0,
        );

        // Vibrate if supported
        if (await Vibration.hasVibrator() == true) {
          Vibration.vibrate(duration: vibrationDuration);
        }
      } catch (e) {
        debugPrint('🚨 [AlertService] Alert failed: $e');
      }
    });
  }

  void dispose() {
    _debounceTimer?.cancel();
    _audioPlayer.dispose();
  }
}

final alertServiceProvider = Provider((ref) {
  final service = AlertService();
  ref.onDispose(() => service.dispose());
  return service;
});
