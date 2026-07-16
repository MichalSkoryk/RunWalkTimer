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
  });

  factory WorkoutPlan.timed({
    required Duration walkDuration,
    required Duration runDuration,
    required Duration timeLimit,
  }) {
    _validatePhaseDurations(walkDuration, runDuration);
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
    );
  }

  factory WorkoutPlan.intervals({
    required Duration walkDuration,
    required Duration runDuration,
    required int intervalCount,
  }) {
    _validatePhaseDurations(walkDuration, runDuration);
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
    );
  }

  final Duration walkDuration;
  final Duration runDuration;
  final WorkoutLimitMode limitMode;
  final Duration? timeLimit;
  final int? intervalCount;

  Duration get cycleDuration => walkDuration + runDuration;

  Duration get targetDuration {
    if (limitMode == WorkoutLimitMode.time) {
      return timeLimit!;
    }

    return Duration(
      microseconds: cycleDuration.inMicroseconds * intervalCount!,
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
}
