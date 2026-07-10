# Repository Guidelines

## Project Structure & Module Organization

PaceLens is a Flutter app for local cricket-ball speed analysis. Main code lives in `lib/`:

- `lib/app/`: app shell, routing, and theme.
- `lib/core/`: shared errors, math utilities, platform channels, and Drift storage.
- `lib/domain/`: entities and service contracts.
- `lib/features/`: screens grouped by workflow, such as `analysis`, `calibration`, `recording`, `replay`, and `video_import`.
- `test/core/` and `test/widgets/`: unit and widget tests.
- `android/` and `ios/`: native camera/video capability channel implementations.

Generated Drift code stays beside its source, for example `lib/core/storage/app_database.g.dart`.

## Build, Test, and Development Commands

Run these from the repository root:

- `flutter pub get`: install Dart and Flutter dependencies.
- `dart run build_runner build`: regenerate Drift and other generated Dart files.
- `dart run build_runner build --delete-conflicting-outputs`: regenerate when stale generated files conflict.
- `flutter analyze`: run static analysis using `analysis_options.yaml`.
- `flutter test`: run all unit and widget tests.
- `flutter run`: launch on a connected device or simulator.

## Coding Style & Naming Conventions

Use the `flutter_lints` rules included by `analysis_options.yaml`. Format Dart with `dart format .` before submitting changes. Use two-space indentation. Name files with `snake_case.dart`, classes with `PascalCase`, and methods, variables, and providers with `lowerCamelCase`.

Keep feature UI inside `lib/features/<feature>/`, shared utilities inside `lib/core/`, and analysis objects inside `lib/domain/`. Avoid sending full video frames through `MethodChannel`; expose compact metadata or capability results.

## Testing Guidelines

Use `flutter_test`. Place pure logic tests in `test/core/` and app flow or screen tests in `test/widgets/`. Name files with the `_test.dart` suffix, matching the subject where possible.

Run `flutter test` and `flutter analyze` before opening a pull request. Add focused tests for calibration math, speed estimation, warnings, storage behavior, and route-level flows when those areas change.

## Commit & Pull Request Guidelines

This checkout has no local Git history, so use clear imperative commit messages, such as `Add imported video timestamp warnings` or `Fix calibration distance validation`.

Pull requests should include a summary, test results, linked issue if available, and screenshots or recordings for visible UI changes. Call out native Android/iOS changes, generated files, and privacy-sensitive behavior changes.

## Security & Configuration Tips

The app is designed for local processing only. Do not add cloud APIs, analytics, accounts, networking permissions, or video upload behavior without documenting the privacy impact and updating platform manifests.
