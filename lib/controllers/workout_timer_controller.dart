import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/workout_timeline.dart';
import '../models/background_workout_state.dart';
import '../models/metronome_config.dart';
import '../models/sound_settings.dart';
import '../models/workout_plan.dart';
import '../models/workout_snapshot.dart';
import '../services/background_workout_bridge.dart';
import '../services/device_feedback_service.dart';

class WorkoutTimerController extends ChangeNotifier {
  WorkoutTimerController({
    DeviceFeedbackService? feedbackService,
    BackgroundWorkoutBridge? backgroundBridge,
  }) : _feedbackService = feedbackService ?? DeviceFeedbackService(),
       _backgroundBridge = backgroundBridge ?? BackgroundWorkoutBridge() {
    _backgroundBridge.onStateChanged = _applyBackgroundState;
  }

  final DeviceFeedbackService _feedbackService;
  final BackgroundWorkoutBridge _backgroundBridge;
  final Stopwatch _activeLeg = Stopwatch();

  Timer? _ticker;
  WorkoutPlan? _plan;
  WorkoutSnapshot? _snapshot;
  Duration _bankedElapsed = Duration.zero;
  bool _soundEnabled = true;
  SoundSettings _soundSettings = const SoundSettings.defaults();
  bool _notificationsEnabled = true;
  bool _backgroundServiceActive = false;
  int _backgroundSessionId = 0;

  WorkoutPlan? get plan => _plan;
  WorkoutSnapshot? get snapshot => _snapshot;
  WorkoutStatus get status => _snapshot?.status ?? WorkoutStatus.idle;
  bool get soundEnabled => _soundEnabled;
  bool get notificationsEnabled => _notificationsEnabled;

  bool get isInProgress =>
      status == WorkoutStatus.running || status == WorkoutStatus.paused;

  void setSoundEnabled(bool enabled) {
    if (_soundEnabled == enabled) {
      return;
    }

    _soundEnabled = enabled;
    if (_backgroundServiceActive) {
      unawaited(_backgroundBridge.updateSound(enabled));
    }
    notifyListeners();
  }

  void skipPhase() {
    if (!isInProgress || _plan == null || _snapshot == null) {
      return;
    }

    final usingBackgroundService = _backgroundServiceActive;
    if (usingBackgroundService) {
      unawaited(_backgroundBridge.skipPhase());
    }

    if (status == WorkoutStatus.running) {
      synchronize();
    }
    if (!isInProgress) {
      return;
    }

    final wasRunning = status == WorkoutStatus.running;
    if (wasRunning) {
      _bankActiveLeg();
    }
    final skippedElapsed = _bankedElapsed + _snapshot!.displayRemaining;
    _bankedElapsed = skippedElapsed > _plan!.targetDuration
        ? _plan!.targetDuration
        : skippedElapsed;
    _snapshot = WorkoutTimeline.snapshotFor(
      plan: _plan!,
      elapsed: _bankedElapsed,
      status: wasRunning ? WorkoutStatus.running : WorkoutStatus.paused,
    );

    if (_snapshot!.status == WorkoutStatus.complete) {
      _ticker?.cancel();
      unawaited(_feedbackService.setKeepScreenOn(false));
      if (!usingBackgroundService) {
        unawaited(
          _feedbackService.playCompletionCue(
            soundEnabled: _soundEnabled,
            soundSettings: _soundSettings,
          ),
        );
      }
    } else {
      if (wasRunning) {
        _activeLeg
          ..reset()
          ..start();
        _startTicker();
      }
      if (!usingBackgroundService) {
        unawaited(
          _feedbackService.playPhaseCue(
            _snapshot!.phase,
            soundEnabled: _soundEnabled,
            soundSettings: _soundSettings,
          ),
        );
      }
    }
    notifyListeners();
  }

