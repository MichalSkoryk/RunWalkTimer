import 'package:flutter_test/flutter_test.dart';
import 'package:run_walk_timer/core/workout_timeline.dart';
import 'package:run_walk_timer/models/workout_plan.dart';
import 'package:run_walk_timer/models/workout_snapshot.dart';

void main() {
  group('interval goal', () {
    final plan = WorkoutPlan.intervals(
      walkDuration: const Duration(seconds: 10),
      runDuration: const Duration(seconds: 20),
      intervalCount: 2,
    );

    test('starts at a full walk interval', () {
      final state = _at(plan, Duration.zero);

      expect(state.phase, WorkoutPhase.walk);
      expect(state.displayRemaining, const Duration(seconds: 10));
      expect(state.cycleIndex, 0);
      expect(state.segmentOrdinal, 0);
      expect(state.status, WorkoutStatus.running);
    });

    test('moves to run at the exact walk boundary', () {
      final state = _at(plan, const Duration(seconds: 10));

      expect(state.phase, WorkoutPhase.run);
      expect(state.displayRemaining, const Duration(seconds: 20));
      expect(state.segmentOrdinal, 1);
    });

    test('starts the next walk after a full cycle', () {
      final state = _at(plan, const Duration(seconds: 30));

      expect(state.phase, WorkoutPhase.walk);
      expect(state.cycleIndex, 1);
      expect(state.completedCycles, 1);
      expect(state.segmentOrdinal, 2);
    });

    test('completes after the requested number of full cycles', () {
      final state = _at(plan, const Duration(seconds: 60));

      expect(state.status, WorkoutStatus.complete);
      expect(state.displayRemaining, Duration.zero);
      expect(state.totalRemaining, Duration.zero);
      expect(state.completedCycles, 2);
      expect(state.overallProgress, 1);
    });
  });

  group('time goal', () {
    test('limits the visible countdown when goal ends during walking', () {
      final plan = WorkoutPlan.timed(
        walkDuration: const Duration(seconds: 10),
        runDuration: const Duration(seconds: 20),
        timeLimit: const Duration(seconds: 5),
      );

      expect(
        _at(plan, Duration.zero).displayRemaining,
        const Duration(seconds: 5),
      );
      expect(
        _at(plan, const Duration(seconds: 5)).status,
        WorkoutStatus.complete,
      );
    });

    test('completion wins at an exact phase boundary', () {
      final plan = WorkoutPlan.timed(
        walkDuration: const Duration(seconds: 10),
        runDuration: const Duration(seconds: 20),
        timeLimit: const Duration(seconds: 10),
      );
      final state = _at(plan, const Duration(seconds: 10));

      expect(state.status, WorkoutStatus.complete);
      expect(state.phase, WorkoutPhase.walk);
      expect(state.segmentOrdinal, 0);
    });

    test('limits a run countdown to the remaining workout time', () {
      final plan = WorkoutPlan.timed(
        walkDuration: const Duration(seconds: 10),
        runDuration: const Duration(seconds: 20),
        timeLimit: const Duration(seconds: 15),
      );
      final state = _at(plan, const Duration(seconds: 12));

      expect(state.phase, WorkoutPhase.run);
      expect(state.phaseRemaining, const Duration(seconds: 18));
      expect(state.totalRemaining, const Duration(seconds: 3));
      expect(state.displayRemaining, const Duration(seconds: 3));
    });
  });

  test('plans reject zero durations and zero cycles', () {
    expect(
      () => WorkoutPlan.intervals(
        walkDuration: Duration.zero,
        runDuration: const Duration(seconds: 1),
        intervalCount: 1,
      ),
      throwsArgumentError,
    );
    expect(
      () => WorkoutPlan.intervals(
        walkDuration: const Duration(seconds: 1),
        runDuration: const Duration(seconds: 1),
        intervalCount: 0,
      ),
      throwsArgumentError,
    );
  });
}

WorkoutSnapshot _at(WorkoutPlan plan, Duration elapsed) {
  return WorkoutTimeline.snapshotFor(
    plan: plan,
    elapsed: elapsed,
    status: WorkoutStatus.running,
  );
}
