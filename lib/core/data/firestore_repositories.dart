import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models.dart';
import 'repositories.dart';

/// Call after Firebase.initializeApp. Reuses the persisted anonymous account.
Future<User> ensureAnonymousSignIn(FirebaseAuth auth) async {
  final existing = auth.currentUser;
  if (existing != null) return existing;
  final user = (await auth.signInAnonymously()).user;
  if (user == null) throw StateError('Sign-in failed. Please retry.');
  return user;
}

/// Construct after sign-in. Recreate on any account change; do not reuse a uid.
class UserFirestore {
  UserFirestore({required this.firestore, required this.uid}) {
    _checkId(uid);
  }
  final FirebaseFirestore firestore;
  final String uid;
  CollectionReference<Map<String, dynamic>> collection(String name) =>
      firestore.collection('users').doc(uid).collection(name);
}

void _checkId(String id) {
  if (id.isEmpty || id.contains('/') || id == '.' || id == '..') {
    throw ArgumentError.value(id, 'id', 'Use a nonempty single document ID.');
  }
}

class FirestoreClosetRepository implements ClosetRepository {
  FirestoreClosetRepository(UserFirestore user)
    : _items = user.collection('items');
  final CollectionReference<Map<String, dynamic>> _items;
  List<ClothingItem> _decode(QuerySnapshot<Map<String, dynamic>> snapshot) => [
    for (final doc in snapshot.docs) ClothingItem.fromMap(doc.id, doc.data()),
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  @override
  Stream<List<ClothingItem>> watchItems() => _items.snapshots().map(_decode);
  @override
  Future<List<ClothingItem>> getItems() async => _decode(await _items.get());
  @override
  Future<void> saveItem(ClothingItem item) {
    _checkId(item.id);
    return _items.doc(item.id).set(item.toMap());
  }

  @override
  Future<void> deleteItem(String id) {
    _checkId(id);
    return _items.doc(id).delete();
  }
}

class FirestoreOutfitRepository implements OutfitRepository {
  FirestoreOutfitRepository(UserFirestore user)
    : _items = user.collection('outfits');
  final CollectionReference<Map<String, dynamic>> _items;
  @override
  Stream<List<Outfit>> watchOutfits() => _items.snapshots().map(
    (s) =>
        [for (final doc in s.docs) Outfit.fromMap(doc.id, doc.data())]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );
  @override
  Future<void> saveOutfit(Outfit outfit) {
    _checkId(outfit.id);
    return _items.doc(outfit.id).set(outfit.toMap());
  }

  @override
  Future<void> deleteOutfit(String id) {
    _checkId(id);
    return _items.doc(id).delete();
  }
}

class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository(UserFirestore user)
    : _profile = user.collection('profile').doc('style');
  final DocumentReference<Map<String, dynamic>> _profile;
  @override
  Future<StyleProfile> getProfile() async {
    final data = (await _profile.get()).data();
    return data == null ? StyleProfile() : StyleProfile.fromMap(data);
  }

  @override
  Future<void> saveProfile(StyleProfile profile) =>
      _profile.set(profile.toMap());
}

class FirestoreWearLogRepository implements WearLogRepository {
  FirestoreWearLogRepository(UserFirestore user)
    : _logs = user.collection('wearLogs');
  final CollectionReference<Map<String, dynamic>> _logs;
  @override
  Future<List<WearLog>> getWearLogs() async => [
    for (final doc in (await _logs.get()).docs)
      WearLog.fromMap(doc.id, doc.data()),
  ];
  @override
  Future<void> saveWearLog(WearLog log) {
    _checkId(log.id);
    return _logs.doc(log.id).set(log.toMap());
  }
}
