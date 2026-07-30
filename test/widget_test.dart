import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_walk_timer/app.dart';

void main() {
  testWidgets('shows interval goal by default and switches to a time goal', (
    tester,
  ) async {
    _useTallTestWindow(tester);
    await tester.pumpWidget(const BasePacerApp());

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      'Base Pacer: Run/Walk Timer',
    );
    expect(find.text('Base Pacer'), findsOneWidget);
    final supportButton = find.byKey(
      const ValueKey('developer-support-button'),
    );
    expect(supportButton, findsOneWidget);
    expect(
      find.ancestor(of: supportButton, matching: find.byType(AppBar)),
      findsOneWidget,
    );
    final settingsButton = find.byKey(const ValueKey('sound-settings-button'));
    expect(
      tester.getCenter(supportButton).dx,
      lessThan(tester.getCenter(settingsButton).dx),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('workout-setup-card'))).height,
      lessThan(650),
    );
    expect(find.text('Walk'), findsOneWidget);
    expect(find.text('Run'), findsOneWidget);
    expect(find.byKey(const ValueKey('walk-duration')), findsOneWidget);
    expect(find.byKey(const ValueKey('run-duration')), findsOneWidget);
    expect(find.byKey(const ValueKey('walk-minutes')), findsNothing);
    expect(find.byKey(const ValueKey('walk-seconds')), findsNothing);
    expect(
      find.byKey(const ValueKey('walk-metronome-checkbox')),
      findsOneWidget,
    );
    expect(find.text('BPM'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('walk-metronome-bpm')), findsNothing);
    expect(find.byKey(const ValueKey('interval-count-input')), findsOneWidget);
    expect(find.byKey(const ValueKey('total')), findsNothing);

    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('total')), findsOneWidget);
    expect(find.byKey(const ValueKey('total-duration')), findsOneWidget);
    expect(find.byKey(const ValueKey('interval-count-input')), findsNothing);
  });

  testWidgets('setup sound shortcut opens editable sound settings', (
    tester,
  ) async {
    _useTallTestWindow(tester);
    await tester.pumpWidget(const BasePacerApp());

    await tester.tap(find.byKey(const ValueKey('setup-sound-settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('Sound settings'), findsOneWidget);
    expect(
      find.text('Stop the workout to change or preview sounds.'),
      findsNothing,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('walk-sound-setting-preview')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('metronome reveals default BPM and validates 70 to 180', (
    tester,
  ) async {
    _useTallTestWindow(tester);
    await tester.pumpWidget(const BasePacerApp());

    final checkbox = find.byKey(const ValueKey('walk-metronome-checkbox'));
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    final bpm = find.byKey(const ValueKey('walk-metronome-bpm'));
    expect(bpm, findsOneWidget);
    expect(tester.widget<TextField>(bpm).controller?.text, '100');
    final decrease = find.byKey(const ValueKey('walk-bpm-decrease'));
    final increase = find.byKey(const ValueKey('walk-bpm-increase'));
    expect(decrease, findsOneWidget);
    expect(increase, findsOneWidget);

    await tester.tap(increase);
    await tester.pump();
    expect(tester.widget<TextField>(bpm).controller?.text, '101');

    await tester.tap(decrease);
    await tester.pump();
    expect(tester.widget<TextField>(bpm).controller?.text, '100');

    await tester.enterText(bpm, '70');
    await tester.pump();
    expect(tester.widget<IconButton>(decrease).onPressed, isNull);
    expect(tester.widget<IconButton>(increase).onPressed, isNotNull);

    await tester.enterText(bpm, '180');
    await tester.pump();
    expect(tester.widget<IconButton>(decrease).onPressed, isNotNull);
    expect(tester.widget<IconButton>(increase).onPressed, isNull);

    await tester.enterText(bpm, '69');
    await tester.pump();
    expect(find.text('Enter a BPM from 70 to 180.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('start-button')))
          .onPressed,
      isNull,
    );

    await tester.enterText(bpm, '70');
    await tester.pump();
    expect(find.text('Enter a BPM from 70 to 180.'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('start-button')))
          .onPressed,
      isNotNull,
    );

    await tester.enterText(bpm, '181');
    await tester.pump();
    expect(find.text('Enter a BPM from 70 to 180.'), findsOneWidget);
  });

  testWidgets('live BPM changes by one and skip advances the phase', (
    tester,
  ) async {
    _useTallTestWindow(tester);
    await tester.pumpWidget(const BasePacerApp());

    await tester.tap(find.byKey(const ValueKey('walk-metronome-checkbox')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('start-button')));
    await tester.pump();

    expect(find.byKey(const ValueKey('live-bpm-control')), findsOneWidget);
    expect(find.byKey(const ValueKey('live-bpm-value')), findsOneWidget);
    expect(find.text('BPM'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('live-bpm-increase')));
    await tester.pump();
    expect(find.text('101'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('skip-phase-button')));
    await tester.pump();
    expect(find.text('RUNNING'), findsOneWidget);
    expect(find.byKey(const ValueKey('live-bpm-control')), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('overall-countdown'))).data,
      '00:14:00',
    );

    await tester.tap(find.byKey(const ValueKey('pause-button')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('skip-phase-button')));
    await tester.pump();
    expect(find.text('WALKING'), findsOneWidget);
    expect(find.text('PAUSED'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('live-bpm-value'))).data,
      '101',
    );
  });

  testWidgets('sound settings stay accessible but lock during a workout', (
    tester,
  ) async {
    _useTallTestWindow(tester);
    await tester.pumpWidget(const BasePacerApp());

    await tester.tap(find.byKey(const ValueKey('start-button')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('sound-settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('Sound settings'), findsOneWidget);
    expect(
      find.text('Stop the workout to change or preview sounds.'),
      findsOneWidget,
    );
  });

  testWidgets('main setup handles a narrow enlarged-text layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          size: Size(320, 720),
          textScaler: TextScaler.linear(1.8),
        ),
        child: BasePacerApp(),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('sound-settings-button')), findsOneWidget);
  });

  testWidgets('normalizes combined duration after editing completes', (
    tester,
  ) async {
    _useTallTestWindow(tester);
    await tester.pumpWidget(const BasePacerApp());

    final walkInput = find.byKey(const ValueKey('walk-duration'));
    await tester.tap(walkInput);
    await tester.enterText(walkInput, '1:5');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(tester.widget<TextField>(walkInput).controller?.text, '01:05');
  });

  testWidgets('invalid combined seconds disable Start with guidance', (
    tester,
  ) async {
    _useTallTestWindow(tester);
    await tester.pumpWidget(const BasePacerApp());

    await tester.enterText(find.byKey(const ValueKey('run-duration')), '02:60');
    await tester.pump();

    expect(
      find.text('Enter time as MM:SS. Seconds must be 00–59.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('start-button')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('total workout time uses one HH:MM:SS input', (tester) async {
    _useTallTestWindow(tester);
    await tester.pumpWidget(const BasePacerApp());

    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();

    final totalInput = find.byKey(const ValueKey('total-duration'));
    expect(totalInput, findsOneWidget);
    expect(tester.widget<TextField>(totalInput).controller?.text, '00:20:00');

    await tester.enterText(totalInput, '00:60:00');
    await tester.pump();
    expect(
      find.text('Enter time as HH:MM:SS. Minutes and seconds must be 00–59.'),
      findsOneWidget,
    );
  });

  testWidgets('running hides setup and pause or stop restores it', (
    tester,
  ) async {
    _useTallTestWindow(tester);
    await tester.pumpWidget(const BasePacerApp());

    await tester.tap(find.byKey(const ValueKey('start-button')));
    await tester.pump();

    expect(find.text('CURRENT MODE'), findsOneWidget);
    expect(find.text('WALKING'), findsOneWidget);
    expect(find.text('CURRENT INTERVAL LEFT'), findsOneWidget);
    expect(find.byKey(const ValueKey('main-countdown')), findsOneWidget);
    expect(find.text('OVERALL TIME LEFT'), findsOneWidget);
    expect(find.byKey(const ValueKey('overall-countdown')), findsOneWidget);
    expect(find.text('Workout setup'), findsNothing);
    expect(find.byKey(const ValueKey('walk-duration')), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('pause-button')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const ValueKey('pause-button')));
    await tester.pump();

    expect(find.text('Workout setup'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('walk-duration')))
          .enabled,
      isFalse,
    );
    expect(find.text('Resume'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stop-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop and reset'));
    await tester.pumpAndSettle();

    expect(find.text('Workout setup'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('walk-duration')))
          .enabled,
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('invalid zero duration disables Start and explains why', (
    tester,
  ) async {
    _useTallTestWindow(tester);
    await tester.pumpWidget(const BasePacerApp());

    await tester.enterText(
      find.byKey(const ValueKey('walk-duration')),
      '00:00',
    );
    await tester.pump();

    expect(find.text('Enter a duration of at least 1 second.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('start-button')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('sound cues default to on and can be muted', (tester) async {
    _useTallTestWindow(tester);
    await tester.pumpWidget(const BasePacerApp());

    final soundSwitch = find.byKey(const ValueKey('sound-cues-switch'));
    expect(tester.widget<SwitchListTile>(soundSwitch).value, isTrue);

    await tester.tap(soundSwitch);
    await tester.pump();

    expect(tester.widget<SwitchListTile>(soundSwitch).value, isFalse);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
  });
}

void _useTallTestWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
