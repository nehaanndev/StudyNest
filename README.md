# StudyNest

StudyNest is a cozy, local-first study planner that brings tasks, calendar
planning, notes, focus sessions, habits, rewards, and room customization into
one mobile experience.

Instead of treating productivity as a list of chores, StudyNest creates a
simple progression loop:

> Plan your work, focus, earn coins, and personalize a study space you want to
> return to.

## Try the Android judge build

The OpenAI Build Week judge build supports Android 7.0 and newer.

1. Open the [latest GitHub release](https://github.com/nehaanndev/StudyNest/releases/latest).
2. Download `StudyNest-Build-Week-2026.apk`.
3. Open the downloaded file on an Android device.
4. If Android asks for permission to install apps from the browser or file
   manager, allow it temporarily.
5. Install and open StudyNest.

An account is not required to explore the core local-first experience. This is
a direct-distribution judge build, not a Google Play production release. See
the [judge guide](docs/BUILD_WEEK_JUDGE_GUIDE.md) for a short evaluation path
and the verified APK checksum.

## What StudyNest includes

- A dashboard that brings the current study plan into one place
- Tasks with due dates, priorities, completion state, and custom filters
- An immersive calendar planning mode with long-press rescheduling
- A configurable Pomodoro timer with focus goals and earned rewards
- Notes, study guides, flashcards, quizzes, and formula sheets
- Habit tracking
- A coin economy with unlockable focus upgrades, themes, and decorations
- A customizable visual study space
- Local-first persistence with optional Firebase-backed account sync
- Shared navigation and restored destination state across sessions

## OpenAI Build Week development

StudyNest existed before Build Week and was meaningfully extended with Codex
during the July 13-21, 2026 submission period. The event-window work includes:

- Reworked onboarding and application navigation
- Stronger Firebase account isolation and auth-transition handling
- A configurable coin and rewards architecture
- Custom Pomodoro lengths and focus rewards
- Shop upgrades and improved narrow-screen layouts
- Task filtering, including overdue and custom views
- Immersive calendar plan mode and long-press event rescheduling
- Regression tests covering state, auth, rewards, planner logic, and widgets

The event-window history contains 18 commits, with 6,262 additions and 2,153
deletions across 53 files.

Codex accelerated feature implementation, refactoring, debugging, responsive
UI work, test design, regression investigation, and release verification. The
commit history preserves the implementation sequence and the primary Codex
build thread is provided with the Devpost submission.

## Technical overview

- Flutter and Dart
- Firebase Authentication and Cloud Firestore on configured mobile builds
- Shared Preferences for local-first persistence
- Responsive Material UI with custom-painted study environments
- Unit and widget test coverage for core workflows

## Run locally

Install a compatible Flutter SDK, then run:

```bash
flutter pub get
flutter run
```

The Android and iOS Firebase applications are configured in the repository.
Other platforms fall back to local-only behavior when their Firebase options
are not configured.

## Verify the project

```bash
flutter analyze
flutter test
flutter build apk --release
```

At submission preparation time, static analysis completed without issues, all
55 automated tests passed, and the Android release APK built successfully.

## Repository structure

```text
lib/app/       Application state, persistence, rewards, auth, and sync
lib/models/    Study content and shared domain models
lib/screens/   Product screens and feature-specific UI
lib/widgets/   Shared navigation, study-space, and decorative widgets
test/          Unit and widget regression tests
```

## Current release status

The Build Week APK uses a temporary debug certificate for direct judge
distribution. A future Google Play release will use a dedicated upload key and
complete the store's production review process.
