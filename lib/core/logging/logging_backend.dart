import 'dart:async';
import 'dart:typed_data';

import '../ai/ai_service.dart';
import '../data/backend_services.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import 'app_log.dart';

/// Wraps every backend service so each Firestore and AI call is logged with
/// how long it took and what came back. Behavior is otherwise unchanged.
BackendServices withLogging(BackendServices services) => BackendServices(
  closet: LoggingClosetRepository(services.closet),
  outfits: LoggingOutfitRepository(services.outfits),
  profile: LoggingProfileRepository(services.profile),
  wearLogs: LoggingWearLogRepository(services.wearLogs),
  ai: LoggingAiService(services.ai),
);

/// Logs [what] when it starts and again when it finishes or fails.
Future<T> _logged<T>(
  void Function(String) log,
  String what,
  Future<T> Function() run, {
  String Function(T result)? describe,
}) async {
  final watch = Stopwatch()..start();
  log('$what...');
  try {
    final result = await run();
    final detail = describe == null ? '' : ': ${describe(result)}';
    log('$what done in ${watch.elapsedMilliseconds} ms$detail');
    return result;
  } on Object catch (error) {
    log('$what FAILED after ${watch.elapsedMilliseconds} ms: $error');
    rethrow;
  }
}

/// Passes a stream through, logging each update and error.
Stream<T> _loggedStream<T>(
  void Function(String) log,
  String what,
  Stream<T> stream,
  String Function(T value) describe,
) {
  log('$what: listening for changes');
  return stream.transform(
    StreamTransformer.fromHandlers(
      handleData: (value, sink) {
        log('$what update: ${describe(value)}');
        sink.add(value);
      },
      handleError: (error, stackTrace, sink) {
        log('$what stream FAILED: $error');
        sink.addError(error, stackTrace);
      },
    ),
  );
}

String _plural(int count, String noun) =>
    '$count $noun${count == 1 ? '' : 's'}';

/// "12 items (5 top, 4 bottom, 3 shoes)".
String describeCloset(List<ClothingItem> items) {
  if (items.isEmpty) return '0 items';
  final counts = <String, int>{};
  for (final item in items) {
    counts.update(item.tags.category, (n) => n + 1, ifAbsent: () => 1);
  }
  final parts = [for (final e in counts.entries) '${e.value} ${e.key}'];
  return '${_plural(items.length, 'item')} (${parts.join(', ')})';
}

String describeTags(ClothingTags tags) => [
  tags.category,
  tags.color,
  tags.pattern,
  tags.formality,
  tags.season,
].map((t) => t.isEmpty ? '-' : t).join(' / ');

class LoggingClosetRepository implements ClosetRepository {
  LoggingClosetRepository(this.inner);
  final ClosetRepository inner;

  @override
  Stream<List<ClothingItem>> watchItems() =>
      _loggedStream(AppLog.data, 'Closet', inner.watchItems(), describeCloset);

  @override
  Future<List<ClothingItem>> getItems() => _logged(
    AppLog.data,
    'Closet: loading items',
    inner.getItems,
    describe: describeCloset,
  );

  @override
  Future<void> saveItem(ClothingItem item) => _logged(
    AppLog.data,
    'Closet: saving item ${item.id} (${describeTags(item.tags)}'
    '${item.isSample ? ', sample' : ''})',
    () => inner.saveItem(item),
    describe: (_) => 'confirmed by Firestore',
  );

  @override
  Future<void> deleteItem(String id) => _logged(
    AppLog.data,
    'Closet: deleting item $id',
    () => inner.deleteItem(id),
    describe: (_) => 'confirmed by Firestore',
  );
}

class LoggingOutfitRepository implements OutfitRepository {
  LoggingOutfitRepository(this.inner);
  final OutfitRepository inner;

  @override
  Stream<List<Outfit>> watchOutfits() => _loggedStream(
    AppLog.data,
    'Outfits',
    inner.watchOutfits(),
    (outfits) => _plural(outfits.length, 'outfit'),
  );

  @override
  Future<void> saveOutfit(Outfit outfit) => _logged(
    AppLog.data,
    'Outfits: saving outfit ${outfit.id} '
    '(${_plural(outfit.itemIds.length, 'item')}, ${outfit.occasion})',
    () => inner.saveOutfit(outfit),
  );

  @override
  Future<void> deleteOutfit(String id) => _logged(
    AppLog.data,
    'Outfits: deleting outfit $id',
    () => inner.deleteOutfit(id),
  );
}

class LoggingProfileRepository implements ProfileRepository {
  LoggingProfileRepository(this.inner);
  final ProfileRepository inner;

  @override
  Future<StyleProfile> getProfile() => _logged(
    AppLog.data,
    'Profile: loading style profile',
    inner.getProfile,
    describe: (profile) => 'style "${profile.style}"',
  );

  @override
  Future<void> saveProfile(StyleProfile profile) => _logged(
    AppLog.data,
    'Profile: saving style "${profile.style}"',
    () => inner.saveProfile(profile),
  );
}

class LoggingWearLogRepository implements WearLogRepository {
  LoggingWearLogRepository(this.inner);
  final WearLogRepository inner;

  @override
  Future<List<WearLog>> getWearLogs() => _logged(
    AppLog.data,
    'Wear log: loading entries',
    inner.getWearLogs,
    describe: (logs) =>
        '${logs.length} ${logs.length == 1 ? 'entry' : 'entries'}',
  );

  @override
  Future<void> saveWearLog(WearLog log) => _logged(
    AppLog.data,
    'Wear log: saving entry ${log.id} for outfit ${log.outfitId}',
    () => inner.saveWearLog(log),
  );
}

class LoggingAiService implements AiService {
  LoggingAiService(this.inner);
  final AiService inner;

  @override
  Future<ClothingTags> tagClothing(Uint8List photoBytes) => _logged(
    AppLog.ai,
    'Tagging a ${(photoBytes.length / 1024).round()} KB photo',
    () => inner.tagClothing(photoBytes),
    describe: describeTags,
  );

  @override
  Future<List<Outfit>> generateOutfits(OutfitRequest request) => _logged(
    AppLog.ai,
    'Generating outfits for "${request.occasion}" from '
    '${_plural(request.closet.length, 'closet item')}',
    () => inner.generateOutfits(request),
    describe: (outfits) => _plural(outfits.length, 'outfit'),
  );
}