  void updateCurrentPhaseBpm(int bpm) {
    if (!isInProgress ||
        _plan == null ||
        _snapshot == null ||
        bpm < MetronomeConfig.minBpm ||
        bpm > MetronomeConfig.maxBpm) {
      return;
    }

    final phase = _snapshot!.phase;
    final current = phase == WorkoutPhase.walk
        ? _plan!.walkMetronome
        : _plan!.runMetronome;
    if (!current.enabled || current.bpm == bpm) {
      return;
    }

    _plan = _plan!.withMetronomeBpm(phase, bpm);
    if (_backgroundServiceActive) {
      unawaited(_backgroundBridge.updateMetronomeBpm(phase, bpm));
    }
    notifyListeners();
  }

  void start(
    WorkoutPlan plan, {
    SoundSettings soundSettings = const SoundSettings.defaults(),
  }) {
    if (status == WorkoutStatus.paused) {
      resume();
      return;
    }
    if (status == WorkoutStatus.running) {
      return;
    }

    _ticker?.cancel();
    _plan = plan;
    _soundSettings = soundSettings;
    _bankedElapsed = Duration.zero;
    _activeLeg
      ..stop()
      ..reset()
      ..start();
    _snapshot = WorkoutTimeline.snapshotFor(
      plan: plan,
      elapsed: Duration.zero,
      status: WorkoutStatus.running,
    );
    _backgroundServiceActive = true;
    _backgroundSessionId = 0;
    unawaited(_startBackgroundSession(plan));
    _startTicker();
    unawaited(_feedbackService.setKeepScreenOn(true));
    notifyListeners();
  }

  void pause() {
    if (status != WorkoutStatus.running || _plan == null) {
      return;
    }

    synchronize();
    if (status == WorkoutStatus.complete) {
      return;
    }

    _bankActiveLeg();
    _ticker?.cancel();
    _snapshot = WorkoutTimeline.snapshotFor(
      plan: _plan!,
      elapsed: _bankedElapsed,
      status: WorkoutStatus.paused,
    );
    if (_backgroundServiceActive) {
      unawaited(_backgroundBridge.pauseSession());
    }
    unawaited(_feedbackService.setKeepScreenOn(false));
    notifyListeners();
  }

  void resume() {
    if (status != WorkoutStatus.paused || _plan == null) {
      return;
    }

    _activeLeg
      ..reset()
      ..start();
    _snapshot = WorkoutTimeline.snapshotFor(
      plan: _plan!,
      elapsed: _bankedElapsed,
      status: WorkoutStatus.running,
    );
    if (_backgroundServiceActive) {
      unawaited(_backgroundBridge.resumeSession());
    }
    _startTicker();
    unawaited(_feedbackService.setKeepScreenOn(true));
    notifyListeners();
  }

  void stop() {
    final shouldStopBackground =
        _backgroundServiceActive || _backgroundSessionId != 0;
    _ticker?.cancel();
    _activeLeg
      ..stop()
      ..reset();
    _bankedElapsed = Duration.zero;

    if (_plan != null) {
      _snapshot = WorkoutTimeline.snapshotFor(
        plan: _plan!,
        elapsed: Duration.zero,
        status: WorkoutStatus.idle,
      );
    } else {
      _snapshot = null;
    }

    _backgroundServiceActive = false;
    _backgroundSessionId = 0;
    if (shouldStopBackground) {
      unawaited(_backgroundBridge.stopSession());
    }
    unawaited(_feedbackService.setKeepScreenOn(false));
    notifyListeners();
  }

