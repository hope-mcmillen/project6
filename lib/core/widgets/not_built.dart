import 'package:flutter/material.dart';

/// Marks a control whose feature does not exist yet. Delete each call as the
/// matching requirement gets built.
void showNotBuilt(BuildContext context, String feature) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('Not built yet: $feature')));
}
