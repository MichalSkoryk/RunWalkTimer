import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const developerSupportUrl = 'https://buycoffee.to/michal-skoryk';

typedef SupportPageLauncher = Future<bool> Function(Uri uri);

Future<bool> launchDeveloperSupportPage(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

class DeveloperSupportButton extends StatelessWidget {
  const DeveloperSupportButton({
    this.launchSupportPage = launchDeveloperSupportPage,
    super.key,
  });

  final SupportPageLauncher launchSupportPage;

  Future<void> _showSupportDialog(BuildContext context) async {
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support the developer'),
        content: const Text(
          'Base Pacer is free to use. If it helps with your workouts, '
          'you can leave an optional tip on buycoffee.to. Tips do not unlock '
          'any features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            key: const ValueKey('open-support-page-button'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open buycoffee.to'),
          ),
        ],
      ),
    );

    if (shouldOpen != true || !context.mounted) {
      return;
    }

    var didLaunch = false;
    try {
      didLaunch = await launchSupportPage(Uri.parse(developerSupportUrl));
    } on Exception {
      didLaunch = false;
    }

    if (!didLaunch && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't open buycoffee.to. Please try again."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Support the developer',
      child: Semantics(
        button: true,
        label: 'Support the developer',
        excludeSemantics: true,
        child: TextButton.icon(
          key: const ValueKey('developer-support-button'),
          onPressed: () => _showSupportDialog(context),
          icon: const Icon(Icons.favorite_outline_rounded, size: 18),
          label: const Text('Support'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            visualDensity: VisualDensity.compact,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
