# Changelog

Every TestFlight build gets an entry here, newest first. Versions are `MARKETING_VERSION (CURRENT_PROJECT_VERSION)` — e.g. `1.0 (4)` — matching what Xcode/App Store Connect show for the build.

## Release process

Before archiving a new TestFlight build:

1. Summarize what changed since the last tag: `git log <last-tag>..HEAD --oneline`.
2. Move the `[Unreleased]` section's notes into a new `## 1.0 (N) — YYYY-MM-DD` section below (bump `N` to match the new `CURRENT_PROJECT_VERSION`).
3. Bump `CURRENT_PROJECT_VERSION` in the Xcode project, archive, export/upload.
4. Commit the changelog + version bump together, then tag the commit: `git tag v1.0-N`.
5. Start a fresh empty `[Unreleased]` section for the next round of work.

## [Unreleased]

## 1.0 (10) — 2026-08-01

- Re-upload of 1.0 (9) — same code, no changes, just a bumped build number.

## 1.0 (9) — 2026-08-01

- Added a post-cooking feedback flow: right after finishing a recipe, rate it 1-5 stars, then either show it off (optional photo + share) or tell us what to improve (recipe, cooking guidance, AI generation, or app experience, with an optional note) — synced to Firestore for review.
- The Cooking Mode Live Activity no longer disappears the instant you finish — it now shows a "rate this dish" card (Lock Screen + Dynamic Island) with Rate/Not now, so finishing from the Lock Screen while the app is backgrounded or closed still gets you a feedback prompt. Tapping Rate deep-links straight into the feedback flow for that cook, even from a cold launch.
- The screen no longer auto-locks while a cooking timer is actively running.
- Redesigned Cooking Mode for one-handed use: Previous/Next are now floating circular buttons docked near the bottom instead of full-width buttons eating vertical space, and the timer card is smaller, centered, and no longer resizes as it moves between idle/running/paused/complete.
- Fixed: the Firestore sync for feedback used a fire-and-forget write that could silently fail (e.g. on a rules rejection) with no signal anywhere. It now awaits the real server round-trip and logs success/failure.

## 1.0 (8) — 2026-07-31

- Removed the embedded recipe-collections section from Home — the dedicated Explore tab already covers browsing curated collections, so the copy on Home just duplicated the network call and UI.

## 1.0 (7) — 2026-07-26

- Added Sign in with Apple and Sign in with Google (via Firebase Auth), shown once after onboarding — skippable, since the app still works fully signed out. Settings gained an Account section to sign in/out later.
- Signing in now backs up and restores your data via Firestore: onboarding answers (Kitchen Profile), recipes, and cooking session progress sync up automatically as you use the app, and restore back down on a fresh install or a fresh sign-in on any device — so reinstalling or switching devices no longer starts you over.
- Added a Skip button to onboarding's question screens, for anyone who wants to start cooking before answering everything — skipped questions are simply left unanswered, and recipe personalization degrades gracefully instead of breaking.
- Fixed: reopening "Paste Recipe" or "Type Dish Name" after using it once showed whatever was typed the last time instead of a clean input.
- Fixed: signing in with Google was crashing the app (a missing GoogleSignIn configuration step).
- Fixed: signing in on a fresh install could land on Home with your existing recipes missing, even though they were already backed up — the restore was racing the screen transition and losing. Sign-in now shows a brief loading state until your data is fully back in place, with no flash of the "no recipes yet" layout on the way in.
- App Store Connect no longer asks the manual export-compliance question after each TestFlight upload (Simmr only makes standard HTTPS calls).

## 1.0 (6) — 2026-07-26

