# Member 3 backend handoff

## Interfaces for Kameron and Hope (M3-02)

Import models from `lib/core/data/models.dart`, repository contracts from
`repositories.dart`, and `AiService` from `lib/core/ai/ai_service.dart`.
Create ONE `BackendServices.fake()` in startup and pass its fields to screens.
Do not create a new fake repository on every screen or data will appear lost.
`withSampleCloset: true` supplies metadata fixtures only; Member 1 provides the
actual licensed assets. Fakes work without Firebase initialization.

```dart
final services = BackendServices.fake();
final tags = await services.ai.tagClothing(photoBytes);
await services.closet.saveItem(ClothingItem(
  id: yourStableId, photoPath: savedPhotoPath, tags: editedTags,
  createdAt: DateTime.now(),
));
final items = await services.closet.getItems();
final request = OutfitRequest(closet: items, occasion: occasion, note: note);
// Check missingCategories in the request screen and name missing pieces.
final outfits = await services.ai.generateOutfits(request);
```

Canonical categories: `top`, `bottom`, `dress`, `shoes`, `outerwear`, `accessory`.
Display labels may be title case, but store canonical values. The other four
tags are short text. `copyWith` supports tag edits and laundry status. Fake AI
accepts `outfitCount` 1–3 and explicit failure flags to test screens. Handle
`AiServiceException.message` with retry/manual entry.

Closet `watchItems()` and lookbook `watchOutfits()` emit the initial state and
later changes. Repository deletion removes metadata only: Member 1 owns local
file deletion. Saved outfits retain item IDs after closet deletion so the
lookbook can label missing items. Fake repositories intentionally do not survive
a process restart.

## Firestore and startup (M3-01, M3-05)

No Firebase project exists yet. Google sign-in is pending. Once configured,
Member 4 calls this from startup and provides loading/error/retry UI:

```dart
final services = await BackendServices.connect(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

The real `DefaultFirebaseOptions` comes from `flutterfire configure`; do not
invent IDs or API keys. `connect` initializes Firebase, reuses/signs in the
anonymous account, enables Firestore persistence and creates scoped services.
Recreate services on account changes. Android/Apple offline persistence caches
previously read data and queues writes; a write Future can remain pending until
the server acknowledges it. Use stream state for immediate UI updates.
Anonymous accounts are device/install scoped; uninstalling can lose access.

Collections (all documents contain text/bools/lists/maps, never image bytes):

| Path | Model |
| --- | --- |
| `users/{uid}/items/{itemId}` | ClothingItem, including local photoPath, tags and UTC ISO createdAt |
| `users/{uid}/outfits/{outfitId}` | Outfit, with itemIds, reason, occasion and UTC ISO createdAt |
| `users/{uid}/profile/style` | StyleProfile |
| `users/{uid}/wearLogs/{logId}` | WearLog with itemIds and UTC ISO wornAt |

`firestore.rules` denies unauthenticated access and other users' paths. Its
owner rule covers all user subcollections. It is NOT deployed yet. Rules tests
use a fake evaluator, which lacks query/batch enforcement and the version
directive; live/emulator checks are still required before release.

## Firebase console setup after sign-in

1. Create the team's FitCheck AI project on the free Spark plan. Leave billing
   and optional analytics off. The account owner accepts any new legal terms.
2. Register the Android package already in this repo (`com.example.project6`)
   unless the team chooses a different package. Register additional platforms
   only as needed. Run the official Firebase and FlutterFire setup, then commit
   real generated `lib/firebase_options.dart` and necessary platform config.
3. Enable Anonymous sign-in. Create Firestore in production/locked mode, then
   deploy this repo's rules with `firebase deploy --only firestore --project REAL_PROJECT_ID`.
4. Enable Firebase AI Logic using the Gemini Developer API. Never bundle an
   AI Studio secret or load `.env` as a Flutter asset. `firebase_ai` uses Firebase
   client configuration. The default model is `gemini-3.8-flash`, configurable
   in `BackendServices.connect`. Check project/model availability with a live call.
5. Give the account owner a concrete teammate-email/role list for access approval.
6. Verify owner access succeeds and another anonymous UID fails for get/list/
   create/update/delete. Verify offline reads after a prior sync and an app restart.

## AI tagging/outfits (M3-04, M3-06)

Tagging prepares a JPEG at at most 1024px on the long edge on an isolate. A
temporary adapter is in `core/ai/clothing_photo_preparer.dart`; inject Keith's
M4-12 helper via `preparePhoto` once available. Never send person photos on the
free tier; screens must communicate/enforce the team's photo rule. No client-side
image classifier can currently guarantee a photo contains no person.

The Firebase client requests schema-constrained JSON; local parsing also checks
types, required tags, lengths and category values. Malformed replies get one
retry. Each network attempt has a 10-second timeout; the overall operation can
take longer on retry and no live latency claim has been verified.

Outfit requests include tags/IDs, occasion, note and optional weather. They never
include image paths or bytes. An incomplete closet causes no AI call. Unknown,
duplicate, laundry or incomplete item sets are discarded; if none remain, retry
once and then surface a clear error. Responses are deduplicated and limited to
three. Clothing-only wording is requested in the prompt; human review of live
responses remains necessary. Prompts alone do not guarantee safe wording.

## Validation and remaining work

Run `flutter analyze` and `flutter test`. Tests cover shared contracts/fakes,
sign-in reuse, scoped persistence round trips, owner-only document access using
the fake rules evaluator, image preparation, malformed JSON/retries/timeouts,
and invalid outfit IDs. Existing screen tests also remain in the suite.

Still required: console provisioning/configuration/deploy, real AI tagging and
outfit smoke checks, true offline/restart tests, teammate screen integration and
Android full-flow verification. M3-07–11 are scheduled in MARCUS_DAILY_PLAN.md.
No P0 card should be marked Done solely because its code has been written.

References: [Flutter setup](https://firebase.google.com/docs/flutter/setup),
[structured output](https://firebase.google.com/docs/ai-logic/generate-structured-output),
[supported models](https://firebase.google.com/docs/ai-logic/models),
[Firestore offline](https://firebase.google.com/docs/firestore/manage-data/enable-offline).
