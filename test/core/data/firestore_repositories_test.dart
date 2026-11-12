import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitcheck_ai/core/data/firestore_repositories.dart';
import 'package:fitcheck_ai/core/data/fake_repositories.dart';
import 'package:fitcheck_ai/core/data/models.dart';

void main() {
  test('anonymous sign-in reuses the current account', () async {
    final auth = MockFirebaseAuth();
    final user = await ensureAnonymousSignIn(auth);
    expect(user.isAnonymous, isTrue);
    expect((await ensureAnonymousSignIn(auth)).uid, user.uid);
  });
  test(
    'closet repository saves under the uid and a new repository reloads it',
    () async {
      final db = FakeFirebaseFirestore();
      final user = UserFirestore(firestore: db, uid: 'alice');
      final repo = FirestoreClosetRepository(user);
      final item = sampleCloset().first;
      await repo.saveItem(item);
      expect(
        (await db.doc('users/alice/items/${item.id}').get()).data(),
        item.toMap(),
      );
      expect(
        (await FirestoreClosetRepository(user).getItems()).single.id,
        item.id,
      );
      expect(
        await FirestoreClosetRepository(
          UserFirestore(firestore: db, uid: 'bob'),
        ).getItems(),
        isEmpty,
      );
      await expectLater(
        () => repo.saveItem(
          ClothingItem(
            id: 'nested/id',
            photoPath: '',
            tags: item.tags,
            createdAt: item.createdAt,
          ),
        ),
        throwsArgumentError,
      );
    },
  );
  test(
    'closet skips a malformed document and still shows the others',
    () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreClosetRepository(
        UserFirestore(firestore: db, uid: 'alice'),
      );
      final good = sampleCloset().first;
      await repo.saveItem(good);
      await db.doc('users/alice/items/broken').set({
        'photoPath': '/photos/broken.jpg',
        'createdAt': 'not a date',
      });

      expect((await repo.getItems()).map((item) => item.id), [good.id]);
      expect((await repo.watchItems().first).map((item) => item.id), [good.id]);
    },
  );
  test('outfits, profile, and wear logs round trip; deleting item preserves missing references', () async {
    final user = UserFirestore(
      firestore: FakeFirebaseFirestore(),
      uid: 'alice',
    );
    final items = FirestoreClosetRepository(user);
    final item = sampleCloset().first;
    await items.saveItem(item);
    final repo = FirestoreOutfitRepository(user);
    final outfit = Outfit(
      id: 'one',
      itemIds: [item.id],
      reason: 'Blue works.',
      occasion: 'work',
      createdAt: DateTime.utc(2026),
    );
    await repo.saveOutfit(outfit);
    await items.deleteItem(item.id);
    expect((await repo.watchOutfits().first).single.itemIds, [item.id]);
    await repo.deleteOutfit(outfit.id);
    expect(await repo.watchOutfits().first, isEmpty);
    final profile = FirestoreProfileRepository(user);
    expect((await profile.getProfile()).style, '');
    await profile.saveProfile(StyleProfile(style: 'classic'));
    expect((await profile.getProfile()).style, 'classic');
    final logs = FirestoreWearLogRepository(user);
    await logs.saveWearLog(
      WearLog(
        id: 'log',
        outfitId: 'one',
        itemIds: [item.id],
        wornAt: DateTime.utc(2026),
      ),
    );
    expect((await logs.getWearLogs()).single.outfitId, 'one');
  });
  // These exercise the checked-in rules using the fake rules evaluator, not a deployed project.
  for (final collection in ['items', 'outfits', 'profile', 'wearLogs']) {
    test(
      'rules permit owner and deny anonymous/other uid access to $collection',
      () async {
        final auth = MockFirebaseAuth(
          mockUser: MockUser(uid: 'alice', isAnonymous: true),
        );
        final db = FakeFirebaseFirestore(
          // The fake parser lacks the rules_version directive. Keep the policy verbatim.
          securityRules: File('firestore.rules')
              .readAsStringSync()
              .replaceFirst("rules_version = '2';", ''),
          authObject: auth.authForFakeFirestore,
        );
        final own = db.doc('users/alice/$collection/one');
        final other = db.doc('users/bob/$collection/one');
        final denied =
            throwsException; // The fake evaluator throws a plain Exception.
        await expectLater(own.get(), denied);
        await expectLater(own.set({'value': 1}), denied);
        await auth.signInAnonymously();
        await own.set({'value': 1});
        expect((await own.get()).get('value'), 1);
        await own.update({'value': 2});
        await expectLater(other.get(), denied);
        await expectLater(other.set({'value': 1}), denied);
        await expectLater(other.update({'value': 2}), denied);
        await expectLater(other.delete(), denied);
        await own.delete();
        await expectLater(db.doc('global/one').set({'value': 1}), denied);
        await auth.signOut();
        await expectLater(own.get(), denied);
      },
    );
  }
}
