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
  and Play Integrity in release builds. Console authorization remains pending.

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

To reproduce the restart check, preserve the test app between invocations:

```sh
flutter test integration_test/firebase_offline_test.dart -d emulator-5554 --no-uninstall
flutter test integration_test/firebase_offline_test.dart -d emulator-5554 --no-uninstall --dart-define=FIREBASE_OFFLINE_PHASE=verify
```

Flutter otherwise uninstalls integration test apps after a run, which clears the
anonymous account/cache. The first rehearsal used that default and failed the
fixture check; the corrected two-launch check above passes. These are emulator
checks, not a claim of a completed real-phone feature flow. Disposable sample
metadata/anonymous accounts from rehearsals may remain in this development project.

## Still pending

- The account owner must review the **separate Gemini API Additional Terms** and
  click **Enable APIs** in the open Firebase AI Logic setup panel. These terms
  are distinct from the Firebase project terms already accepted.
- AI Logic setup now enforces App Check automatically. Authorize the team's
  development builds and configure Play Integrity before expecting verified AI
  calls. Debug tokens grant access and need explicit owner approval; keep them
  out of GitHub and public recordings. Do not disable App Check enforcement.
- Live clothing tagging, live outfit generation, and latency verification.
- Kameron, Hope and Keith's Google-account emails, plus approval of the actual
  recipient/role list, before granting project access.
- Teammates' feature integration and the full flow on a real Android phone.
- The per-device daily AI allowance is still planned in M3-08.

Automatic approval review rejected optional extra web-app registration as outside
the explicitly authorized Android setup. It was cancelled; no web app was
created. Web/Apple Firebase initialization deliberately remains unsupported.
