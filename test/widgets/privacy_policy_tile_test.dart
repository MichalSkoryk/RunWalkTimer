import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_walk_timer/widgets/privacy_policy_tile.dart';

void main() {
  testWidgets('opens the exact hosted privacy policy externally', (
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

    await tester.tap(find.byKey(const ValueKey('privacy-policy-link')));
    await tester.pump();

    expect(openedUri, Uri.parse(privacyPolicyUrl));
  });

  testWidgets('shows a message when the privacy policy cannot be opened', (
    tester,
  ) async {
    await tester.pumpWidget(_TestApp(launcher: (_) async => false));

    await tester.tap(find.byKey(const ValueKey('privacy-policy-link')));
    await tester.pumpAndSettle();

    expect(
      find.text("Couldn't open the privacy policy. Please try again."),
      findsOneWidget,
    );
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.launcher});

  final PrivacyPolicyLauncher launcher;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: PrivacyPolicyTile(launchPrivacyPolicy: launcher)),
    );
  }
}
