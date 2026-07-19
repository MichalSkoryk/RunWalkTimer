import 'package:flutter/services.dart';

import '../models/workout_plan.dart';
import '../models/sound_settings.dart';

class DeviceFeedbackService {
  static const _channel = MethodChannel('run_walk_timer/device');

  Future<void> playPhaseCue(
    WorkoutPhase phase, {
    required bool soundEnabled,
    required SoundSettings soundSettings,
  }) async {
    if (soundEnabled) {
      await _playNativeCue(
        phase.name,
        phase == WorkoutPhase.walk
            ? soundSettings.walkCue.id
            : soundSettings.runCue.id,
      );
    }

    try {
      if (phase == WorkoutPhase.walk) {
        await HapticFeedback.lightImpact();
      } else {
        await HapticFeedback.mediumImpact();
        await Future<void>.delayed(const Duration(milliseconds: 90));
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {
      // Haptics are helpful feedback, but never allowed to affect the timer.
    }
  }

  Future<void> playCompletionCue({
    required bool soundEnabled,
    required SoundSettings soundSettings,
  }) async {
    if (soundEnabled) {
      await _playNativeCue('complete', soundSettings.completionCue.id);
    }
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {
      // Some devices do not expose haptics.
    }
  }

  Future<void> setKeepScreenOn(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setKeepScreenOn', <String, Object>{
        'enabled': enabled,
      });
    } catch (_) {
      // The timer remains accurate without this convenience feature.
    }
  }

  Future<void> _playNativeCue(String cue, String soundId) async {
    try {
      await _channel.invokeMethod<void>('playCue', <String, Object>{
        'cue': cue,
        'soundId': soundId,
      });
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {
        // Muted devices or unsupported platforms should not stop a workout.
      }
    }
  }
}
