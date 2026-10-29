# Jewte 1.1.0 validation

## Verified

- `flutter analyze`: no issues found.
- `flutter test`: all 16 tests passed. Tests cover the real catalogue, persistence/restore, cross-screen completion, search, large text, rapid tab changes, retained scroll positions, reduced motion and the Android bridge protocol.
- Every one of the 1,567 YouTube result URLs contains exactly the canonical topic title as `search_query`, without added exam/course text. The catalogue stores that same title as its query.
- Catalogue integrity: 10 technical subjects, 1,567 unique normalized titles and stable IDs, 41 niche records attached to canonical topics. Widgets add no duplicate syllabus records.
- Progress, saved topics, notes, recents and preferences survive store reloads. Rapid writes serialize; failed writes report an error; invalid backups are rejected before mutation.
- All four tabs render at 320 logical pixels with 1.5x text scaling without overflow. The widget gallery also renders and scrolls at that size. Rapid switching during active transitions produces no framework exceptions and retains each tab's scroll position.
- Progress updates preserve the MaterialApp theme instance. Reduced motion suppresses the tab fade.
- `flutter test integration_test/android_widgets_test.dart -d emulator-5554 --no-uninstall`: passed on the Pixel 10 Pro emulator, using the real Kotlin MethodChannel implementation. Verifies persisted native snapshots, completion/saved counts, next-topic selection, exact-topic search data, RemoteViews PNG renders at 720×360 and 440×280, rejection of invalid native snapshots, and gallery loading of actual native previews.
- Native widget previews were extracted and visually inspected. `docs/screenshots/widget-progress.png` and `widget-topic.png` use a controlled test state (one completed topic, one saved topic, TLB reach selected), separate from the user's study data.
- Signed universal release APK: version 1.1.0 (3), package `app.jewte.jewte`, minimum API 24, target/compile API 36. Includes ARM32, ARM64 and x86_64. Release metadata, signature and delivered-file hashes are recorded in `docs/build-manifest.json`.

- Release emulator smoke test: installation succeeded, cold topic and warm library/topic intents returned Status ok and rendered their expected destination. Both native providers were registered with Android. No matched Jewte Flutter/fatal errors appeared in the launch logs.

## Behavior

Widgets display a compact mirror. Checklist changes remain in Flutter; the mirror updates after the progress repository confirms a successful save. Native mirror writes run on one worker queue. Pending syncs are drained when the app leaves the foreground. Widgets cannot independently overwrite checklist progress.

The progress widget opens Subjects. The next-concept widget opens the canonical topic detail; its YouTube shortcut constructs an HTTPS result URL from the exact title. Warm and cold launch actions are consumed once through the platform channel. Widgets use no background timers, network refreshes, deadlines or streaks.

## Practical limits

No physical-phone session was performed. Widget placement, padding and resizing vary by launcher. Native layouts and the bridge were exercised on the Android emulator; automated tests do not confirm placement through every launcher's pin dialog. Supporting Android 8+ launchers can use the in-app Add button. The widget picker provides a fallback, including Android 7. Progress refreshes after changes are saved in Jewte.

YouTube/browser intent handling depends on installed applications. Searches do not select or endorse videos. PYQ references use PDF viewer page numbers; supplied answers are not independently revalidated.

Progress is local. Clipboard backups must be pasted somewhere safe. Uninstalling or clearing app data removes local progress. Keep the private release keystore for compatible future updates.

During release screenshot capture, the emulator displayed a System UI ANR dialog. Jewte continued to handle explicit destination intents underneath it. This is separate from an app-process crash; physical-device frame timing has not been measured.
