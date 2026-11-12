# FitCheck AI Tasks

The Friday MVP is due **November 6, 2026**. It needs one working flow: add a
clothing photo, get AI tags, save to Firestore, and get an outfit.

| Priority | Meaning |
| --- | --- |
| **P0** | Needed for the Friday MVP |
| **P1** | Next, after the MVP: remaining core work, Fit Check, and the demo video |
| **P2** | Only if time allows |

Work through each list from the top, and track progress on the
[Trello board](https://trello.com/b/VkUZV9ex/4335-project6). Requirement IDs such
as FR-1 and F-1 are defined in the requirements doc.

**Friday is for bug fixes only.** Everyone stops adding features after Thursday.

## Member 1: Closet (Kameron Arceneaux)

### P0: Friday MVP

Phone checks for M1-01 to M1-05 happen together in M1-05, because the
earlier tasks only ran against fakes.

- [ ] **M1-01: Add items from the camera or gallery**
  - **Due:** Wed, Nov 4
  - **Covers:** FR-1
  - **Needs first:** M4-01
  - **Status:** Code merged in PR #1. Waiting on the phone check in M1-05.
  - **What to do:** Replace the placeholder buttons with `image_picker` so a user can take or choose a clothing photo. Save a copy on the phone with `path_provider`, then pass its file path to tag review. The gallery must still work if camera access is denied.
  - **Where:** `lib/features/closet/add_item_screen.dart`
  - **Done when:** A real photo appears on tag review, its file is still on the phone after a restart, and denying camera access leaves the gallery usable.
- [ ] **M1-02: Make tag review editable, with AI tags when available**
  - **Due:** Wed, Nov 4
  - **Covers:** FR-2, FR-3
  - **Needs first:** M3-02
  - **Status:** Code merged in PR #5 and moved onto Member 3's shared services in M1-05. Waiting on the phone check in M1-05.
  - **What to do:** When the screen opens, read the photo, call `AiService.tagClothing`, show a loading state, and fill in category, color, pattern, formality, and season. Let the user change any field, then save the item. If the AI call fails, show its message and empty fields for manual entry.
  - **Where:** `lib/features/closet/tag_review_screen.dart`
  - **Done when:** Suggested tags appear, every tag can be edited, the saved item keeps the user's values, and a failed AI call opens manual entry.
- [ ] **M1-03: Build the real closet screen with browse and delete**
  - **Due:** Wed, Nov 4
  - **Covers:** FR-4
  - **Needs first:** M3-02
  - **Status:** Code merged in PR #5. Category filters were added early in M1-05 so the new Wardrobe tab kept the filters from Member 2's design. Waiting on the phone check in M1-05.
  - **What to do:** Show items from the closet repository with their saved photos, newest first. Tapping an item opens its details. Deleting it removes the Firestore record, and the photo file once Firestore confirms the delete.
  - **Where:** `lib/features/closet/closet_screen.dart`, `lib/features/closet/item_detail_screen.dart`
  - **Done when:** New items appear in the grid with their photos and tags, and a deleted item and its photo file are gone.
- [ ] **M1-04: Add a sample closet that loads with one tap**
  - **Due:** Wed, Nov 4
  - **Covers:** FR-10
  - **Needs first:** M3-02
  - **Status:** Code merged in PR #5 with 18 drawn clothing images the team made. Real clothing photos can replace them under the same file names. Waiting on the phone check in M1-05.
  - **What to do:** Bundle 15-20 clothing images with tags already written, including tops, bottoms, and shoes. Show a load button when the closet is empty. Loading copies the images onto the phone and saves each item with `isSample: true`. Member 4 can reuse `SampleClosetLoader` for the Settings option.
  - **Where:** `assets/sample_closet/`, `lib/features/closet/sample_closet.dart`
  - **Done when:** One tap on an empty closet fills it with enough items for the outfit flow, with no AI calls.
- [ ] **M1-05: Connect the closet to Firestore and live AI tagging**
  - **Due:** Thu, Nov 5
  - **Covers:** FR-2, FR-11
  - **Needs first:** M3-04, M3-05 (both merged in PR #2)
  - **Status:** Code on branch `m1-05-firebase-closet`. The closet screens use the shared `BackendScope` services, and the Wardrobe and Add item tabs show them. The phone check is still to do.
  - **What to do:** Use Member 3's `ClothingItem`, `ClosetRepository`, and `AiService` from `BackendScope`, and store canonical lowercase categories. Do not wait for Firestore to confirm a save or delete, because offline writes wait until the phone reconnects; show a message if a write fails later. Then install a debug build on a real Android phone. Ask Member 3 to register that phone's App Check debug token in the Firebase console first, or AI tagging fails and only manual entry works. Test with clothing-only photos, because the Gemini free tier must not receive photos of people.
  - **Where:** `lib/features/closet/`, `lib/app/app_shell.dart` (Wardrobe and Add item tabs), `lib/main.dart`
  - **Done when:** On a real phone, a new clothing photo gets real AI tags, the item shows under `users/{uid}/items` in the Firebase console (your Viewer role is enough), it reloads after a restart, and loading the sample closet and deleting an item both reach Firestore.

### P1: Next

- [ ] **M1-06: Finish closet editing, clearing, and failure states**
  - **Covers:** FR-3, FR-4, FR-9, FR-10
  - **Needs first:** M1-05, M4-04
  - **What to do:** Category filters are done. Still to do: edit saved tags with `ClothingItem.copyWith` and `saveItem`; add a "Clear sample closet" option that deletes every `isSample` item and its photo; delete the copied photo when the user backs out of tag review without saving; and add color and season filters. Use Member 4's shared widgets for errors and retries, and add tests under `test/features/closet/`.
  - **Where:** `lib/features/closet/`, `test/features/closet/`
  - **Done when:** Filters work offline, saved tags can be changed, the sample closet clears with one tap, an abandoned photo is not left on the phone, and closet failures show a message instead of crashing.
- [ ] **M1-07: Write the demo script**
  - **Covers:** Demo video
  - **Needs first:** None
  - **Status:** Draft on branch `m1-07-demo-script` in `docs/demo-script.md`. The 8-minute target is a placeholder until the course's required length is confirmed. Waiting on review from all 4 members.
  - **What to do:** Write the demo video script: who speaks, what each member shows, and the order of the main flow and Fit Check. Include the proof the course asks for, such as an item appearing in the Firebase console as the server component, and check it against any required length.
  - **Where:** `docs/demo-script.md`
  - **Done when:** All 4 members have reviewed the script, and each has a segment.
- [ ] **M1-09: Run an accessibility pass on closet screens**
  - **Covers:** Accessibility quality requirement
  - **Needs first:** M1-06
  - **What to do:** Add screen reader labels to photos and icon buttons, make sure colors also appear as text, and check every closet screen at a large text size.
  - **Where:** `lib/features/closet/`
  - **Done when:** A screen reader can describe each closet item and control, and no closet text is cut off at a large text size.
- [ ] **M1-10: Record the closet demo segment**
  - **Covers:** Demo video
  - **Needs first:** M1-07, M1-05
  - **What to do:** Record your section of the script on a real phone: adding an item, reviewing AI tags, and browsing the closet. Use clothing-only photos, and keep App Check debug tokens and account details off screen.
  - **Where:** Shared with Member 4 for editing
  - **Done when:** Member 4 has the recording, and it follows the script.

### P2: If time allows

- [ ] **M1-08: Add laundry status**
  - **Covers:** Could-have feature
  - **Needs first:** M1-05
  - **What to do:** The shared model already has `inLaundry`, and outfit requests already skip those items. Add a toggle on the item details screen that saves `item.copyWith(inLaundry: ...)`, and show the status on the closet card.
  - **Where:** `lib/features/closet/`
  - **Done when:** An item marked as in the laundry is visibly marked and is not suggested in outfits.

## Member 2: Outfits (Hope McMillen)

### P0: Friday MVP

- [ ] **M2-01: Build the occasion screen and closet check with fakes**
  - **Due:** Wed, Nov 4
  - **Covers:** FR-5, FR-6
  - **Needs first:** M3-02
  - **What to do:** Make the occasion chips and optional note work, keeping the sample weather for now. Before requesting outfits, read the closet through the fake repository. It needs shoes and either a dress or a top and bottom; if something is missing, name it and make no AI call.
  - **Where:** `lib/features/outfits/outfit_request_screen.dart`
  - **Done when:** Occasion choices work, the note is kept, an incomplete closet names what is missing, and a complete closet continues to results.
- [ ] **M2-02: Build the outfit results screen with fakes**
  - **Due:** Wed, Nov 4
  - **Covers:** FR-5
  - **Needs first:** M3-02
  - **What to do:** Call the fake `AiService` with the request, show a loading state, and display up to 3 outfits. Each outfit shows its item photos and a 1-2 sentence reason. Leave the save, swap, rating, and wear buttons as Not built messages.
  - **Where:** `lib/features/outfits/outfit_results_screen.dart`
  - **Done when:** Fake outfits show real closet items and their reasons, and the screen handles 1, 2, or 3 outfits.
- [ ] **M2-05: Connect outfit screens to Firestore and live AI**
  - **Due:** Thu, Nov 5
  - **Covers:** FR-5, FR-9, FR-11
  - **Needs first:** M3-05, M3-06, M4-04
  - **What to do:** Swap the fakes for Member 3's real closet repository and `AiService`. Show a retry message with Member 4's shared widget if a request fails, and add a basic test of the request-to-results flow. Fuller failure handling and tests come with M2-04.
  - **Where:** `lib/features/outfits/`, `test/features/outfits/`
  - **Done when:** The Friday flow runs on live data: real closet items produce real outfits, and a failed request shows a retry message instead of crashing.

### P1: Next

- [ ] **M2-03: Show live weather with a city fallback**
  - **Covers:** FR-7
  - **Needs first:** M3-07
  - **What to do:** Replace the sample weather card with temperature and rain chance from Member 3's weather service, using `geolocator`. If location is denied, let the user enter a city. Include the weather in outfit requests. Start this first if your MVP tasks finish early.
  - **Where:** `lib/features/outfits/outfit_request_screen.dart`
  - **Done when:** Real weather appears, denying location still allows a city, and the request sends the weather shown.
- [ ] **M2-04: Build outfit saving and the lookbook**
  - **Covers:** FR-8, FR-9
  - **Needs first:** M3-05
  - **What to do:** Make the Save button store an outfit, and replace the sample lookbook with saved outfits. Add a way to remove one. If a clothing item is deleted, clearly mark the outfits that used it. Add failure states and tests for this flow.
  - **Where:** `lib/features/outfits/lookbook_screen.dart`, `lib/features/outfits/outfit_results_screen.dart`, `test/features/outfits/`
  - **Done when:** Saved outfits survive a restart, can be removed, and show clearly when one of their items was deleted.
- [ ] **M2-08: Run an accessibility pass on outfit screens**
  - **Covers:** Accessibility quality requirement
  - **Needs first:** M2-04
  - **What to do:** Add screen reader labels to outfit photos and icon buttons, describe weather and colors in text, and check each outfit screen at a large text size.
  - **Where:** `lib/features/outfits/`
  - **Done when:** A screen reader can describe each outfit and control, and no outfit text is cut off at a large text size.
- [ ] **M2-09: Record the outfit demo segment**
  - **Covers:** Demo video
  - **Needs first:** M1-07
  - **What to do:** Record your section of the script on a real phone: choosing an occasion, getting outfits, and saving one to the lookbook.
  - **Where:** Shared with Member 4 for editing
  - **Done when:** Member 4 has the recording, and it follows the script.

### P2: If time allows

- [ ] **M2-06: Build swap one piece**
  - **Covers:** F-2
  - **Needs first:** M3-10
  - **What to do:** Connect the swap button so the user picks one item in an outfit and requests a replacement. Only that piece changes, and the new one comes from the closet.
  - **Where:** `lib/features/outfits/outfit_results_screen.dart`
  - **Done when:** Swapping changes only the chosen item, and its replacement comes from the user's closet.
- [ ] **M2-07: Add ratings and the wear log**
  - **Covers:** F-3, F-4
  - **Needs first:** M3-10
  - **What to do:** Connect the thumbs buttons, with a reason such as "too formal", and the Wear today button. Store both in Firestore so later requests can use recent ratings and avoid items worn in the last 3 days.
  - **Where:** `lib/features/outfits/outfit_results_screen.dart`
  - **Done when:** Ratings and worn dates are saved, ratings visibly change suggestions in a test, and items worn in the last 3 days are avoided unless the closet is too small.

## Member 3: Database and AI (Marcus Reese)

### P0: Friday MVP

- [ ] **M3-01: Create the Firebase project and enable its services**
  - **Due:** Wed, Nov 4, midday
  - **Covers:** FR-11
  - **Needs first:** None
  - **What to do:** Create the project and add all teammates. Enable Firestore, Anonymous sign-in, and AI Logic with the Gemini Developer API. Run `flutterfire configure` and commit the generated options file so CI can build. App Check is set up later in M3-08.
  - **Where:** Firebase console, `lib/firebase_options.dart`
  - **Done when:** All 4 members can open the project, and the app starts with Firebase initialized.
- [ ] **M3-02: Define the models, repositories, AiService, and fakes**
  - **Due:** Wed, Nov 4, midday
  - **Covers:** FR-2, FR-5, FR-11
  - **Needs first:** M4-01
  - **What to do:** Define the `ClothingItem`, `Outfit`, `WearLog`, and `StyleProfile` models, the Firestore collections, repository interfaces, and `AiService`. Add fake versions with sample data. Members 1 and 2 are waiting on this, so merge the interfaces and fakes first.
  - **Where:** `lib/core/data/`, `lib/core/ai/`
  - **Done when:** Members 1 and 2 can build their screens against the merged fakes without Firebase.
- [ ] **M3-03: Write security rules that limit each user to their own data**
  - **Due:** Wed, Nov 4
  - **Covers:** FR-11
  - **Needs first:** M3-01
  - **What to do:** Write rules so a signed-in user can read and write only documents under `users/{uid}`, and deploy them. Do not leave the database open in test mode.
  - **Where:** `firestore.rules`
  - **Done when:** A user can read their own data, and an attempt to read another user's data is refused.
- [ ] **M3-04: Build AI tagging and confirm it returns valid JSON**
  - **Due:** Wed, Nov 4
  - **Covers:** FR-2
  - **Needs first:** M3-01, M3-02, M4-12
  - **What to do:** Implement photo tagging with `firebase_ai`. Resize each photo with M4-12's helper, send one clothing photo, and require JSON with category, color, pattern, formality, and season. Reject invalid replies and retry once. Do this early, because every AI feature depends on it.
  - **Where:** `lib/core/ai/`
  - **Done when:** A clothing-only photo returns valid tags within about 10 seconds, and an invalid reply produces a clear error.
- [ ] **M3-05: Build Firestore repositories with anonymous sign-in**
  - **Due:** Wed, Nov 4
  - **Covers:** FR-11
  - **Needs first:** M3-01, M3-02
  - **What to do:** Provide the anonymous sign-in method that M4-11 calls at startup, and implement the closet repository first so the MVP can save items under `users/{uid}/items`. Store only text and each photo's path on the phone, never the photo. Add outfit and profile repositories in time for the tasks that need them.
  - **Where:** `lib/core/data/`
  - **Done when:** Items save to Firestore under the signed-in user, reload after a restart, and the closet still reads while offline.
- [ ] **M3-06: Build outfit generation with item ID validation**
  - **Due:** Thu, Nov 5
  - **Covers:** FR-5
  - **Needs first:** M3-02, M3-04
  - **What to do:** Send closet tags as text, plus the occasion, note, and weather, and require JSON with up to 3 outfits and reasons. Discard any outfit that uses an item ID not in the closet. Comment on clothing only, never on the person. If this is shaky by Thursday morning, simplify the prompt instead of adding features.
  - **Where:** `lib/core/ai/`
  - **Done when:** A real closet returns up to 3 valid outfits, and a test shows an unknown item ID is rejected.

### P1: Next

- [ ] **M3-07: Build the Open-Meteo weather service**
  - **Covers:** FR-7
  - **Needs first:** M3-02
  - **What to do:** Create a service that returns temperature and rain chance for a rounded location or a city, using Open-Meteo. Review and meet its CC-BY 4.0 licence terms, including any credit it requires. Include a fake for tests.
  - **Where:** `lib/core/weather/`
  - **Done when:** Member 2 can get real weather for a location or a city through one service, and failures return a clear error.
- [ ] **M3-08: Add App Check and the daily AI request limit**
  - **Covers:** Security and cost quality requirements
  - **Needs first:** M3-04
  - **What to do:** Turn on App Check for AI calls, using debug tokens for the team's development builds and a production provider for release builds. Add a per-device daily limit on AI requests with a clear message when it is reached. Set a spend cap if billing is enabled.
  - **Where:** `lib/core/ai/`, Firebase console
  - **Done when:** An unverified client cannot use AI Logic, team builds still work, and going over the limit shows a clear message.
- [ ] **M3-09: Build Fit Check AI feedback**
  - **Covers:** F-1
  - **Needs first:** M3-04
  - **What to do:** Send one outfit photo with the occasion and weather, and require a verdict plus up to 3 specific suggestions as JSON. Feedback covers clothing only, never body shape, weight, or skin. Photos of people need the paid Gemini tier; without billing, accept only outfits with no person in the photo.
  - **Where:** `lib/core/ai/`
  - **Done when:** Member 4 can get valid feedback through `AiService`, the wording stays on the clothes, and the team's billing decision is applied.
- [ ] **M3-11: Record the demo segment showing data in Firestore**
  - **Covers:** Server component, demo video
  - **Needs first:** M1-07, M1-05
  - **What to do:** Record your section of the script: a saved item appears in the Firebase console, then reloads in the app. Mention that this database connection is the project's server component. Use sample data, and do not show keys or personal account details.
  - **Where:** Shared with Member 4 for editing
  - **Done when:** Member 4 has a recording that clearly shows data moving between the app and Firestore.

### P2: If time allows

- [ ] **M3-10: Add swaps, ratings, and style profile to outfit prompts**
  - **Covers:** F-2, F-3, F-4, F-5
  - **Needs first:** M3-06
  - **What to do:** Extend outfit requests so one piece can be swapped while the rest stay locked. Include recent ratings, items worn in the last 3 days, and style profile answers.
  - **Where:** `lib/core/ai/`
  - **Done when:** A swap changes one validated item, and tests show ratings, wear history, and profile answers reach the request.

## Member 4: Platform and Fit Check (Keith Mayle)

### P0: Friday MVP

- [ ] **M4-01: Merge the template, then add packages, permissions, and code owners**
  - **Due:** Wed, Nov 4, midday
  - **Covers:** Git repo
  - **Needs first:** None
  - **What to do:** Merge the placeholder template. Add known packages: `firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_ai`, `firebase_app_check`, `image_picker`, `path_provider`, `geolocator`, and `http`. Add camera, photo, location, and network permissions and any Android settings Firebase needs. Add `.github/CODEOWNERS` with real usernames. Everyone is waiting on this.
  - **Where:** `pubspec.yaml`, `android/`, `ios/`, `.github/CODEOWNERS`
  - **Done when:** `master` has the template, the app builds, the checks pass, and every member has pulled it.
- [ ] **M4-02: Extend CI with a format check, analysis, and an APK build**
  - **Due:** Wed, Nov 4
  - **Covers:** Automated build
  - **Needs first:** M4-01, M3-01
  - **What to do:** Add `dart format --set-exit-if-changed`, `flutter analyze`, and `flutter build apk` to the existing workflow, which stops after tests today. Upload the APK as a build artifact.
  - **Where:** `.github/workflows/main.yml`
  - **Done when:** A pull request runs all checks, and the run offers a downloadable APK.
- [ ] **M4-03: Finish the Trello board setup**
  - **Due:** Wed, Nov 4
  - **Covers:** Task list
  - **Needs first:** None
  - **What to do:** The cards, labels, and owners are already on the board. Link the board in the README, and agree the team habit: move a card to In Progress when you start, and to Done when its pull request merges.
  - **Where:** Trello board, `README.md`
  - **Done when:** The README links to the board, and all members are using it.
- [ ] **M4-04: Build shared error and retry widgets**
  - **Due:** Wed, Nov 4
  - **Covers:** FR-9
  - **Needs first:** M4-01
  - **What to do:** Create small shared widgets for loading, an error message with a Retry button, and being offline. Keep them simple, and tell the team as soon as they merge because Members 1 and 2 will use them.
  - **Where:** `lib/core/widgets/`
  - **Done when:** Members 1 and 2 can show loading and retry states with one widget each, and the widgets have a test.
- [ ] **M4-11: Build app startup and the first-launch flow**
  - **Due:** Wed, Nov 4
  - **Covers:** FR-11, privacy quality requirement
  - **Needs first:** M3-01, M4-01
  - **What to do:** Write the startup code: initialize Firebase, call Member 3's anonymous sign-in, and show loading and retry screens. Save the 18+ confirmation with `shared_preferences` so the welcome screen appears only once. Commit tests for first launch, repeat launch, and a failed startup.
  - **Where:** `lib/main.dart`, `lib/app/`, `test/app/`
  - **Done when:** First launch shows the welcome screen, later launches open the closet, and a startup failure shows a retry option instead of crashing.
- [ ] **M4-12: Build the photo resize helper with tests**
  - **Due:** Wed, Nov 4
  - **Covers:** FR-2, performance quality requirement
  - **Needs first:** M4-01
  - **What to do:** Write a shared helper that resizes a photo to 1024 px on the long edge, keeps its proportions, and returns JPEG bytes for AI requests. Run the work off the main thread so the screen does not freeze. Commit unit tests using small sample images.
  - **Where:** `lib/core/images/`, `test/core/images/`
  - **Done when:** Member 3 can call one method from AI tagging, large photos come back at 1024 px, smaller photos are not enlarged, and the tests pass in CI.
- [ ] **M4-06: Run the full flow on a real Android phone**
  - **Due:** Thu, Nov 5, night
  - **Covers:** MVP check
  - **Needs first:** M1-05, M2-05
  - **What to do:** Install a build on a real Android phone and run the Friday flow: add a clothing photo, review AI tags, save to Firestore, and get an outfit. Report any problems to their owners that night. On Friday, build the final APK from `master`.
  - **Where:** Real Android phone, CI build
  - **Done when:** The full flow works on a real phone by Thursday night, and the final APK is ready on Friday.
- [ ] **M4-13: Write an automated test of the Friday flow**
  - **Due:** Thu, Nov 5
  - **Covers:** MVP check, automated build
  - **Needs first:** M1-02, M1-03, M2-02
  - **What to do:** Write a widget test that uses the fakes to add an item, review tags, save it, request an outfit, and see the results. Add it to the CI run so a merge that breaks the main flow fails.
  - **Where:** `test/app/`, `.github/workflows/main.yml`
  - **Done when:** The test passes on `master`, runs in CI, and fails when any step of the flow is broken.

### P1: Next

- [ ] **M4-05: Add the final privacy notice and data deletion**
  - **Covers:** Privacy quality requirement
  - **Needs first:** M3-05, M4-11
  - **What to do:** Replace the placeholder notice with final wording about what leaves the phone. Connect Delete all my data to remove the user's Firestore data and saved photos, and clear the saved age confirmation. Finish this before anyone outside the team uses the app.
  - **Where:** `lib/app/welcome_screen.dart`, `lib/features/settings/`
  - **Done when:** A new user sees the final notice, and deletion removes their Firestore data and local photos.
- [ ] **M4-07: Build Fit Check screens and apply the photo rule**
  - **Covers:** F-1
  - **Needs first:** M3-09
  - **What to do:** Connect the camera and show the real verdict and suggestions, with loading and retry states. Discard the photo unless the user saves it. Without billing, tell users to photograph outfits with no person in the frame.
  - **Where:** `lib/features/fit_check/`
  - **Done when:** A photo returns real feedback, unsaved photos are discarded, and the screen follows the team's billing decision.
- [ ] **M4-09: Run an accessibility pass on Fit Check and settings screens**
  - **Covers:** Accessibility quality requirement
  - **Needs first:** M4-05, M4-07
  - **What to do:** Add screen reader labels to photos and icon buttons, and check the welcome, Fit Check, and settings screens at a large text size.
  - **Where:** `lib/app/`, `lib/features/fit_check/`, `lib/features/settings/`
  - **Done when:** A screen reader can describe each control, and no text on these screens is cut off at a large text size.
- [ ] **M4-10: Edit and upload the demo video**
  - **Covers:** Demo video
  - **Needs first:** M1-10, M2-09, M3-11
  - **What to do:** Record your own Fit Check and platform segment, combine it with the other recordings, and check it against any required length. Upload the video and add its link to the README.
  - **Where:** Video host, `README.md`
  - **Done when:** The README links to a video that plays, and it includes all 4 members' segments.
- [ ] **M4-14: Connect the Settings actions**
  - **Covers:** FR-10, F-5
  - **Needs first:** M1-04
  - **What to do:** Replace the Not built messages in Settings: connect Load sample closet to Member 1's code, and show a confirmation before Delete all my data. Commit widget tests for both actions.
  - **Where:** `lib/features/settings/settings_screen.dart`, `test/features/settings/`
  - **Done when:** Load sample closet works from Settings, deletion asks first, and no Settings option shows a Not built message unless its feature is still planned.
- [ ] **M4-15: Add an offline banner to the app shell**
  - **Covers:** FR-9
  - **Needs first:** M4-04
  - **What to do:** Use `connectivity_plus` to detect when the phone is offline, and show a banner across every tab. It should say the closet still works and AI features need a connection. Commit widget tests for going offline and coming back.
  - **Where:** `lib/app/app_shell.dart`, `test/app/`
  - **Done when:** The banner appears within a few seconds of losing connection and disappears when the connection returns.

### P2: If time allows

- [ ] **M4-08: Build the style profile**
  - **Covers:** F-5
  - **Needs first:** M3-05, M3-10
  - **What to do:** Save the 3 skippable answers on style, colors to avoid, and regular occasions, and let users edit them in Settings.
  - **Where:** `lib/features/settings/style_profile_screen.dart`
  - **Done when:** Answers can be skipped, saved, and edited, and Member 3's outfit requests include them.
