import 'package:flutter_test/flutter_test.dart';
import 'package:run_walk_timer/controllers/workout_timer_controller.dart';
import 'package:run_walk_timer/models/background_workout_state.dart';
import 'package:run_walk_timer/models/metronome_config.dart';
import 'package:run_walk_timer/models/sound_settings.dart';
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
      expect(bridge.lastSoundSettings, const SoundSettings.defaults());
      expect(controller.status, WorkoutStatus.running);

      controller.skipPhase();
      await _flushAsyncWork();
      expect(bridge.skipCalls, 1);

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

  test('live BPM updates the plan and forwards the current phase', () async {
    final bridge = _FakeBackgroundBridge();
    final controller = WorkoutTimerController(backgroundBridge: bridge);
    final metronomePlan = WorkoutPlan.intervals(
      walkDuration: const Duration(seconds: 10),
      runDuration: const Duration(seconds: 20),
      intervalCount: 2,
      walkMetronome: const MetronomeConfig(enabled: true, bpm: 100),
    );

    controller.start(metronomePlan);
    await _flushAsyncWork();
    controller.updateCurrentPhaseBpm(101);
    await _flushAsyncWork();

    expect(controller.plan!.walkMetronome.bpm, 101);
    expect(bridge.bpmUpdates, [(WorkoutPhase.walk, 101)]);
    controller.dispose();
  });

  test('fallback skip advances to the boundary and stays paused', () async {
    final bridge = _FakeBackgroundBridge()..startSucceeds = false;
    final controller = WorkoutTimerController(backgroundBridge: bridge);

    controller.start(plan);
    await _flushAsyncWork();
    controller.pause();
    controller.skipPhase();

    expect(controller.status, WorkoutStatus.paused);
    expect(controller.snapshot!.phase, WorkoutPhase.run);
    expect(controller.snapshot!.activeElapsed, const Duration(seconds: 10));
    expect(controller.snapshot!.totalRemaining, const Duration(seconds: 50));
    controller.dispose();
  });

  test('fallback skip completes when the goal ends in this phase', () async {
    final bridge = _FakeBackgroundBridge()..startSucceeds = false;
    final controller = WorkoutTimerController(backgroundBridge: bridge);
    final timedPlan = WorkoutPlan.timed(
      walkDuration: const Duration(seconds: 10),
      runDuration: const Duration(seconds: 20),
      timeLimit: const Duration(seconds: 5),
    );

    controller.start(timedPlan);
    await _flushAsyncWork();
    controller.pause();
    controller.skipPhase();

    expect(controller.status, WorkoutStatus.complete);
    expect(controller.snapshot!.totalRemaining, Duration.zero);
    controller.dispose();
  });

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
    expect(state.plan.walkMetronome.enabled, isFalse);
    expect(state.plan.walkMetronome.bpm, MetronomeConfig.defaultWalkBpm);
    expect(state.plan.runMetronome.enabled, isFalse);
    expect(state.plan.runMetronome.bpm, MetronomeConfig.defaultRunBpm);
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
  int skipCalls = 0;
  bool startSucceeds = true;
  final List<bool> soundUpdates = [];
  final List<(WorkoutPhase, int)> bpmUpdates = [];
  BackgroundWorkoutState? currentState;
  SoundSettings? lastSoundSettings;

  @override
  Future<bool> startSession({
    required WorkoutPlan plan,
    required bool soundEnabled,
    required SoundSettings soundSettings,
  }) async {
    startCalls += 1;
    lastSoundSettings = soundSettings;
    return startSucceeds;
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
  Future<void> skipPhase() async {
    skipCalls += 1;
  }

  @override
  Future<void> updateMetronomeBpm(WorkoutPhase phase, int bpm) async {
    bpmUpdates.add((phase, bpm));
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
