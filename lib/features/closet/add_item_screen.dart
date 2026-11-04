import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/widgets/photo_placeholder.dart';
import 'closet_photo_picker.dart';
import 'tag_review_screen.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key, this.photoPicker});

  final ClosetPhotoPicker? photoPicker;

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  late final ClosetPhotoPicker _photoPicker =
      widget.photoPicker ?? ClosetPhotoPicker();
  bool _isPicking = false;

  Future<void> _addPhoto(ImageSource source) async {
    setState(() => _isPicking = true);
    try {
      final photoPath = await _photoPicker.pickAndSave(source);
      if (!mounted || photoPath == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TagReviewScreen(photoPath: photoPath),
        ),
      );
    } on PlatformException {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PhotoPlaceholder(icon: Icons.add_a_photo, height: 240),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take photo'),
            onPressed: _isPicking ? null : () => _addPhoto(ImageSource.camera),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text('Choose from gallery'),
            onPressed: _isPicking ? null : () => _addPhoto(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}
