import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_walk_timer/models/sound_settings.dart';
import 'package:run_walk_timer/screens/sound_settings_screen.dart';
import 'package:run_walk_timer/services/sound_settings_service.dart';

void main() {
  testWidgets('saves independent choices and previews the exact sound', (
    tester,
  ) async {
    final service = _FakeSoundSettingsService();
    SoundSettings? latest;
    await tester.pumpWidget(
      MaterialApp(
        home: SoundSettingsScreen(
          initialSettings: const SoundSettings.defaults(),
          readOnly: false,
          service: service,
          onSettingsChanged: (settings) => latest = settings,
        ),
      ),
    );

    final walkSelector = find.descendant(
      of: find.byKey(const ValueKey('walk-sound-setting')),
      matching: find.byType(DropdownButtonFormField<WalkCueSound>),
    );
    tester
        .widget<DropdownButtonFormField<WalkCueSound>>(walkSelector)
        .onChanged!(WalkCueSound.woodTone);
    await tester.pump();

    expect(service.saved.single.walkCue, WalkCueSound.woodTone);
    expect(latest?.walkCue, WalkCueSound.woodTone);

    final preview = find.byKey(const ValueKey('walk-sound-setting-preview'));
    await tester.tap(preview);
    await tester.pump();

    expect(service.previews, [(SoundCategory.walk, 'wood_tone')]);
  });

  testWidgets('active workout makes settings and previews read only', (
    tester,
  ) async {
    final service = _FakeSoundSettingsService();
    await tester.pumpWidget(
      MaterialApp(
        home: SoundSettingsScreen(
          initialSettings: const SoundSettings.defaults(),
          readOnly: true,
          service: service,
          onSettingsChanged: (_) {},
        ),
      ),
    );

    expect(
      find.text('Stop the workout to change or preview sounds.'),
      findsOneWidget,
    );
    final selector = tester.widget<DropdownButtonFormField<WalkCueSound>>(
      find.descendant(
        of: find.byKey(const ValueKey('walk-sound-setting')),
        matching: find.byType(DropdownButtonFormField<WalkCueSound>),
      ),
    );
    expect(selector.onChanged, isNull);
    final preview = tester.widget<IconButton>(
      find.byKey(const ValueKey('walk-sound-setting-preview')),
    );
    expect(preview.onPressed, isNull);
    expect(find.byKey(const ValueKey('privacy-policy-link')), findsOneWidget);
  });

  testWidgets('narrow enlarged-text layout does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 720),
          textScaler: TextScaler.linear(1.8),
        ),
        child: MaterialApp(
          home: SoundSettingsScreen(
            initialSettings: const SoundSettings.defaults(),
            readOnly: false,
            service: _FakeSoundSettingsService(),
            onSettingsChanged: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

class _FakeSoundSettingsService extends SoundSettingsService {
  final List<SoundSettings> saved = [];
  final List<(SoundCategory, String)> previews = [];

  @override
  Future<bool> save(SoundSettings settings) async {
    saved.add(settings);
    return true;
  }

  @override
  Future<bool> preview({
    required SoundCategory category,
    required String soundId,
  }) async {
    previews.add((category, soundId));
    return true;
  }
}
