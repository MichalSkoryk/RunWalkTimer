import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_walk_timer/core/workout_timeline.dart';
import 'package:run_walk_timer/models/metronome_config.dart';
import 'package:run_walk_timer/models/workout_plan.dart';
import 'package:run_walk_timer/widgets/current_phase_card.dart';

void main() {
  testWidgets('live controls fit a narrow enlarged-text workout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final plan = WorkoutPlan.intervals(
      walkDuration: const Duration(minutes: 1),
      runDuration: const Duration(minutes: 2),
      intervalCount: 2,
      walkMetronome: const MetronomeConfig(enabled: true, bpm: 100),
    );
    final snapshot = WorkoutTimeline.snapshotFor(
      plan: plan,
      elapsed: Duration.zero,
      status: WorkoutStatus.running,
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 900),
          textScaler: TextScaler.linear(1.8),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CurrentPhaseCard(
                snapshot: snapshot,
                plan: plan,
                onSkipPhase: () {},
                onBpmChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('live-bpm-control')), findsOneWidget);
    expect(find.byKey(const ValueKey('skip-phase-button')), findsOneWidget);
  });
}
