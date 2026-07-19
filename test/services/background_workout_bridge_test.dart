import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_walk_timer/models/metronome_config.dart';
import 'package:run_walk_timer/models/sound_settings.dart';
import 'package:run_walk_timer/models/workout_plan.dart';
import 'package:run_walk_timer/services/background_workout_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('run_walk_timer/device');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('start payload includes metronomes and every sound selection', () async {
    MethodCall? captured;
    messenger.setMockMethodCallHandler(channel, (call) async {
      captured = call;
      return true;
    });
    final bridge = BackgroundWorkoutBridge();
    final plan = WorkoutPlan.intervals(
      walkDuration: const Duration(minutes: 1),
      runDuration: const Duration(minutes: 2),
      intervalCount: 3,
      walkMetronome: const MetronomeConfig(enabled: true, bpm: 100),
      runMetronome: const MetronomeConfig(enabled: true, bpm: 170),
    );
    const settings = SoundSettings(
      walkCue: WalkCueSound.woodTone,
      runCue: RunCueSound.brightBell,
      completionCue: CompletionCueSound.successChime,
      metronome: MetronomeSound.digitalTick,
    );

    expect(
      await bridge.startSession(
        plan: plan,
        soundEnabled: false,
        soundSettings: settings,
      ),
      isTrue,
    );

    expect(captured?.method, 'startWorkoutService');
    final arguments = Map<Object?, Object?>.from(captured!.arguments as Map);
    expect(arguments['walkMetronomeEnabled'], isTrue);
    expect(arguments['walkBpm'], 100);
    expect(arguments['runMetronomeEnabled'], isTrue);
    expect(arguments['runBpm'], 170);
    expect(arguments['soundEnabled'], isFalse);
    expect(arguments['walkCue'], 'wood_tone');
    expect(arguments['runCue'], 'bright_bell');
    expect(arguments['completionCue'], 'success_chime');
    expect(arguments['metronome'], 'digital_tick');
    bridge.dispose();
  });
}
