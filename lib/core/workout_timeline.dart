import '../models/workout_plan.dart';
import '../models/workout_snapshot.dart';

abstract final class WorkoutTimeline {
  static WorkoutSnapshot snapshotFor({
    required WorkoutPlan plan,
    required Duration elapsed,
    required WorkoutStatus status,
  }) {
    final targetMicroseconds = plan.targetDuration.inMicroseconds;
    final elapsedMicroseconds = elapsed.inMicroseconds.clamp(
      0,
      targetMicroseconds,
    );
    final isComplete = elapsedMicroseconds >= targetMicroseconds;

    final positionMicroseconds = isComplete && targetMicroseconds > 0
        ? targetMicroseconds - 1
        : elapsedMicroseconds;
    final cycleMicroseconds = plan.cycleDuration.inMicroseconds;
    final walkMicroseconds = plan.walkDuration.inMicroseconds;
    final cycleIndex = positionMicroseconds ~/ cycleMicroseconds;
    final positionInCycle = positionMicroseconds % cycleMicroseconds;
    final isWalking = positionInCycle < walkMicroseconds;
    final phase = isWalking ? WorkoutPhase.walk : WorkoutPhase.run;
    final phaseDuration = isWalking ? plan.walkDuration : plan.runDuration;
    final phaseRemainingMicroseconds = isWalking
        ? walkMicroseconds - positionInCycle
        : cycleMicroseconds - positionInCycle;
    final totalRemainingMicroseconds = targetMicroseconds - elapsedMicroseconds;
    final displayRemainingMicroseconds = isComplete
        ? 0
        : phaseRemainingMicroseconds < totalRemainingMicroseconds
        ? phaseRemainingMicroseconds
        : totalRemainingMicroseconds;

    final completedCycles =
        isComplete && plan.limitMode == WorkoutLimitMode.intervals
        ? plan.intervalCount!
        : elapsedMicroseconds ~/ cycleMicroseconds;

    return WorkoutSnapshot(
      status: isComplete ? WorkoutStatus.complete : status,
      phase: phase,
      phaseRemaining: isComplete
          ? Duration.zero
          : Duration(microseconds: phaseRemainingMicroseconds),
      displayRemaining: Duration(microseconds: displayRemainingMicroseconds),
      totalRemaining: Duration(microseconds: totalRemainingMicroseconds),
      activeElapsed: Duration(microseconds: elapsedMicroseconds),
      cycleIndex: cycleIndex,
      completedCycles: completedCycles,
      segmentOrdinal: cycleIndex * 2 + (isWalking ? 0 : 1),
      phaseProgress: isComplete
          ? 1
          : 1 - (phaseRemainingMicroseconds / phaseDuration.inMicroseconds),
      overallProgress: targetMicroseconds == 0
          ? 0
          : elapsedMicroseconds / targetMicroseconds,
    );
  }
}
