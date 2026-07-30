import 'metronome_config.dart';

enum WorkoutLimitMode { time, intervals }

enum WorkoutPhase { walk, run }

enum WorkoutStatus { idle, running, paused, complete }

extension WorkoutPhaseLabel on WorkoutPhase {
  String get label => this == WorkoutPhase.walk ? 'Walking' : 'Running';

  String get actionLabel => this == WorkoutPhase.walk ? 'Walk' : 'Run';
}

class WorkoutPlan {
  WorkoutPlan._({
    required this.walkDuration,
    required this.runDuration,
    required this.limitMode,
    required this.timeLimit,
    required this.intervalCount,
    required this.walkMetronome,
    required this.runMetronome,
  });

  factory WorkoutPlan.timed({
    required Duration walkDuration,
    required Duration runDuration,
    required Duration timeLimit,
    MetronomeConfig walkMetronome = MetronomeConfig.walkDefault,
    MetronomeConfig runMetronome = MetronomeConfig.runDefault,
  }) {
    _validatePhaseDurations(walkDuration, runDuration);
    _validateMetronomes(walkMetronome, runMetronome);
    if (timeLimit <= Duration.zero) {
      throw ArgumentError.value(
        timeLimit,
        'timeLimit',
        'must be greater than zero',
      );
    }

    return WorkoutPlan._(
      walkDuration: walkDuration,
      runDuration: runDuration,
      limitMode: WorkoutLimitMode.time,
      timeLimit: timeLimit,
      intervalCount: null,
      walkMetronome: walkMetronome,
      runMetronome: runMetronome,
    );
  }

  factory WorkoutPlan.intervals({
    required Duration walkDuration,
    required Duration runDuration,
    required int intervalCount,
    MetronomeConfig walkMetronome = MetronomeConfig.walkDefault,
    MetronomeConfig runMetronome = MetronomeConfig.runDefault,
  }) {
    _validatePhaseDurations(walkDuration, runDuration);
    _validateMetronomes(walkMetronome, runMetronome);
    if (intervalCount < 1) {
      throw ArgumentError.value(
        intervalCount,
        'intervalCount',
        'must be at least one',
      );
    }

    return WorkoutPlan._(
      walkDuration: walkDuration,
      runDuration: runDuration,
      limitMode: WorkoutLimitMode.intervals,
      timeLimit: null,
      intervalCount: intervalCount,
      walkMetronome: walkMetronome,
      runMetronome: runMetronome,
    );
  }

  final Duration walkDuration;
  final Duration runDuration;
  final WorkoutLimitMode limitMode;
  final Duration? timeLimit;
  final int? intervalCount;
  final MetronomeConfig walkMetronome;
  final MetronomeConfig runMetronome;

  Duration get cycleDuration => walkDuration + runDuration;

  Duration get targetDuration {
    if (limitMode == WorkoutLimitMode.time) {
      return timeLimit!;
    }

    return Duration(
      microseconds: cycleDuration.inMicroseconds * intervalCount!,
    );
  }

  WorkoutPlan withMetronomeBpm(WorkoutPhase phase, int bpm) {
    final updated = MetronomeConfig(
      enabled: phase == WorkoutPhase.walk
          ? walkMetronome.enabled
          : runMetronome.enabled,
      bpm: bpm,
    );

    return limitMode == WorkoutLimitMode.time
        ? WorkoutPlan.timed(
            walkDuration: walkDuration,
            runDuration: runDuration,
            timeLimit: timeLimit!,
            walkMetronome: phase == WorkoutPhase.walk ? updated : walkMetronome,
            runMetronome: phase == WorkoutPhase.run ? updated : runMetronome,
          )
        : WorkoutPlan.intervals(
            walkDuration: walkDuration,
            runDuration: runDuration,
            intervalCount: intervalCount!,
            walkMetronome: phase == WorkoutPhase.walk ? updated : walkMetronome,
            runMetronome: phase == WorkoutPhase.run ? updated : runMetronome,
          );
  }

  static void _validatePhaseDurations(
    Duration walkDuration,
    Duration runDuration,
  ) {
    if (walkDuration <= Duration.zero) {
      throw ArgumentError.value(
        walkDuration,
        'walkDuration',
        'must be greater than zero',
      );
    }
    if (runDuration <= Duration.zero) {
      throw ArgumentError.value(
        runDuration,
        'runDuration',
        'must be greater than zero',
      );
    }
  }

  static void _validateMetronomes(
    MetronomeConfig walkMetronome,
    MetronomeConfig runMetronome,
  ) {
    for (final entry in <String, MetronomeConfig>{
      'walkMetronome': walkMetronome,
      'runMetronome': runMetronome,
    }.entries) {
      if (!entry.value.hasValidBpm) {
        throw ArgumentError.value(
          entry.value.bpm,
          entry.key,
          'BPM must be between ${MetronomeConfig.minBpm} and '
          '${MetronomeConfig.maxBpm}',
        );
      }
    }
  }
}
