# Firebase setup and verification — November 4, 2026

Project: [FitCheck AI](https://console.firebase.google.com/project/fitcheck-ai-258e1/overview)
(`fitcheck-ai-258e1`). Plan: Spark (no billing enabled).

## Configured

- Android app: `com.example.project6`, app ID
  `1:376143188914:android:b50071b9e266e4163f0aab`.
- Real Android client options in `lib/firebase_options.dart`. These were copied
  from the visible Firebase/Google Cloud configuration because the console
  download stalled. They are not fictitious or FlutterFire CLI-generated output.
  The app initializes Firebase through explicit Dart options and does not need
  the native Google Services Gradle plugin for the services currently used.
- The Firebase-provisioned Android key is restricted to Firebase-related APIs;
  its allowlist includes AI Logic, Firestore and Identity Toolkit, and excludes
  the Gemini Developer API. No Gemini secret is in the repository.
- Anonymous authentication enabled.
- Firestore Standard `(default)` database in `nam5` (United States), created in
  production/locked mode. Owner-only rules matching `firestore.rules` published
  through the console and verified with real Android clients.
- App startup connects Firebase and exposes one shared `BackendScope`, with
  loading and retry UI. Existing feature screens still need their owners to use
  the injected repositories/services.
- App Check SDK initialization uses the Android debug provider in debug builds
  and Play Integrity in release builds. The local Android emulator's debug
  credential is registered with owner approval.
  Release Play Integrity registration is still pending.

## Passed verification

`flutter analyze`: no issues. `flutter test`: all **47** tests pass.
Android integration builds and these live checks pass on the local API 36 emulator:

1. `integration_test/firebase_backend_test.dart`: anonymous sign-in; save and
   server-read a sample item; reload through the repository; a second anonymous
   UID is denied get/list/create/update/delete against the first UID's data.
2. `integration_test/firebase_offline_test.dart` seed phase: save a test item,
   confirm it from the server and persist its identifiers on the device.
3. A separate app launch runs the verify phase: the same anonymous UID is
   restored, Firestore networking is disabled, the test item is read from the
   persistent cache through both the SDK and repository, networking is restored,
   and the test item is removed.

4. `integration_test/firebase_ai_test.dart`: App Check token verification, valid
   clothing tags in **3,479 ms**, and valid closet-based outfits in **5,044 ms**.
   Both use the normal production 10-second per-attempt deadline. Returned
   explanations were reviewed and describe only clothes and the occasion.
5. `integration_test/firebase_startup_test.dart`: the real `main.dart` initializes
   Firebase, restores its signed-in account and reaches the welcome screen with
   a working shared closet repository.

The selected default is stable `gemini-3.5-flash-lite` with LOW thinking and
schema-constrained JSON. The larger Flash model timed out, so the lightweight
model was selected using actual live results. A diagnostic run with a longer
timeout was not counted as a normal app pass. Latencies above are observed test
results, not a guarantee for every network or future model response.

To reproduce live AI checks and the offline restart check:

```sh
flutter test integration_test/firebase_ai_test.dart -d emulator-5554 --no-uninstall
flutter test integration_test/firebase_offline_test.dart -d emulator-5554 --no-uninstall
flutter test integration_test/firebase_offline_test.dart -d emulator-5554 --no-uninstall --dart-define=FIREBASE_OFFLINE_PHASE=verify
```

Flutter otherwise uninstalls integration test apps after a run, clearing the
anonymous account/cache and development credential. Preserve the app between
runs. These are emulator checks, not a completed real-phone feature flow.
Disposable sample metadata/anonymous accounts from rehearsals may remain in this
development project.

## Approved development access

The account owner accepted the Gemini agreement and enabled the APIs. Firebase
AI Logic is active with Basic App Check enforcement. The console confirms both
the approved local emulator debug credential and Kameron's Firebase Viewer role.
No development credential or personal teammate email is committed to GitHub.

## Remaining work

- Configure release Play Integrity and authorize other team development devices
  as needed. The current emulator is already authorized. Keep debug tokens out
  of GitHub and public recordings; do not disable App Check enforcement.
- For a sideloaded Friday demo, use a debug APK and authorize that device's debug
  token. Release builds select Play Integrity and need its console/signing setup
  before AI calls will work; do not treat the debug emulator check as release proof.
- Obtain Hope and Keith's Google-account emails and approval of their actual roles.
  Kameron's read-only Firebase Viewer access is granted and verified.
- Teammates must connect the feature screens to the shared services and verify
  the complete add-photo → tags → Firestore → outfit flow on a real Android phone.
- The per-device daily AI allowance remains scheduled in M3-08.
- Only Android is registered. Register other platforms before enabling them.

Model references: [supported models](https://firebase.google.com/docs/ai-logic/models)
and [thinking configuration](https://firebase.google.com/docs/ai-logic/thinking).
