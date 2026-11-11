import 'package:flutter/material.dart';

import '../core/logging/app_log.dart';
import '../core/widgets/status_views.dart';
import 'app_dependencies.dart';
import 'app_shell.dart';
import 'welcome_screen.dart';

/// Shows the welcome screen until the user confirms they are 18 or older,
/// then the app. Firebase has already started by the time this builds; see
/// `FirebaseBackend` for the connecting and retry screens.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late final _ageConfirmation = AppDependencies.of(context).ageConfirmation;
  bool? _confirmed;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    bool confirmed;
    try {
      confirmed = await _ageConfirmation.isConfirmed();
    } on Object catch (error) {
      // If the setting cannot be read, asking again is the safe choice.
      AppLog.app('Could not read the age confirmation: $error');
      confirmed = false;
    }
    AppLog.app(confirmed ? 'Repeat launch' : 'First launch: showing welcome');
    if (mounted) setState(() => _confirmed = confirmed);
  }

  Future<void> _confirm() async {
    await _ageConfirmation.confirm();
    AppLog.app('Age confirmed');
    if (mounted) setState(() => _confirmed = true);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_confirmed) {
      null => const Scaffold(body: LoadingView()),
      false => WelcomeScreen(onConfirmed: _confirm),
      true => const AppShell(),
    };
  }
}
