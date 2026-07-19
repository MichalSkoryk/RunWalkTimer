import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_walk_timer/models/sound_settings.dart';
import 'package:run_walk_timer/services/sound_settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('run_walk_timer/device');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('loads, saves, and previews exact native sound identifiers', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'getSoundSettings') {
        return <String, String>{
          'walkCue': 'soft_bell',
          'runCue': 'digital_double',
          'completionCue': 'bell_finish',
          'metronome': 'wood_tick',
        };
      }
      return null;
    });

    const service = SoundSettingsService();
    final settings = await service.load();
    expect(settings.walkCue, WalkCueSound.softBell);
    expect(settings.metronome, MetronomeSound.woodTick);

    final next = settings.copyWith(metronome: MetronomeSound.digitalTick);
    expect(await service.save(next), isTrue);
    expect(
      await service.preview(
        category: SoundCategory.metronome,
        soundId: 'digital_tick',
      ),
      isTrue,
    );

    expect(calls.map((call) => call.method), <String>[
      'getSoundSettings',
      'setSoundSettings',
      'previewSound',
    ]);
    expect(
      Map<Object?, Object?>.from(calls[1].arguments as Map)['metronome'],
      'digital_tick',
    );
    expect(
      Map<Object?, Object?>.from(calls[2].arguments as Map),
      <String, String>{'category': 'metronome', 'soundId': 'digital_tick'},
    );
  });
}
