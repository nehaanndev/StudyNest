# StudyNest

StudyNest is a cozy, local-first study planner that brings tasks, calendar
planning, notes, focus sessions, habits, rewards, and room customization into
one mobile experience.

**OpenAI Build Week track:** Work and Productivity

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

## OpenAI Build Week eligibility and development record

StudyNest is a pre-existing project. The submission period ran from July 13 at
9:00 a.m. PDT through July 21 at 5:00 p.m. PDT. Only the work described under
**New during the submission period** is presented for Build Week evaluation.

### Pre-existing foundation

The last repository state before the submission period was
[`aba7b2f`](https://github.com/nehaanndev/StudyNest/commit/aba7b2fdf3304060537239db7f45a5c18abc13c1),
dated June 12, 2026. At that point, StudyNest already had its Flutter mobile
foundation, core study screens, local persistence and Firebase integration,
study-space themes, and the initial decoration collection. These parts provide
product context but are not claimed as Build Week work.

### New during the submission period

All eligible development below was completed with Codex between July 18 and
July 21, after the submission period opened:

| Date (PDT) | New work | Dated repository evidence |
| --- | --- | --- |
| July 18-19 | Reworked onboarding, shared navigation, restored destinations, and safer Firebase account isolation | [PR #9](https://github.com/nehaanndev/StudyNest/pull/9), commits [`99aab1f`](https://github.com/nehaanndev/StudyNest/commit/99aab1f) through [`e057291`](https://github.com/nehaanndev/StudyNest/commit/e057291) |
| July 19 | Added the configurable coin/reward architecture, custom Pomodoro lengths, shop upgrades, responsive reward UI, and reward regression tests | [PR #10](https://github.com/nehaanndev/StudyNest/pull/10), commits [`66d492f`](https://github.com/nehaanndev/StudyNest/commit/66d492f) and [`d1dd318`](https://github.com/nehaanndev/StudyNest/commit/d1dd318) |
| July 19 | Fixed dialog lifecycle behavior and expanded Pomodoro and shop test coverage | [PR #11](https://github.com/nehaanndev/StudyNest/pull/11), commits [`064fcf2`](https://github.com/nehaanndev/StudyNest/commit/064fcf2) through [`0a3b1d8`](https://github.com/nehaanndev/StudyNest/commit/0a3b1d8) |
| July 20 | Added task filtering, including overdue, completion, and custom views | [PR #12](https://github.com/nehaanndev/StudyNest/pull/12), commit [`17d88b5`](https://github.com/nehaanndev/StudyNest/commit/17d88b5) |
| July 20 | Added immersive calendar plan mode, event editing, timeline layout, long-press rescheduling, and planner model tests | [PR #13](https://github.com/nehaanndev/StudyNest/pull/13), commits [`b36ceca`](https://github.com/nehaanndev/StudyNest/commit/b36ceca) and [`c6b3ab9`](https://github.com/nehaanndev/StudyNest/commit/c6b3ab9) |
| July 21 | Built and verified the Android judge release and added submission-specific documentation | [PR #14](https://github.com/nehaanndev/StudyNest/pull/14) |

The eligible product-development history contains 18 commits, with 6,262
additions and 2,153 deletions across 53 files, followed by the release and
documentation preparation in PR #14.

### Codex-use evidence

Codex was used throughout the eligible work for implementation, refactoring,
debugging, responsive UI iteration, test design, regression investigation, APK
construction, and release verification. The dated commits and pull requests
above preserve the repository-side development timeline. The Devpost entry
also supplies the required primary `/feedback` Codex Session ID so judges can
associate the timestamped Codex build thread with this submission.

Representative examples include using Codex to separate large screens into
reusable controls and runners, protect local snapshots across Firebase auth
changes, design and test the configurable reward model, implement calendar
rescheduling behavior, and diagnose release-build and device-install issues.

## Third-party integrations and licensing

StudyNest does not redistribute a third-party dataset or call an unlicensed
content API. Its integrations and dependencies are:

| Integration | Purpose and authorization basis |
| --- | --- |
| Flutter and Dart | Application framework and language, used under their published open-source licenses. |
| Firebase Core, Authentication, and Cloud Firestore | Optional authentication and cloud synchronization through the entrant-controlled `studynest-e477d` Firebase project, subject to the applicable Google/Firebase terms. |
| Google Sign-In | Optional account linking through the entrant-controlled Firebase/Google configuration, subject to the applicable Google API terms. |
| `connectivity_plus`, `shared_preferences`, `flutter_svg`, `cupertino_icons`, and test/lint packages | Packages obtained from pub.dev and used under the licenses published with their package releases. Exact versions are recorded in `pubspec.lock`. |
| Project visual assets | Original or project-generated assets stored in the repository; no third-party visual-asset service is called at runtime. |

The complete SDK and package inventory is declared in `pubspec.yaml` and
locked in `pubspec.lock`. Entrants remain responsible for maintaining the
associated service accounts and complying with the applicable provider terms.

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
55 automated tests passed, the Android release APK built successfully, and the
judge build passed a fresh-install smoke test on a physical Pixel 9 Pro running
Android 16.

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
