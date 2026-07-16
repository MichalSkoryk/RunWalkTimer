import 'package:flutter_test/flutter_test.dart';
import 'package:run_walk_timer/controllers/workout_timer_controller.dart';
import 'package:run_walk_timer/models/background_workout_state.dart';
import 'package:run_walk_timer/models/workout_plan.dart';
import 'package:run_walk_timer/services/background_workout_bridge.dart';

void main() {
  final plan = WorkoutPlan.intervals(
    walkDuration: const Duration(seconds: 10),
    runDuration: const Duration(seconds: 20),
    intervalCount: 2,
  );

  test(
    'controller forwards explicit commands to the background service',
    () async {
      final bridge = _FakeBackgroundBridge();
      final controller = WorkoutTimerController(backgroundBridge: bridge);

      controller.start(plan);
      await _flushAsyncWork();
      expect(bridge.startCalls, 1);
      expect(controller.status, WorkoutStatus.running);

      controller.pause();
      await _flushAsyncWork();
      expect(bridge.pauseCalls, 1);
      expect(controller.status, WorkoutStatus.paused);

      controller.resume();
      controller.setSoundEnabled(false);
      await _flushAsyncWork();
      expect(bridge.resumeCalls, 1);
      expect(bridge.soundUpdates, [false]);

      controller.stop();
      await _flushAsyncWork();
      expect(bridge.stopCalls, 1);
      expect(controller.status, WorkoutStatus.idle);

      controller.dispose();
    },
  );

  test('notification actions project authoritative state into Flutter', () {
    final bridge = _FakeBackgroundBridge();
    final controller = WorkoutTimerController(backgroundBridge: bridge);

    bridge.emit(
      BackgroundWorkoutState(
        status: BackgroundWorkoutStatus.running,
        plan: plan,
        elapsed: const Duration(seconds: 12),
        soundEnabled: true,
        sessionId: 100,
      ),
    );
    expect(controller.status, WorkoutStatus.running);
    expect(controller.snapshot!.phase, WorkoutPhase.run);
    expect(controller.snapshot!.displayRemaining, const Duration(seconds: 18));

    bridge.emit(
      BackgroundWorkoutState(
        status: BackgroundWorkoutStatus.paused,
        plan: plan,
        elapsed: const Duration(seconds: 13),
        soundEnabled: false,
        sessionId: 100,
      ),
    );
    expect(controller.status, WorkoutStatus.paused);
    expect(controller.soundEnabled, isFalse);

    bridge.emit(
      BackgroundWorkoutState(
        status: BackgroundWorkoutStatus.idle,
        plan: plan,
        elapsed: Duration.zero,
        soundEnabled: false,
        sessionId: 100,
      ),
    );
    expect(controller.status, WorkoutStatus.idle);
    expect(controller.snapshot!.displayRemaining, const Duration(seconds: 10));

    controller.dispose();
  });

  test('background state decodes a timed plan', () {
    final state = BackgroundWorkoutState.fromMap(<String, Object?>{
      'status': 'paused',
      'walkMs': 30000,
      'runMs': 60000,
      'targetMs': 300000,
      'limitMode': 'time',
      'intervalCount': null,
      'elapsedMs': 45000,
      'soundEnabled': false,
      'sessionId': 42,
      'notificationsEnabled': false,
    });

    expect(state.status, BackgroundWorkoutStatus.paused);
    expect(state.plan.limitMode, WorkoutLimitMode.time);
    expect(state.plan.timeLimit, const Duration(minutes: 5));
    expect(state.elapsed, const Duration(seconds: 45));
    expect(state.soundEnabled, isFalse);
    expect(state.notificationsEnabled, isFalse);
  });

  test('native completion becomes terminal without sending an extra stop', () {
    final bridge = _FakeBackgroundBridge();
    final controller = WorkoutTimerController(backgroundBridge: bridge);

    bridge.emit(
      BackgroundWorkoutState(
        status: BackgroundWorkoutStatus.complete,
        plan: plan,
        elapsed: plan.targetDuration,
        soundEnabled: true,
        sessionId: 150,
      ),
    );

    expect(controller.status, WorkoutStatus.complete);
    expect(controller.isInProgress, isFalse);
    expect(controller.snapshot!.displayRemaining, Duration.zero);
    expect(controller.snapshot!.totalRemaining, Duration.zero);
    expect(bridge.stopCalls, 0);
    controller.dispose();
  });

  test('stop clears a completed native session', () async {
    final bridge = _FakeBackgroundBridge();
    final controller = WorkoutTimerController(backgroundBridge: bridge);

    bridge.emit(
      BackgroundWorkoutState(
        status: BackgroundWorkoutStatus.complete,
        plan: plan,
        elapsed: plan.targetDuration,
        soundEnabled: true,
        sessionId: 200,
      ),
    );

    controller.stop();
    await _flushAsyncWork();

    expect(bridge.stopCalls, 1);
    expect(controller.status, WorkoutStatus.idle);
    controller.dispose();
  });
}

Future<void> _flushAsyncWork() {
  return Future<void>.delayed(Duration.zero);
}

class _FakeBackgroundBridge implements BackgroundWorkoutBridge {
  @override
  void Function(BackgroundWorkoutState state)? onStateChanged;

  int startCalls = 0;
  int pauseCalls = 0;
  int resumeCalls = 0;
  int stopCalls = 0;
  final List<bool> soundUpdates = [];
  BackgroundWorkoutState? currentState;

  @override
  Future<bool> startSession({
    required WorkoutPlan plan,
    required bool soundEnabled,
  }) async {
    startCalls += 1;
    return true;
  }

  @override
  Future<void> pauseSession() async {
    pauseCalls += 1;
  }

  @override
  Future<void> resumeSession() async {
    resumeCalls += 1;
  }

  @override
  Future<void> stopSession() async {
    stopCalls += 1;
  }

  @override
  Future<void> updateSound(bool enabled) async {
    soundUpdates.add(enabled);
  }

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<BackgroundWorkoutState?> getState() async => currentState;

  void emit(BackgroundWorkoutState state) {
    currentState = state;
    onStateChanged?.call(state);
  }

  @override
  void dispose() {
    onStateChanged = null;
  }
}
