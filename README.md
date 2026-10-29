# Jewte

A Flutter Android study app built around your GATE CS technical checklist. Its name on the Android launcher is **Jewte**.

## Included

- 10 technical subjects, with C Programming and Data Structures separated.
- 1,567 canonical concepts after removing revision/admin entries and consolidating overlapping concepts. Alternate wording remains searchable. Shared foundations have one home subject and one progress record.
- 41 curated niche PYQ topics with focused YouTube searches, explanations of the conceptual trap, and PDF viewer page references.
- Topic completion, subject progress, global/subject search, saved concepts and personal notes.
- Two native Android home-screen widgets: overall progress and next concept, with a direct YouTube shortcut. Add them from Settings > Home-screen widgets or your launcher’s widget picker. Pinning from the app requires a supporting Android 8+ launcher; Android 7 users can use the widget picker.
- Topic-only YouTube searches: the exact concept title, without an added exam or course prefix.
- Independent tab scroll positions, lazy niche/saved lists, short transitions, local persistence, clipboard backup/restore, light/dark appearance and Reduce Motion (including Android’s animation accessibility setting).
- Offline checklist and bundled fonts. YouTube searches open in the YouTube app or browser and require internet.
- No accounts, ads, analytics, aptitude, mathematics, study timelines or deadline targets.

## Install

Copy **Jewte.apk** from your Desktop to your Android phone, open it, and allow that file-transfer/browser app to install this APK when Android asks. The minimum supported OS is Android 7.0 (API 24). The universal release APK includes ARM, ARM64 and x86_64 variants.

The app is locally signed for direct installation. It has not been published to Google Play. Keep `android/jewte-release.jks` and `android/key.properties` private and backed up if you want future builds to update this installation without uninstalling. They are deliberately ignored by Git. There is no cloud account or automatic cross-device progress sync.

Before uninstalling or changing phones, use **Settings > Copy progress backup**, paste that JSON somewhere safe, then restore it on the other installation. Clipboard backup is text, not an automatically created backup file. Restoring replaces the current progress and notes.

## Development

The project is saved at the requested Desktop/gatechecklist directory.

Validated toolchain: Flutter 3.47.5, Dart 3.13.4, JDK 17, Android SDK 36. `android/gradle.properties` selects the JDK 17 installation on this machine; update its `org.gradle.java.home` path if moving the project.

```powershell
flutter pub get
flutter analyze
flutter test
flutter test integration_test/android_widgets_test.dart -d <emulator-id>
flutter build apk --release
```

APK build output: `build/app/outputs/flutter-apk/app-release.apk`.

Core files:

- `assets/data/catalog.json`: canonical curriculum and niche references.
- `lib/models/catalog.dart`: catalogue loading, search and safe YouTube search URIs.
- `lib/state/study_store.dart`: local progress, serialized writes and validated backup restore.
- `lib/screens/`: overview, library, subject checklists, global search, topic details, niche/saved collections and settings.
- `lib/theme.dart` and `lib/widgets.dart`: visual system, shared components and motion.
- `test/`: catalogue, persistence, topic-only search, navigation, large-text and widget-bridge regression tests.
- `integration_test/`: Android tests of native widget rendering, snapshot persistence and gallery loading.
- `android/app/src/main/kotlin/app/jewte/jewte/JewteWidgets.kt`: native widget providers and the progress mirror.
- `docs/catalog-merges.json`: overlapping wording consolidated during catalogue preparation.
- `docs/DESIGN.md`: TypeUI reference and design decisions.
- `docs/screenshots/`: actual Flutter-rendered UI captures.

## Content sources

The supplied `CS_GATE2027_Syllabus.pdf`, technical sections 2-10, supplied `pyq.pdf`, and the earlier expanded checklist. Mathematics and aptitude topic blocks are excluded. Supporting and legacy topics are labeled. PYQ references use the PDF viewer's page numbers; answer keys are not independently validated. The niche collection does not predict future question frequency.

Layout inspiration: [TypeUI's free application-shell prompt](https://www.typeui.sh/prompts/shells). The original palette uses paper, carbon, forest and chartreuse, without purple gradients.

## Validation

See `docs/QA.md` for test/build/install evidence and practical limits.
