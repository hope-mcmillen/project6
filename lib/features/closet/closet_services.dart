import 'package:flutter/widgets.dart';

import '../../core/data/backend_services.dart';
import '../../core/data/firebase_backend.dart';
import '../../core/data/models.dart';

/// Finds the app's shared services. It does not subscribe to changes, so it is
/// safe to call from initState.
BackendServices closetServices(BuildContext context) {
  final scope = context.getInheritedWidgetOfExactType<BackendScope>();
  if (scope == null) throw StateError('No BackendScope above this screen.');
  return scope.services;
}

String capitalized(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// The display label for a stored category, such as 'top' -> 'Top'.
String categoryLabel(String category) => capitalized(category);

String itemName(ClothingItem item) =>
    capitalized('${item.tags.color} ${item.tags.category}'.trim());

String newClosetId() => DateTime.now().microsecondsSinceEpoch.toString();
