import 'package:flutter/material.dart';

import '../../core/data/firebase_backend.dart';
import '../../core/data/models.dart';
import '../../core/data/repositories.dart';
import '../../core/logging/app_log.dart';
import '../../core/widgets/status_views.dart';

/// Three optional questions that shape outfit suggestions. Any of them can be
/// left blank, and Skip leaves without saving.
class StyleProfileScreen extends StatefulWidget {
  const StyleProfileScreen({super.key, this.repository});

  /// Defaults to the app's profile repository.
  final ProfileRepository? repository;

  @override
  State<StyleProfileScreen> createState() => _StyleProfileScreenState();
}

/// Splits "black, neon green" into ["black", "neon green"].
List<String> splitList(String text) => [
  for (final part in text.split(','))
    if (part.trim().isNotEmpty) part.trim(),
];

class _StyleProfileScreenState extends State<StyleProfileScreen> {
  late final ProfileRepository _repository =
      widget.repository ??
      context.getInheritedWidgetOfExactType<BackendScope>()!.services.profile;

  final _style = TextEditingController();
  final _colorsToAvoid = TextEditingController();
  final _occasions = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _style.dispose();
    _colorsToAvoid.dispose();
    _occasions.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final profile = await _repository.getProfile();
      if (!mounted) return;
      setState(() {
        _style.text = profile.style;
        _colorsToAvoid.text = profile.colorsToAvoid.join(', ');
        _occasions.text = profile.regularOccasions.join(', ');
        _loading = false;
      });
    } on Object catch (error) {
      AppLog.ui('Style profile failed to load: $error');
      if (!mounted) return;
      setState(() {
        _failure = 'Could not load your style profile.';
        _loading = false;
      });
    }
  }

  void _retry() {
    setState(() {
      _failure = null;
      _loading = true;
    });
    _load();
  }

  Future<void> _save() async {
    AppLog.tap('Save', screen: 'Style Profile');
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await _repository.saveProfile(
        StyleProfile(
          style: _style.text.trim(),
          colorsToAvoid: splitList(_colorsToAvoid.text),
          regularOccasions: splitList(_occasions.text),
        ),
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Style profile saved')),
      );
      navigator.pop();
    } on Object catch (error) {
      AppLog.ui('Style profile failed to save: $error');
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(TextEditingController controller, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: 'Optional',
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Style Profile'),
        actions: [
          TextButton(
            onPressed: () {
              AppLog.tap('Skip', screen: 'Style Profile');
              Navigator.of(context).pop();
            },
            child: const Text('Skip'),
          ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : failure != null
          ? ErrorRetryView(message: failure, onRetry: _retry)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Answer any of these to tailor outfit suggestions. Leave '
                  'a question blank to skip it.',
                ),
                const SizedBox(height: 16),
                _field(
                  _style,
                  'What is your style?',
                  'Like minimal, sporty, or preppy',
                ),
                _field(
                  _colorsToAvoid,
                  'Which colors should we avoid?',
                  'Separate with commas, like orange, neon green',
                ),
                _field(
                  _occasions,
                  'What occasions do you dress for?',
                  'Separate with commas, like class, work, gym',
                ),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Save'),
                ),
              ],
            ),
    );
  }
}
