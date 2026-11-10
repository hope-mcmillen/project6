# FitCheck AI Demo Script

Draft for **M1-07**, by Kameron. Every member reviews it and signs off at the
bottom before anyone records (M1-10, M2-09, M3-11, M4-10).

**Target length: 8 minutes.** This is a placeholder. Check it against the
course's required length and adjust the timings below before recording.

## How we record

- Record each segment on a real Android phone with the team's debug build,
  using the screen recorder plus a voice-over. Keith (Member 4) combines the
  recordings.
- Photograph **clothing only**, laid flat or on a hanger. No people in any photo
  sent to the AI, because the Gemini free tier must not receive them.
- Keep these off screen: App Check debug tokens, API keys, the Firebase project
  settings page, Google account names and emails, and phone notifications.
  Turn on Do Not Disturb first.
- Use the sample closet plus the one item Kameron adds on camera. Do not show
  anyone's real closet.
- Each segment starts and ends on a screen the next speaker can pick up from,
  so the cuts read as one continuous flow.

## Running order

| # | Segment | Speaker | Time | Covers |
| --- | --- | --- | --- | --- |
| 1 | Intro: the problem and the team | Kameron | 0:30 | — |
| 2 | First launch and privacy notice | Keith | 0:40 | FR-11, privacy |
| 3 | Closet: sample closet, add an item, AI tags, browse | Kameron | 1:50 | FR-1–FR-4, FR-10 |
| 4 | Server component: the item in Firestore | Marcus | 1:20 | FR-11, server component |
| 5 | Outfits: occasion, weather, results, lookbook | Hope | 1:50 | FR-5–FR-8 |
| 6 | Fit Check, offline, and Settings | Keith | 1:30 | F-1, FR-9 |
| 7 | Wrap-up | Hope | 0:20 | — |
| | **Total** | | **8:00** | |

## 1. Intro (Kameron, 0:30)

**On screen:** the app's Today tab.

**Say:**
> Most of us own plenty of clothes and still feel like we have nothing to wear.
> FitCheck AI builds outfits from the clothes you already own. I'm Kameron, and
> I built the closet. Hope built outfits, Marcus built the database and AI, and
> Keith built the platform and Fit Check.

## 2. First launch and privacy notice (Keith, 0:40)

**Before recording:** clear the app's data so it opens as a new install.

**Show:**
1. Open the app. The welcome screen appears.
2. Scroll the privacy notice, pausing on what leaves the phone: clothing photos
   go to the AI for tagging, tags go to Firestore, and photos stay on the phone.
3. Confirm the 18+ check and continue.
4. Force-close and reopen the app to show the welcome screen does not return.

**Say:** the app signs in anonymously, so there is no account to create, and
each user can only read their own data.

**End on:** the Wardrobe tab, empty.

## 3. Closet (Kameron, 1:50)

**Before recording:** have one clothing item ready to photograph, such as a
plain shirt laid flat on a bed. Make sure AI tagging works on this phone (its
App Check debug token is registered).

**Show:**
1. On the empty Wardrobe tab, tap **Load sample closet**. About 18 pieces
   appear at once with no AI calls.
   > If you just want to try the app, one tap gives you a full closet.
2. Go to **Add item** and tap **Take photo**. Photograph the shirt.
3. Tag review shows "Suggesting tags..." and then fills in category, color,
   pattern, formality, and season from the AI.
   > The photo is resized and sent to Gemini, which sends back tags as
   > structured JSON. Every tag is still editable.
4. Change one tag, such as the color, and tap **Save to closet**. The app jumps
   to the Wardrobe with the new shirt first.
5. Tap the **Tops** chip, then set **Color** to the shirt's color. Set them back
   to All and Any.
6. Open the shirt, tap **Edit tags**, change the season, and save. The new tag
   shows right away.
7. Point out **Clear sample closet**, but do not tap it; outfits need the sample
   pieces.

