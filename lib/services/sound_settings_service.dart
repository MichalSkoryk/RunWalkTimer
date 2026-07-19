import 'package:flutter/services.dart';

import '../models/sound_settings.dart';

class SoundSettingsService {
  const SoundSettingsService();

  static const _channel = MethodChannel('run_walk_timer/device');

  Future<SoundSettings> load() async {
    try {
      final raw = await _channel.invokeMethod<Object?>('getSoundSettings');
      if (raw is Map) {
        return SoundSettings.fromMap(raw);
      }
    } on MissingPluginException {
      // Non-Android test and development targets use safe defaults.
    } on PlatformException {
      // Settings are optional; a native read failure should not block a workout.
    }
    return const SoundSettings.defaults();
  }

  Future<bool> save(SoundSettings settings) async {
    try {
      await _channel.invokeMethod<void>('setSoundSettings', settings.toMap());
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> preview({
    required SoundCategory category,
    required String soundId,
  }) async {
    try {
      await _channel.invokeMethod<void>('previewSound', <String, String>{
        'category': category.id,
        'soundId': soundId,
      });
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
