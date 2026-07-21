# StudyNest Build Week Judge Guide

This guide provides a fast, repeatable way to evaluate the Android submission.

## Install

1. Visit the [latest GitHub release](https://github.com/nehaanndev/StudyNest/releases/latest).
2. Download `StudyNest-Build-Week-2026.apk`.
3. Open the APK on a device running Android 7.0 or newer.
4. Approve the temporary install-from-this-source prompt if Android shows it.
5. Install and launch StudyNest.

No account is required for the core local-first workflow.

## Recommended five-minute evaluation

1. Complete the welcome flow and arrive at the dashboard.
2. Open **Tasks**, create a task with a due date and reward, and try the task
   filters.
3. Open **Planner**, enter plan mode, and arrange a study block on the calendar.
4. Open **Focus**, choose a focus length, and inspect the Pomodoro controls and
   reward explanation.
5. Open **Shop** to see how completed work and focus sessions feed the coin and
   customization system.
6. Open **More** to inspect notes, habits, profile controls, and the wider study
   toolkit.
7. Close and reopen the app to confirm local persistence.

## APK verification

- File: `StudyNest-Build-Week-2026.apk`
- Package: `com.studynest.app`
- Version: `1.0.0` (`versionCode` 1)
- Minimum Android version: Android 7.0 / API 24
- SHA-256:
  `a1f017149df9c528d406e5e7407fdfd8c90d6071b1bf971d03a1f6dc6ee29e09`

The APK is a universal direct-distribution build signed with a temporary
Android debug certificate. It is intended for Build Week judging and is not a
Google Play production artifact.

The uploaded build passed a fresh-install smoke test on a physical Pixel 9 Pro
running Android 16.

## If installation is unavailable

The public demo video shows the complete product loop for judges who are not
using an Android device. The repository also contains setup instructions and
the full automated test suite.

## Suggested evaluation focus

StudyNest's central product idea is the connection between planning,
concentrated work, earned rewards, and personalization. Individual utilities
are designed to reinforce that loop rather than behave as unrelated tools.