  void synchronize() {
    if (status != WorkoutStatus.running || _plan == null) {
      return;
    }

    final previous = _snapshot!;
    final elapsed = _bankedElapsed + _activeLeg.elapsed;
    final next = WorkoutTimeline.snapshotFor(
      plan: _plan!,
      elapsed: elapsed,
      status: WorkoutStatus.running,
    );
    _snapshot = next;

    if (next.status == WorkoutStatus.complete) {
      _ticker?.cancel();
      _activeLeg
        ..stop()
        ..reset();
      _bankedElapsed = _plan!.targetDuration;
      unawaited(_feedbackService.setKeepScreenOn(false));
      if (!_backgroundServiceActive) {
        unawaited(
          _feedbackService.playCompletionCue(
            soundEnabled: _soundEnabled,
            soundSettings: _soundSettings,
          ),
        );
      }
    } else if (next.segmentOrdinal != previous.segmentOrdinal &&
        !_backgroundServiceActive) {
      unawaited(
        _feedbackService.playPhaseCue(
          next.phase,
          soundEnabled: _soundEnabled,
          soundSettings: _soundSettings,
        ),
      );
    }

    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => synchronize(),
    );
  }

  void _bankActiveLeg() {
    _activeLeg.stop();
    _bankedElapsed += _activeLeg.elapsed;
    _activeLeg.reset();
  }

  Future<void> _startBackgroundSession(WorkoutPlan plan) async {
    final started = await _backgroundBridge.startSession(
      plan: plan,
      soundEnabled: _soundEnabled,
      soundSettings: _soundSettings,
    );
    if (!started) {
      _backgroundServiceActive = false;
    }
  }

  Future<WorkoutPlan?> refreshFromBackgroundService() async {
    final state = await _backgroundBridge.getState();
    if (state == null) {
      synchronize();
      return null;
    }

    _applyBackgroundState(state);
    return state.plan;
  }

  Future<void> openNotificationSettings() {
    return _backgroundBridge.openNotificationSettings();
  }

  void _applyBackgroundState(BackgroundWorkoutState state) {
    if (_backgroundSessionId != 0 &&
        state.sessionId != 0 &&
        state.sessionId < _backgroundSessionId) {
      return;
    }

    _backgroundSessionId = state.sessionId;
    _plan = state.plan;
    _soundEnabled = state.soundEnabled;
    _notificationsEnabled = state.notificationsEnabled;
    _ticker?.cancel();
    _activeLeg
      ..stop()
      ..reset();
    _bankedElapsed = state.elapsed > state.plan.targetDuration
        ? state.plan.targetDuration
        : state.elapsed;

    switch (state.status) {
      case BackgroundWorkoutStatus.running:
        _backgroundServiceActive = true;
        _activeLeg.start();
        _snapshot = WorkoutTimeline.snapshotFor(
          plan: state.plan,
          elapsed: _bankedElapsed,
          status: WorkoutStatus.running,
        );
        _startTicker();
        unawaited(_feedbackService.setKeepScreenOn(true));
      case BackgroundWorkoutStatus.paused:
        _backgroundServiceActive = true;
        _snapshot = WorkoutTimeline.snapshotFor(
          plan: state.plan,
          elapsed: _bankedElapsed,
          status: WorkoutStatus.paused,
        );
        unawaited(_feedbackService.setKeepScreenOn(false));
      case BackgroundWorkoutStatus.complete:
        _backgroundServiceActive = false;
        _bankedElapsed = state.plan.targetDuration;
        _snapshot = WorkoutTimeline.snapshotFor(
          plan: state.plan,
          elapsed: state.plan.targetDuration,
          status: WorkoutStatus.complete,
        );
        unawaited(_feedbackService.setKeepScreenOn(false));
      case BackgroundWorkoutStatus.idle:
        _backgroundServiceActive = false;
        _backgroundSessionId = 0;
        _bankedElapsed = Duration.zero;
        _snapshot = WorkoutTimeline.snapshotFor(
          plan: state.plan,
          elapsed: Duration.zero,
          status: WorkoutStatus.idle,
        );
        unawaited(_feedbackService.setKeepScreenOn(false));
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _activeLeg.stop();
    _backgroundBridge.dispose();
    unawaited(_feedbackService.setKeepScreenOn(false));
    super.dispose();
  }
}
