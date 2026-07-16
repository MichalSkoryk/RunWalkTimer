import 'package:flutter/services.dart';

import '../models/background_workout_state.dart';
import '../models/workout_plan.dart';

class BackgroundWorkoutBridge {
  BackgroundWorkoutBridge() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  static const _channel = MethodChannel('run_walk_timer/device');

  void Function(BackgroundWorkoutState state)? onStateChanged;

  Future<bool> startSession({
    required WorkoutPlan plan,
    required bool soundEnabled,
  }) async {
    try {
      return await _channel
              .invokeMethod<bool>('startWorkoutService', <String, Object?>{
                'walkMs': plan.walkDuration.inMilliseconds,
                'runMs': plan.runDuration.inMilliseconds,
                'targetMs': plan.targetDuration.inMilliseconds,
                'limitMode': plan.limitMode.name,
                'intervalCount': plan.intervalCount,
                'soundEnabled': soundEnabled,
              }) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> pauseSession() => _sendCommand('pauseWorkoutService');

  Future<void> resumeSession() => _sendCommand('resumeWorkoutService');

  Future<void> stopSession() => _sendCommand('stopWorkoutService');

  Future<void> updateSound(bool enabled) {
    return _sendCommand('setWorkoutServiceSound', <String, Object>{
      'enabled': enabled,
    });
  }

  Future<void> openNotificationSettings() {
    return _sendCommand('openNotificationSettings');
  }

  Future<BackgroundWorkoutState?> getState() async {
    try {
      final raw = await _channel.invokeMethod<Object?>(
        'getWorkoutServiceState',
      );
      if (raw is! Map) {
        return null;
      }
      return BackgroundWorkoutState.fromMap(Map<String, Object?>.from(raw));
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> _sendCommand(
    String method, [
    Map<String, Object>? arguments,
  ]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // Background notifications are Android-only.
    } on PlatformException {
      // The in-app timer remains functional if the native service is absent.
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method != 'workoutServiceStateChanged' || call.arguments is! Map) {
      return;
    }

    final state = BackgroundWorkoutState.fromMap(
      Map<String, Object?>.from(call.arguments as Map),
    );
    onStateChanged?.call(state);
  }

  void dispose() {
    onStateChanged = null;
    _channel.setMethodCallHandler(null);
  }
}