**Say:** the closet works offline. Saves and deletes show right away, and
Firestore catches up when the phone reconnects.

**End on:** the shirt's details screen. Marcus picks up this item.

## 4. Server component: Firestore (Marcus, 1:20)

**Before recording:** open the Firebase console on a computer, on the Firestore
Data page, before you start recording. Do not show the project settings, API
keys, or the account menu.

**Show:**
1. Open `users`, then this phone's user ID, then `items`.
2. Open the shirt Kameron just added. Its fields are text only: the tags,
   `createdAt`, `isSample`, and `photoPath`. There is no image.
   > This database is our server component. The app stores the tags here. The
   > photo itself never leaves the phone except to be tagged.
3. Point out that the shirt's season matches Kameron's edit.
4. On the phone, force-close and reopen the app. The shirt reloads from
   Firestore.
5. Mention the security rules: a user can read and write only their own
   `users/{uid}` documents.

**End on:** the Wardrobe tab on the phone.

## 5. Outfits (Hope, 1:50)

**Show:**
1. Open the outfit request. Live weather shows the temperature and rain chance.
   If location is off, enter a city.
2. Pick an occasion such as **Work** and add a short note.
3. Tap **Get outfits**. Up to 3 outfits appear, each with photos of real closet
   pieces and a one- or two-sentence reason.
   > The AI only gets the tags as text, not the photos, and every item it
   > suggests is checked against the closet.
4. Save one outfit, then open the lookbook to show it there.
5. If swap or ratings are built (M2-06, M2-07), swap one piece in an outfit.

**End on:** the lookbook.

## 6. Fit Check, offline, and Settings (Keith, 1:30)

**Before recording:** lay an outfit flat or hang it up, with no person in the
frame (unless the team turned on billing; see M3-09).

**Show:**
1. Open Fit Check, photograph the outfit, and show the verdict and up to 3
   suggestions.
   > Feedback is only ever about the clothes, never the person.
2. Turn on airplane mode. The offline banner says the closet still works and AI
   needs a connection. Browse the Wardrobe to prove it, then turn airplane mode
   off and watch the banner go.
3. Open Settings. Show **Delete all my data** and its confirmation, then tap
   Cancel.
4. Optionally show a GitHub Actions run with the APK artifact as proof of the
   automated build.

## 7. Wrap-up (Hope, 0:20)

> FitCheck AI turns the clothes you already own into outfits, with AI tags,
> outfit suggestions, and Fit Check. Thanks for watching.

## What must be built before recording

As of November 10, 2026. Update this table as tasks merge.

| Segment | Needs | Current state |
| --- | --- | --- |
| 2. First launch | M4-11, M4-05 | A welcome screen with placeholder wording exists, but the app never shows it, and nothing saves the 18+ answer yet. |
| 3. Closet | M1-01 to M1-06 | Built; M1-06 is on branch `m1-06-closet-editing`. The phone check (M1-05) is still to do. |
| 4. Firestore | M3-03, M3-05, M1-05 | Live checks pass on the emulator, per `FIREBASE_STATUS.md`. Needs a run on a real phone. |
| 5. Outfits | M2-03, M2-04, M2-05 | The Outfits tab is still a demo chat with sample replies. The outfit screens are not connected to the app yet. |
| 6. Fit Check and Settings | M3-09, M4-07, M4-14, M4-15 | Fit Check and Settings are placeholder screens with no way to reach them from the app's tabs. |

**If a feature is not ready on recording day,** leave it out and give its time
to the other segments. Never show sample data or a demo reply as if it came from
the AI.

## Sign-off

Done when all 4 members have reviewed the script and each has a segment.

| Member | Segments | Reviewed |
| --- | --- | --- |
| Kameron Arceneaux | 1, 3 | [ ] |
| Hope McMillen | 5, 7 | [ ] |
| Marcus Reese | 4 | [ ] |
| Keith Mayle | 2, 6, final edit | [ ] |
