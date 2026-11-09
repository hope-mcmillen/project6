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
   Both used the original production 10-second per-attempt deadline. Returned
   explanations were reviewed and describe only clothes and the occasion.
5. `integration_test/firebase_startup_test.dart`: the real `main.dart` initializes
   Firebase, restores its signed-in account and reaches the welcome screen with
   a working shared closet repository.

The selected default is stable `gemini-3.5-flash-lite` with LOW thinking and
schema-constrained JSON. The larger Flash model timed out, so the lightweight
model was selected using actual live results. A diagnostic run with a longer
timeout was not counted as a normal app pass. Latencies above are observed test
results, not a guarantee for every network or future model response.

### November 5 integration check

The Firebase backend merged in PR #2. The live test photo now belongs to the
Android debug variant, so combining the branch with the sample closet leaves a
single Flutter asset list. The combined branches passed analysis and 66 tests.

An outfit request exceeded the original 10-second deadline. Outfit requests
now ask for one short reason and can wait up to 20 seconds per attempt; tagging
retains its 10-second deadline. After an intermittent service error, the next
authorized emulator run passed both live checks: **8,462 ms** for clothing tags
and **3,310 ms** for two validated outfits. The full phone flow is still pending.

### November 6 Android startup regression

The merged UI launched without `BackendScope`. The startup regression test
reproduced this on `master`. The Friday fix restores `FirebaseBackend` at the
Android entry point and preserves the UI preview on unregistered platforms.
On the review branch, the same test reached the current app with an anonymous
Firebase user and read from the shared closet repository. Static analysis and
all 63 Flutter tests passed locally.

The authorized emulator also verified Firestore owner access, cross-user
denials, and cached closet reads after a separate offline relaunch. The first
Gemini run returned tags in **5,015 ms** and timed out on outfits with the
retry message. A fresh run with the same settings returned tags in **4,224 ms**
and two validated outfits in **2,124 ms**. The feature screens still use demo
data, and a physical Android phone was unavailable for the end-to-end flow.

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

## Android App Check developer setup — November 9

`BackendServices.connect` already activates App Check after Firebase
initialization and before Auth, Firestore and AI are used. The selected provider
comes from the Flutter build mode. Calling `FirebaseBackend` at the app entry
point supplies the shared services. [Flutter App Check setup](https://firebase.google.com/docs/app-check/flutter/default-providers).

| Flutter mode | Provider in this app | Required configuration |
| --- | --- | --- |
| Debug | `AndroidDebugProvider` | Approved credential for that device/install |
| Profile or release | `AndroidPlayIntegrityProvider` | Signing certificate and Play Integrity setup for the distribution channel |

For a new teammate development device:

1. Run `flutter run --debug -d DEVICE_ID` using this project's Android app.
   Inspect the `DebugAppCheckProvider` message in local Logcat to obtain its
   generated debug credential. Treat the raw logs as private.
2. Obtain account-owner approval for the specific device and credential. In
   Firebase project `fitcheck-ai-258e1`, open App Check, select the Android app
   `com.example.project6`, then use its overflow menu's **Manage debug tokens**
   action to register the approved credential.
3. Run the checks below. Their setup forces an App Check token refresh before
   making real AI requests, and the startup check confirms the shared backend.
   Preserve the installation between runs with `--no-uninstall`.

```sh
flutter test integration_test/firebase_ai_test.dart -d DEVICE_ID --no-uninstall
flutter test integration_test/firebase_startup_test.dart -d DEVICE_ID --no-uninstall
```

The existing local emulator is already approved and registered. Other devices
need their own approval. Keep debug credentials, App Check tokens and raw logs
out of GitHub and recordings. A cleared installation can generate a different
credential. [Firebase debug-provider setup](https://firebase.google.com/docs/app-check/flutter/debug-provider).

### Release handoff to Keith and the account owner

`android/app/build.gradle.kts` currently assigns the debug signing configuration
to release builds. Keith must establish the intended release signing identity
and distribution channel. The SHA-256 fingerprint must match the certificate
on the distributed app. A Google Play build uses its app-signing certificate.

The account owner links the same Firebase project in Play Console's App
integrity settings and registers the Android app's signing fingerprint for
Firebase App Check's Play Integrity provider. Its app-recognition, licensing
and device-integrity settings must match the chosen distribution channel.
Firebase's default app-recognition requirement expects publication on Google
Play, while its documented setup for distribution outside Play uses different
verdict requirements. [Play Integrity setup and distribution settings](https://firebase.google.com/docs/app-check/android/play-integrity-provider).

After those settings and signing are ready, verify the actual release on a
physical Android device through token exchange and real AI requests. Release
verification, the full feature flow and other team devices remain pending.
The per-device daily request allowance is scheduled for November 10, with
enforcement/rejection checks on November 11.

November 9 recheck of the existing merged runtime on the approved emulator
completed a forced App Check token refresh, valid clothing tags in 7,498 ms and
two validated outfits in 2,284 ms. The real app entry point restored anonymous
sign-in and exposed the shared repository to the current UI. These observations
cover the debug emulator. Release/provider console configuration and physical
phone acceptance remain pending.

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
