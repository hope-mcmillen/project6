import 'package:flutter/widgets.dart';

import 'age_confirmation.dart';
import 'connection_status.dart';

/// App-wide platform services, available on every route. Tests pass fakes
/// through `FitCheckApp`.
class AppDependencies extends InheritedWidget {
  const AppDependencies({
    super.key,
    required this.ageConfirmation,
    required this.connection,
    required super.child,
  });

  final AgeConfirmation ageConfirmation;
  final ConnectionStatus connection;

  static AppDependencies of(BuildContext context) {
    final found = context.getInheritedWidgetOfExactType<AppDependencies>();
    if (found == null) {
      throw StateError('No AppDependencies above this screen.');
    }
    return found;
  }

  @override
  bool updateShouldNotify(AppDependencies oldWidget) =>
      ageConfirmation != oldWidget.ageConfirmation ||
      connection != oldWidget.connection;
}
