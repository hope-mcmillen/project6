# Marcus: daily delivery plan

Owner: Marcus Reese / MarcusReese1 (Member 3). Time zone: America/Chicago.
Friday MVP: November 6, 2026. Final Member 3 handoff: November 17, 2026.
Source: [team tasks](../TASKS.md) and [Trello](https://trello.com/b/VkUZV9ex/4335-project6).

## Current work, November 4

Code prepared for M3-02 through M3-06: shared models and interfaces, deterministic
fakes, user-scoped Firestore implementations, owner-only rules, structured AI
tagging, bounded retries, and validated outfit generation. See BACKEND_HANDOFF.md.
This is not a claim of live deployment or end-to-end completion.

Firebase project `fitcheck-ai-258e1` now exists on Spark. Android registration,
Anonymous sign-in, Firestore (`nam5`) and owner-only rule deployment are complete.
Live Android startup, storage/reload, cross-user access, offline restart,
clothing tagging and outfit checks pass. The Gemini provider is enabled. The local emulator is authorized for App Check, and Kameron has the approved
Firebase Viewer role. Release App Check registration and Hope/Keith's access
remain pending. Their Google-account emails are still needed. See FIREBASE_STATUS.md for current evidence.
App Check initialization was brought forward because new AI Logic setup enforces
it immediately. Future daily runs should verify existing work before duplicating it.

## Daily work

Work starts at 10:00 AM Central each day, November 5–17 inclusive. Inspect current
master and relevant PRs first. Complete the day's real deliverable, test it, and
commit cohesive changes on a Marcus branch. Do not change teammates' feature
screens unless they explicitly request it. Use small, descriptive commits when
they represent separate completed units; no empty commits, backdating, or
cosmetic changes solely to increase the count. If a deliverable is already
complete, verify it and report that fact instead of creating a duplicate commit.

| Date | Work and completion evidence | Task |
| --- | --- | --- |
| Nov 5 Thu | Finish remaining Gemini/App Check and teammate-access setup; generate real FlutterFire options, enable anonymous auth/Firestore/AI Logic, deploy owner-only rules, verify tagging/storage/outfits live. Resolve backend integration issues before feature freeze. | M3-01, M3-03–06 |
| Nov 6 Fri | Bug fixes only. Reproduce and fix backend issues from the Android Friday flow. Capture actual results for anonymous sign-in, own/other-user access, offline reload, tagging latency, and valid outfits. Do not mark pending checks passed. | Friday MVP |
| Nov 7 Sat | Implement Open-Meteo weather lookup for rounded coordinates, input validation, network/timeout errors and deterministic tests. | M3-07 |
| Nov 8 Sun | Add city geocoding fallback, response validation, weather fake and attribution/licence handoff for Hope. | M3-07 |
| Nov 9 Mon | Add App Check initialization hooks and debug/release provider configuration; document developer setup without committing tokens. | M3-08 |
| Nov 10 Tue | Implement a persistent per-device daily AI request allowance, clock/date handling, clear limit errors and tests for restarts/day rollover. | M3-08 |
| Nov 11 Wed | Validate App Check in the console and team builds, enforce only once authorized clients work; verify rejection and quota behavior. Never add billing automatically. | M3-08 |
| Nov 12 Thu | Extend AiService/fakes with Fit Check verdict and at most three clothing-only suggestions; add structured reply and error tests. | M3-09 |
| Nov 13 Fri | Implement live Fit Check with photo preparation, explicit person-photo policy (clothing-only without paid tier), defensive parsing, and Keith's integration handoff. | M3-09 |
| Nov 14 Sat | If all P1 work is verified, implement one-piece swaps with locked item IDs, closet validation and tests; otherwise resolve P1 blockers first. | M3-10 (P2) |
| Nov 15 Sun | If P1 is complete, add ratings, last-three-day wear history and style preferences to prompts with tests showing context propagation and small-closet behavior. | M3-10 (P2) |
| Nov 16 Mon | Run backend regression checks; prepare a redacted Firestore demo walkthrough and sample-data evidence. Use the team's actual demo script if available. | M3-11 preparation |
| Nov 17 Tue | Final Member 3 handoff: verify remaining requirements, fix release blockers, collect actual Firestore persistence proof and recording if available, document outstanding manual steps and deliver to Keith when explicitly authorized. Stop the daily automation after this run. | M3-11, final handoff |

## Constraints and manual dependencies

- Keep the computer powered on and Codex running at the scheduled time.
- Google sign-in, any acceptance of terms, and teammate access grants may require
  the account owner. Team email addresses and minimum required roles are needed
  before invitations. Do not expose credentials or add a paid plan.
- Real Android checks require a connected device/emulator with the team's build.
- M3-11 requires a real console/app demonstration. A script is not a recording;
  a missing recording stays explicitly incomplete. Teammate demo script review
  and final video editing are outside Marcus's implementation scope.
- Move Trello cards to Done only after their work meets acceptance criteria and
  the PR merges. Do not claim a blocked console task is complete.
- If a scheduled run is missed, prioritize overdue P0/P1 work on the next run;
  never alter commit dates or manufacture activity for a missed day.
- The daily schedule is a work plan, not a guarantee that external access,
  hardware or teammate dependencies will be available by the deadline.
