import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_walk_timer/widgets/developer_support_button.dart';

void main() {
  testWidgets('explains optional support before opening the exact page', (
    tester,
  ) async {
    Uri? openedUri;
    await tester.pumpWidget(
      _TestApp(
        launcher: (uri) async {
          openedUri = uri;
          return true;
        },
      ),
    );

    await tester.tap(find.byKey(const ValueKey('developer-support-button')));
    await tester.pumpAndSettle();

    expect(find.text('Support the developer'), findsOneWidget);
    expect(
      find.textContaining('Tips do not unlock any features.'),
      findsOneWidget,
    );
    expect(openedUri, isNull);

    await tester.tap(find.byKey(const ValueKey('open-support-page-button')));
    await tester.pumpAndSettle();

    expect(openedUri, Uri.parse(developerSupportUrl));
  });

  testWidgets('Not now closes the dialog without opening the page', (
    tester,
  ) async {
    var launchCount = 0;
    await tester.pumpWidget(
      _TestApp(
        launcher: (_) async {
          launchCount += 1;
          return true;
        },
      ),
    );

    await tester.tap(find.byKey(const ValueKey('developer-support-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Support the developer'), findsNothing);
    expect(launchCount, 0);
  });

  testWidgets('shows a message when the support page cannot be opened', (
    tester,
  ) async {
    await tester.pumpWidget(_TestApp(launcher: (_) async => false));

    await tester.tap(find.byKey(const ValueKey('developer-support-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-support-page-button')));
    await tester.pumpAndSettle();

    expect(
      find.text("Couldn't open buycoffee.to. Please try again."),
      findsOneWidget,
    );
  });

  testWidgets('fits in a narrow app bar with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: _TestApp(launcher: (_) async => true, includeTitle: true),
      ),
    );

    expect(tester.takeException(), isNull);
    final buttonRect = tester.getRect(
      find.byKey(const ValueKey('developer-support-button')),
    );
    expect(buttonRect.right, lessThanOrEqualTo(320));
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.launcher, this.includeTitle = false});

  final SupportPageLauncher launcher;
  final bool includeTitle;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: includeTitle
              ? const Text(
                  'Run/Walk Timer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          actions: [DeveloperSupportButton(launchSupportPage: launcher)],
        ),
      ),
    );
  }
}
