import 'workout_plan.dart';

class WorkoutSnapshot {
  const WorkoutSnapshot({
    required this.status,
    required this.phase,
    required this.phaseRemaining,
    required this.displayRemaining,
    required this.totalRemaining,
    required this.activeElapsed,
    required this.cycleIndex,
    required this.completedCycles,
    required this.segmentOrdinal,
    required this.phaseProgress,
    required this.overallProgress,
  });

  final WorkoutStatus status;
  final WorkoutPhase phase;
  final Duration phaseRemaining;
  final Duration displayRemaining;
  final Duration totalRemaining;
  final Duration activeElapsed;
  final int cycleIndex;
  final int completedCycles;
  final int segmentOrdinal;
  final double phaseProgress;
  final double overallProgress;
}
