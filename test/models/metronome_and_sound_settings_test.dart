import 'package:flutter_test/flutter_test.dart';
import 'package:run_walk_timer/models/metronome_config.dart';
import 'package:run_walk_timer/models/sound_settings.dart';
import 'package:run_walk_timer/models/workout_plan.dart';

void main() {
  group('metronome configuration', () {
    test('provides disabled walking and running defaults', () {
      final plan = WorkoutPlan.intervals(
        walkDuration: const Duration(minutes: 1),
        runDuration: const Duration(minutes: 2),
        intervalCount: 2,
      );

      expect(plan.walkMetronome.enabled, isFalse);
      expect(plan.walkMetronome.bpm, 100);
      expect(plan.runMetronome.enabled, isFalse);
      expect(plan.runMetronome.bpm, 160);
    });

    test('accepts inclusive BPM boundaries', () {
      final plan = WorkoutPlan.timed(
        walkDuration: const Duration(minutes: 1),
        runDuration: const Duration(minutes: 1),
        timeLimit: const Duration(minutes: 10),
        walkMetronome: const MetronomeConfig(enabled: true, bpm: 70),
        runMetronome: const MetronomeConfig(enabled: true, bpm: 180),
      );

      expect(plan.walkMetronome.bpm, 70);
      expect(plan.runMetronome.bpm, 180);
    });

    test('rejects BPM values outside the supported range', () {
      for (final bpm in <int>[69, 181]) {
        expect(
          () => WorkoutPlan.intervals(
            walkDuration: const Duration(minutes: 1),
            runDuration: const Duration(minutes: 1),
            intervalCount: 1,
            walkMetronome: MetronomeConfig(enabled: true, bpm: bpm),
          ),
          throwsArgumentError,
        );
      }
    });
  });

  group('sound settings', () {
    test('decodes independent selections', () {
      final settings = SoundSettings.fromMap(<String, String>{
        'walkCue': 'wood_tone',
        'runCue': 'bright_bell',
        'completionCue': 'success_chime',
        'metronome': 'digital_tick',
      });

      expect(settings.walkCue, WalkCueSound.woodTone);
      expect(settings.runCue, RunCueSound.brightBell);
      expect(settings.completionCue, CompletionCueSound.successChime);
      expect(settings.metronome, MetronomeSound.digitalTick);
      expect(settings.toMap()['metronome'], 'digital_tick');
    });

    test('falls back safely for missing and unknown native values', () {
      final settings = SoundSettings.fromMap(<String, String>{
        'walkCue': 'unknown',
      });

      expect(settings.walkCue, WalkCueSound.classicLow);
      expect(settings.runCue, RunCueSound.classicDouble);
      expect(settings.completionCue, CompletionCueSound.classicTriple);
      expect(settings.metronome, MetronomeSound.sharpClick);
    });
  });
}
