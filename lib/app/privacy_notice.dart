import 'package:flutter/material.dart';

/// One point of the privacy notice.
class PrivacyPoint {
  const PrivacyPoint(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

/// The final privacy notice: what leaves the phone and where it goes. Shown on
/// the welcome screen and in Settings > Privacy.
const privacyPoints = [
  PrivacyPoint(
    Icons.checkroom,
    'Clothing photos stay on your phone',
    'When you add an item, a smaller copy of its photo is sent to Google '
        'Gemini, through Firebase AI Logic, to suggest tags. The photo itself '
        'is never stored in our database.',
  ),
  PrivacyPoint(
    Icons.no_accounts,
    'Photograph clothing, not people',
    'We use the free Gemini tier, where Google may use what we send to '
        'improve its products. Keep people out of every photo, including Fit '
        'Check photos.',
  ),
  PrivacyPoint(
    Icons.camera_alt,
    'Fit Check photos are deleted unless you save them',
    'A Fit Check photo is sent to Gemini for feedback, then removed from your '
        'phone unless you tap Save photo.',
  ),
  PrivacyPoint(
    Icons.cloud,
    'Your closet is stored in Google Firebase',
    'Clothing tags, saved outfits, your style profile, and wear history are '
        'stored in Cloud Firestore under an anonymous account. We never ask '
        'for your name, email, or phone number.',
  ),
  PrivacyPoint(
    Icons.location_on,
    'Weather uses your approximate location',
    'If you allow location, a rounded location is sent to Open-Meteo to get '
        'the weather. You can type a city instead.',
  ),
  PrivacyPoint(
    Icons.verified_user,
    'Security checks',
    'Firebase App Check confirms with Google that requests come from a real '
        'copy of this app.',
  ),
  PrivacyPoint(
    Icons.delete_forever,
    'Delete everything at any time',
    'Settings > Delete all my data removes your Firestore data and the photos '
        'this app saved on your phone.',
  ),
];

/// Lists [privacyPoints]. Not scrollable itself; put it in a scroll view.
class PrivacyNotice extends StatelessWidget {
  const PrivacyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final point in privacyPoints)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Icon(point.icon, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(point.title, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(point.body),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