- Cooking sessions now persist: force-quitting mid-cook and relaunching (via the app icon or the Live Activity) lands you back at the exact step and timer state instead of losing progress. Home gained a "Continue Cooking" card and a "Recent Recipes" history list covering active, paused, not-started, and completed cooks.
- Redesigned Home around that history: one scrolling dashboard instead of separate screens, with recipe creation (camera, photos, paste, dish name) tucked behind a single "New Recipe" sheet.
- Redesigned the cooking-step timer as a custom-drawn hourglass, replacing the old circular dial — visibly smaller so it doesn't crowd out the recipe, with sand that drains/fills while running, a subtle breathing/rocking idle animation, and a signature 180° flip when restarting it after it finishes. The duration can now be adjusted while the timer is running, and down to 1 minute regardless of the recipe's suggested time.
- Fixed: navigating between recipe steps while a timer was running used to silently reset it. It now keeps counting in the background and restores exactly where it was when you return to that step.
- Fixed: tapping "Continue Cooking" right after a fresh app launch could occasionally land on a blank Cooking screen (a SwiftUI navigation timing race), needing a second tap to work. Recipe/cooking-session data now travels directly on the navigation route instead of through a side channel, closing the race entirely.
- Added a shake-to-open API log screen (TestFlight and debug builds only) showing every OpenAI request/response with success/failure, status code, and timing — for diagnosing generation issues without a debugger attached.

## 1.0 (5) — 2026-07-24

- Added Recipe Import: capture recipe pages with the camera (multi-page document scanner, reorder/retake/add pages before processing) or pick multiple existing photos, then reconstruct the recipe via on-device Vision OCR + the existing AI parser — lands on the same Recipe Overview screen as pasting text. The parsing prompt was updated to handle noisy OCR input: duplicate/repeated text, watermarks, headers/footers/page numbers, out-of-order pages, and OCR misreads are cleaned up or ignored rather than trusted at face value. If some pages can't be read, the import continues with the readable ones instead of failing outright.
- Optimization chips on the Home screen now read as tappable (tint background, border, `+`/checkmark icon, press feedback), and the section title changed from "Optimize this recipe" to "Select what to optimize."
- Tapping anywhere outside the recipe input field now dismisses the keyboard.
- App now forces light appearance everywhere (`preferredColorScheme(.light)`), fixing the status bar and a few text fields that were unreadable when the system was in Dark Mode (the app is light-mode-only by design).
- Dynamic Island fixes: the compact/minimal timer no longer reserves space for an hours digit it never needs, which was making the pill render far too wide; the leading cooking icon has an explicit smaller font instead of defaulting to body size; the minimal presentation shows a single glyph (matching how other apps use that slot) instead of icon+timer crammed together.

## 1.0 (4) — 2026-07-17

- Recipe generation is now personalized using the user's Kitchen Profile (onboarding answers): allergies, medical conditions, foods avoided, skill level, available time/appliances, diet, nutrition goals, preferred cuisines, spice preference, and measurement system are sent to OpenAI alongside the pasted recipe/dish name. Falls back to no personalization if onboarding isn't complete.
- Added a "Recipe Prompt" section in Settings to view/edit/reset the system prompt sent to OpenAI, for testing without a code change.
- Recipe schema extended with difficulty, cuisine, meal type, dietary tags, ingredient prep notes, and step cookware/heat level/lid/visual-doneness cues.
- Fixed: "Edit Kitchen Profile" from Settings restarted the whole onboarding flow from the welcome screen with no way to back out without finishing it. It now jumps straight to the questions and adds a close button, and no longer flips the profile back to "incomplete" while mid-edit.
- Fixed: several text fields (onboarding's "Other" field, the OpenAI API key field) rendered invisible in system Dark Mode.
- Recipe overview's servings/prep/cook/calories row is now rendered as pills instead of a plain text row.

## 1.0 (3) — 2026-07-16

- Added Live Activities + Dynamic Island for Cooking Mode: current step, live countdown timer, and interactive Previous/Next/Finish navigation from the Lock Screen and Dynamic Island, without needing to open the app.
- Lock Screen presentation adapts to system Dark Mode; the Dynamic Island stays fixed to dark-style colors since its cutout is always black regardless of system appearance.

## 1.0 (2) — 2026-07-16

First TestFlight build. Simmr MVP:

- Paste-to-cook flow: paste a full recipe or type a dish name, parsed/generated live via OpenAI Structured Outputs.
- Kitchen Profile onboarding flow (cooking habits, dietary needs, taste preferences).
- Cooking Mode with step-by-step instructions, per-step timers (background-accurate), and a minute stepper.
- Recipe optimization toggles (lower calories, more protein, less sugar, low carb, dairy free, spicier, kid friendly) and estimated calories per serving.
- Kitchen unit converter.
- App branding, icon, and launch animation.
