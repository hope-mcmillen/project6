import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/ai/ai_service.dart';
import '../../core/data/repositories.dart';
import '../../core/logging/app_log.dart';
import 'closet_heading.dart';
import 'closet_photo_picker.dart';
import 'tag_review_screen.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({
    super.key,
    this.photoPicker,
    this.repository,
    this.ai,
    this.onSaved,
  });

  final ClosetPhotoPicker? photoPicker;
  final ClosetRepository? repository;
  final AiService? ai;

  /// Called after a new item is saved and the app is back on its first route.
  final VoidCallback? onSaved;

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  late final ClosetPhotoPicker _photoPicker =
      widget.photoPicker ?? ClosetPhotoPicker();
  bool _isPicking = false;

  Future<void> _addPhoto(ImageSource source) async {
    final from = source == ImageSource.camera ? 'camera' : 'gallery';
    AppLog.tap(
      source == ImageSource.camera ? 'Take photo' : 'Choose from gallery',
      screen: 'Add Item',
    );
    setState(() => _isPicking = true);
    try {
      final photoPath = await _photoPicker.pickAndSave(source);
      if (photoPath == null) {
        AppLog.ui('Photo from $from cancelled');
        return;
      }
      AppLog.ui('Photo from $from saved to the closet photos folder');
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/review-tags'),
          builder: (_) => TagReviewScreen(
            photoPath: photoPath,
            repository: widget.repository,
            ai: widget.ai,
            onSaved: widget.onSaved,
          ),
        ),
      );
    } on PlatformException catch (error) {
      AppLog.ui('Could not open the $from: ${error.code} ${error.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_failureMessage(source))));
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  String _failureMessage(ImageSource source) {
    return switch (source) {
      ImageSource.camera =>
        'Could not open the camera. Check camera access in Settings, or choose '
            'a photo from your gallery.',
      ImageSource.gallery =>
        'Could not open your gallery. Check photo access in Settings.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    // Pushed from the closet it gets a back button; as an app tab it does not.
    final isPushed = ModalRoute.of(context)?.canPop ?? false;
    return Scaffold(
      appBar: isPushed ? AppBar(title: const Text('Add Item')) : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          const ClosetHeading(
            eyebrow: 'A LITTLE CLOSET REFRESH',
            title: 'Meet your next staple.',
            subtitle: 'Snap one piece and we will suggest its tags.',
          ),
          ClosetCard(
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                Icon(Icons.add_a_photo_outlined, size: 90, color: primary),
                const SizedBox(height: 16),
                const Text(
                  'Photograph only the clothing item, laid flat or on a '
                  'hanger, with no people in the photo.',
                  textAlign: .center,
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take photo'),
                  onPressed: _isPicking
                      ? null
                      : () => _addPhoto(ImageSource.camera),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Choose from gallery'),
                  onPressed: _isPicking
                      ? null
                      : () => _addPhoto(ImageSource.gallery),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
