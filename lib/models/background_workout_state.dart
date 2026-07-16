import 'workout_plan.dart';

enum BackgroundWorkoutStatus { idle, running, paused, complete }

class BackgroundWorkoutState {
  const BackgroundWorkoutState({
    required this.status,
    required this.plan,
    required this.elapsed,
    required this.soundEnabled,
    required this.sessionId,
    this.notificationsEnabled = true,
  });

  factory BackgroundWorkoutState.fromMap(Map<String, Object?> map) {
    final modeName = map['limitMode'] as String? ?? 'intervals';
    final walkDuration = Duration(
      milliseconds: (map['walkMs'] as num?)?.toInt() ?? 0,
    );
    final runDuration = Duration(
      milliseconds: (map['runMs'] as num?)?.toInt() ?? 0,
    );
    final targetDuration = Duration(
      milliseconds: (map['targetMs'] as num?)?.toInt() ?? 0,
    );
    final intervalCount = (map['intervalCount'] as num?)?.toInt() ?? 1;

    final plan = modeName == WorkoutLimitMode.time.name
        ? WorkoutPlan.timed(
            walkDuration: walkDuration,
            runDuration: runDuration,
            timeLimit: targetDuration,
          )
        : WorkoutPlan.intervals(
            walkDuration: walkDuration,
            runDuration: runDuration,
            intervalCount: intervalCount,
          );

    final statusName = map['status'] as String? ?? 'idle';
    final status = BackgroundWorkoutStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => BackgroundWorkoutStatus.idle,
    );

    return BackgroundWorkoutState(
      status: status,
      plan: plan,
      elapsed: Duration(milliseconds: (map['elapsedMs'] as num?)?.toInt() ?? 0),
      soundEnabled: map['soundEnabled'] as bool? ?? true,
      sessionId: (map['sessionId'] as num?)?.toInt() ?? 0,
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
    );
  }

  final BackgroundWorkoutStatus status;
  final WorkoutPlan plan;
  final Duration elapsed;
  final bool soundEnabled;
  final int sessionId;
  final bool notificationsEnabled;

  bool get isActive =>
      status == BackgroundWorkoutStatus.running ||
      status == BackgroundWorkoutStatus.paused;
}
