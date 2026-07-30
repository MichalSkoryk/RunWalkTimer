import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const privacyPolicyUrl =
    'https://michalskoryk.github.io/RunWalkTimer/privacy.html';

typedef PrivacyPolicyLauncher = Future<bool> Function(Uri uri);

Future<bool> launchPrivacyPolicyPage(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

class PrivacyPolicyTile extends StatelessWidget {
  const PrivacyPolicyTile({
    this.launchPrivacyPolicy = launchPrivacyPolicyPage,
    super.key,
  });

  final PrivacyPolicyLauncher launchPrivacyPolicy;

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    var didLaunch = false;
    try {
      didLaunch = await launchPrivacyPolicy(Uri.parse(privacyPolicyUrl));
    } on Exception {
      didLaunch = false;
    }

    if (!didLaunch && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't open the privacy policy. Please try again."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: const ValueKey('privacy-policy-link'),
      leading: const Icon(Icons.privacy_tip_outlined),
      title: const Text(
        'Privacy policy',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: const Text('Opens in your browser'),
      trailing: const Icon(Icons.open_in_new_rounded, size: 20),
      onTap: () => _openPrivacyPolicy(context),
    );
  }
}
