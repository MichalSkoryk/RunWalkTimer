import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_walk_timer/app.dart';

void main() {
  testWidgets('shows interval goal by default and switches to a time goal', (
    tester,
  ) async {
    _useTallTestWindow(tester);
    await tester.pumpWidget(const RunWalkTimerApp());

    expect(find.text('Run/Walk Timer'), findsOneWidget);
    final supportButton = find.byKey(
      const ValueKey('developer-support-button'),
    );
    expect(supportButton, findsOneWidget);
    expect(
      find.ancestor(of: supportButton, matching: find.byType(AppBar)),
      findsOneWidget,
    );
    expect(find.text('Walk duration'), findsOneWidget);
    expect(find.text('Run duration'), findsOneWidget);
    expect(find.byKey(const ValueKey('interval-count-input')), findsOneWidget);
    expect(find.byKey(const ValueKey('total')), findsNothing);

    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('total')), findsOneWidget);
    expect(find.byKey(const ValueKey('interval-count-input')), findsNothing);
  });

  testWidgets('running hides setup and pause or stop restores it', (
    tester,
  ) async {
    _useTallTestWindow(tester);
    await tester.pumpWidget(const RunWalkTimerApp());

    await tester.tap(find.byKey(const ValueKey('start-button')));
    await tester.pump();

    expect(find.text('CURRENT MODE'), findsOneWidget);
    expect(find.text('WALKING'), findsOneWidget);
    expect(find.text('CURRENT INTERVAL LEFT'), findsOneWidget);
    expect(find.byKey(const ValueKey('main-countdown')), findsOneWidget);
    expect(find.text('OVERALL TIME LEFT'), findsOneWidget);
    expect(find.byKey(const ValueKey('overall-countdown')), findsOneWidget);
    expect(find.text('Workout setup'), findsNothing);
    expect(find.byKey(const ValueKey('walk-minutes')), findsNothing);
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
          .widget<TextField>(find.byKey(const ValueKey('walk-minutes')))
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
          .widget<TextField>(find.byKey(const ValueKey('walk-minutes')))
          .enabled,
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('invalid zero duration disables Start and explains why', (
    tester,
  ) async {
    _useTallTestWindow(tester);
    await tester.pumpWidget(const RunWalkTimerApp());

    await tester.enterText(find.byKey(const ValueKey('walk-minutes')), '0');
    await tester.enterText(find.byKey(const ValueKey('walk-seconds')), '0');
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
    await tester.pumpWidget(const RunWalkTimerApp());

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
