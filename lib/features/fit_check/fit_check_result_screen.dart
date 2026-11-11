import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/ai/ai_service.dart';
import '../../core/images/photo_resizer.dart';
import '../../core/logging/app_log.dart';
import '../../core/widgets/photo_placeholder.dart';
import '../../core/widgets/status_views.dart';
import 'fit_check_photos.dart';
import 'fit_check_service.dart';

typedef ReadFitCheckPhoto = Future<Uint8List> Function(String photoPath);
typedef PrepareFitCheckPhoto = Future<Uint8List> Function(Uint8List bytes);

Future<Uint8List> _readFile(String photoPath) => File(photoPath).readAsBytes();

/// Shows the AI's verdict and suggestions for one outfit photo.
///
/// The picked photo is deleted when this screen closes. Save photo keeps a
/// copy in the app's own folder first.
class FitCheckResultScreen extends StatefulWidget {
  const FitCheckResultScreen({
    super.key,
    required this.photoPath,
    required this.occasion,
    required this.service,
    this.readPhoto = _readFile,
    this.preparePhoto = resizePhotoForAi,
    this.savePhoto = saveFitCheckPhoto,
    this.discardPhoto = discardFitCheckPhoto,
  });

  final String photoPath;
  final String occasion;
  final FitCheckService service;
  final ReadFitCheckPhoto readPhoto;
  final PrepareFitCheckPhoto preparePhoto;
  final SaveFitCheckPhoto savePhoto;
  final DiscardFitCheckPhoto discardPhoto;

  @override
  State<FitCheckResultScreen> createState() => _FitCheckResultScreenState();
}

class _FitCheckResultScreenState extends State<FitCheckResultScreen> {
  FitCheckFeedback? _feedback;
  String? _failure;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    // The picker's copy is never kept. A saved photo is a separate copy.
    AppLog.ui(
      _saved
          ? 'Fit Check: photo saved, picker copy removed'
          : 'Fit Check: photo not saved, discarded',
    );
    widget.discardPhoto(widget.photoPath);
    super.dispose();
  }

  void _retry() {
    AppLog.tap('Retry', screen: 'Fit Check Result');
    setState(() {
      _feedback = null;
      _failure = null;
    });
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes = await widget.preparePhoto(
        await widget.readPhoto(widget.photoPath),
      );
      final feedback = await widget.service.checkFit(
        FitCheckRequest(photo: bytes, occasion: widget.occasion),
      );
      if (mounted) setState(() => _feedback = feedback);
    } on AiServiceException catch (error) {
      if (mounted) setState(() => _failure = error.message);
    } on Object catch (error) {
      AppLog.ui('Fit Check failed: $error');
      if (mounted) {
        setState(
          () => _failure = 'We could not check this photo. Please retry.',
        );
      }
    }
  }

  Future<void> _save() async {
    AppLog.tap('Save photo', screen: 'Fit Check Result');
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.savePhoto(widget.photoPath);
      if (mounted) setState(() => _saved = true);
      messenger.showSnackBar(const SnackBar(content: Text('Photo saved')));
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save the photo.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    final feedback = _feedback;
    return Scaffold(
      appBar: AppBar(title: const Text('Fit Check Result')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(widget.photoPath),
              height: 280,
              fit: BoxFit.contain,
              semanticLabel: 'Your outfit photo',
              errorBuilder: (_, _, _) => const PhotoPlaceholder(height: 280),
            ),
          ),
          const SizedBox(height: 16),
          if (failure != null)
            ErrorRetryView(message: failure, onRetry: _retry)
          else if (feedback == null)
            const LoadingView(message: 'Checking your fit...')
          else
            ..._buildFeedback(context, feedback),
        ],
      ),
    );
  }

  List<Widget> _buildFeedback(BuildContext context, FitCheckFeedback feedback) {
    final theme = Theme.of(context);
    return [
      Semantics(
        header: true,
        child: Text(feedback.verdict, style: theme.textTheme.titleLarge),
      ),
      const SizedBox(height: 8),
      for (final suggestion in feedback.suggestions)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const ExcludeSemantics(child: Icon(Icons.lightbulb_outline)),
          title: Text(suggestion),
        ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: _saved || _saving ? null : _save,
        icon: Icon(_saved ? Icons.check : Icons.save_alt),
        label: Text(_saved ? 'Photo saved' : 'Save photo'),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Check another outfit'),
      ),
    ];
  }
}
