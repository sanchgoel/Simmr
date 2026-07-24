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
