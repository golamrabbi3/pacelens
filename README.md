# PaceLens

PaceLens is a Flutter MVP for estimating cricket-ball or moving-object speed from mobile camera input using local processing only.

**PaceLens provides experimental camera-based speed estimates. Results depend on camera placement, frame rate, lighting, calibration, timestamp quality, tracking accuracy, object visibility, and perspective. It is not a certified radar-speed measurement system.**

## Current State

The project currently has two active product paths:

1. A live local speed test that uses the device camera, OpenCV frame differencing, and two calibrated guide lines to estimate speed without saving video.
2. An imported-video analysis pipeline that can select local video files and inspect native frame timestamps, but does not yet decode real frames into the calibration and tracking workflow.

The app also keeps a synthetic debug analysis path for validating the manual analysis workflow end to end.

## Implemented Features

- Home navigation for live measurement, imported-video analysis, saved results, setup guidance, and debug synthetic analysis in debug builds.
- Camera setup guidance plus Android/iOS native camera capability queries for 60 FPS or higher profiles.
- Live camera preview using the Flutter `camera` plugin.
- OpenCV-based live motion detection over sampled luma frames.
- Calibrated guide-line speed estimation from a user-entered real-world distance.
- Experimental AR-depth mode UI and Dart estimator contracts. Native AR-depth sampling is not implemented yet, so Android and iOS report it as unsupported.
- Local video selection with `file_selector`.
- Native imported-video metadata and timestamp inspection:
  - Android: `MediaMetadataRetriever` and `MediaExtractor`.
  - iOS: `AVAsset`, `AVAssetTrack`, and `AVAssetReader`.
- Timestamp support checks for FPS, monotonic timestamps, duplicated timestamps, irregular frame spacing, and likely re-encoding warnings.
- Synthetic high-FPS moving-dot fixture for manual calibration, ball-point correction, speed calculation, replay, and saved-result testing.
- Drift-backed local result history. Video bytes are not stored in the database.

For a route-by-route inventory of implemented features, current MVP limits, and test coverage, see [`FEATURES.md`](FEATURES.md).

For the prioritized next implementation slices, see [`NEXT_FEATURES.md`](NEXT_FEATURES.md).

## Architecture

```text
lib/
├── app/                 # Material app, router, theme
├── core/
│   ├── errors/          # Explicit analysis errors
│   ├── math/            # Calibration, projection, statistics, units
│   ├── platform/        # Camera, video inspector, and AR-depth channels
│   └── storage/         # Drift database
├── domain/
│   ├── entities/        # Camera, video, observations, calibration, results
│   └── services/        # Speed estimators, trackers, frame-source contracts
└── features/            # Home, setup, recording, import, calibration, tracking, replay, history
```

Native code lives in:

- `android/app/src/main/kotlin/com/w3artists/pacelens/MainActivity.kt`
- `ios/Runner/AppDelegate.swift`

## Platform Capability Model

Flutter does not assume that one plugin exposes identical high-speed capture on every device.

Android uses a Kotlin `MethodChannel` backed by Camera2 capability queries. It enumerates back-camera profiles at 60 FPS or higher and marks constrained high-speed profiles when Camera2 exposes them.

iOS uses a Swift `MethodChannel` backed by AVFoundation format and frame-rate-range enumeration.

Native high-speed video recording commands currently return explicit unsupported errors. The live guide-line test uses camera preview image streams instead of native high-speed recording.

Imported-video inspection is native on both platforms and returns compact metadata/timestamp diagnostics. Do not stream full-resolution video frames continuously through `MethodChannel`.

## Running

Run from the repository root:

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

## Known Limitations

- The live guide-line test is an experimental local estimate and depends on fixed camera placement, visible object motion, lighting, and accurate guide-line distance.
- Native high-speed recording is not complete.
- AR-depth sampling is not implemented natively on Android or iOS.
- Imported-video metadata and timestamp inspection is complete, but imported-video frame extraction and calibration from real decoded frames are not complete.
- Automatic cricket-ball tracking for imported footage is not wired into the UI.
- The synthetic debug path is still the only full manual recorded-video analysis path.
- Linear calibration assumes a stationary side-on camera and motion approximately parallel to the calibration line.
- No 3D reconstruction or broadcast-footage analysis is attempted.
- Speeds are hidden when recorded-video analysis confidence fails.

## Privacy

Processing is local. The app does not use cloud APIs, hosted AI services, analytics SDKs, accounts, or video upload behavior. Video bytes are not stored inside the Drift database.

The app displays the installed version from `pubspec.yaml` on every page. Release builds may check Google Play or the Apple App Store for a newer published version and show an update button when one is available. That check sends the app package identifier to the relevant store; it does not upload video or analysis data.
