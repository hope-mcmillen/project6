import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/logging/app_log.dart';
import 'fit_check_result_screen.dart';
import 'fit_check_service.dart';

typedef PickFitCheckPhoto = Future<XFile?> Function(ImageSource source);

Future<XFile?> _pickWithImagePicker(ImageSource source) =>
    ImagePicker().pickImage(source: source);

/// The Fit Check tab: choose the occasion, then photograph the outfit.
class FitCheckScreen extends StatefulWidget {
  const FitCheckScreen({
    super.key,
    this.service = const PendingFitCheckService(),
    this.pickPhoto = _pickWithImagePicker,
  });

  /// Member 3's Fit Check AI from M3-09. Until it is merged, the result
  /// screen explains that feedback is not connected yet.
  final FitCheckService service;
  final PickFitCheckPhoto pickPhoto;

  static const occasions = [
    'Everyday',
    'Class',
    'Work',
    'Going out',
    'Interview',
  ];

  /// The app uses the free Gemini tier, so photos must not show people.
  static const photoRule =
      'Photograph the outfit on a hanger, on a bed, or laid flat, with no '
      'person in the photo. Photos of people cannot be checked.';

  @override
  State<FitCheckScreen> createState() => _FitCheckScreenState();
}

class _FitCheckScreenState extends State<FitCheckScreen> {
  String _occasion = FitCheckScreen.occasions.first;
  bool _picking = false;

  Future<void> _check(ImageSource source) async {
    final from = source == ImageSource.camera ? 'camera' : 'gallery';
    AppLog.tap('Fit Check from $from', screen: 'Fit Check');
    setState(() => _picking = true);
    try {
      final photo = await widget.pickPhoto(source);
      if (photo == null || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/fit-check-result'),
          builder: (_) => FitCheckResultScreen(
            photoPath: photo.path,
            occasion: _occasion,
            service: widget.service,
          ),
        ),
      );
    } on PlatformException catch (error) {
      AppLog.ui('Fit Check could not open the $from: ${error.code}');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              source == ImageSource.camera
                  ? 'Could not open the camera. Check camera access in '
                        'Settings, or choose a photo from your gallery.'
                  : 'Could not open your gallery. Check photo access in '
                        'Settings.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        Semantics(
          header: true,
          child: Text('Fit Check', style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(height: 8),
        const Text(
          'Photograph your outfit and get feedback for the occasion.',
        ),
        const SizedBox(height: 16),
        Card(
          color: theme.colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: Icon(Icons.no_accounts)),
                SizedBox(width: 12),
                Expanded(child: Text(FitCheckScreen.photoRule)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Occasion', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final occasion in FitCheckScreen.occasions)
              ChoiceChip(
                label: Text(occasion),
                selected: occasion == _occasion,
                onSelected: (_) {
                  AppLog.tap('Occasion: $occasion', screen: 'Fit Check');
                  setState(() => _occasion = occasion);
                },
              ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: const Text('Take photo'),
          onPressed: _picking ? null : () => _check(ImageSource.camera),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.photo_library),
          label: const Text('Choose from gallery'),
          onPressed: _picking ? null : () => _check(ImageSource.gallery),
        ),
      ],
    );
  }
}
