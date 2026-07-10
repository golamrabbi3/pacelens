# PaceLens Feature Inventory

This document describes the features currently implemented in the repository. It is based on the app routes, screens, domain services, native platform channels, and tests in this checkout.

## Product Scope

PaceLens is a Flutter MVP for estimating cricket-ball speed from local mobile video. The app is intentionally local-first: it does not use cloud APIs, accounts, analytics SDKs, or video uploads. Results are presented as experimental estimates, not certified radar measurements.

## App Navigation

Routes are defined in `lib/app/router.dart`:

| Route | Screen | Purpose |
| --- | --- | --- |
| `/` | `HomeScreen` | Entry point, safety warning, workflow actions. |
| `/setup` | `CameraSetupScreen` | Capture guidance and native camera capability query. |
| `/record` | `RecordingScreen` | Recording placeholder and 60 FPS policy notice. |
| `/import` | `VideoImportScreen` | Local video picker and native timestamp inspection. |
| `/calibration` | `CalibrationScreen` | Manual side-on linear calibration. |
| `/ball-selection` | `BallSelectionScreen` | Initial ball point review for the loaded fixture. |
| `/tracking` | `TrackingCorrectionScreen` | Manual trajectory correction and point filtering. |
| `/results` | `ResultsScreen` | Speed estimate, confidence, warnings, and save action. |
| `/replay` | `ReplayScreen` | Annotated trajectory replay over tracked observations. |
| `/history` | `HistoryScreen` | Local saved result list from Drift storage. |

## Working Analysis Flow

The current fully working analysis path is the synthetic debug fixture. In debug builds, the home and import screens can load a generated moving-dot video model from `SyntheticAnalysisService`. The workflow then supports calibration review, ball selection review, manual point correction, speed calculation, annotated replay, and local result saving.

Imported-video metadata inspection is implemented, but real imported-frame extraction and frame-by-frame calibration are not complete. After importing a valid video, the app loads metadata into the analysis workflow, but no decoded observation points are generated from the selected file yet.

## Camera Capability Query

`CameraSetupScreen` calls `HighSpeedCameraPlatform.getSupportedProfiles()` through Riverpod. The Dart channel is implemented in `lib/core/platform/high_speed_camera_platform.dart`.

Android support in `android/app/src/main/kotlin/com/pacelens/pacelens/MainActivity.kt` queries back-camera Camera2 high-speed and standard FPS profiles, filters for 60 FPS or higher, and reports profile size, FPS range, high-speed status, and timestamp support.

iOS support in `ios/Runner/AppDelegate.swift` enumerates back-camera AVFoundation formats with maximum frame rate of at least 60 FPS. Native recording itself is not enabled on either platform; `startRecording` returns an explicit unsupported error.

## Video Import and Timestamp Inspection

`VideoImportScreen` uses `file_selector` to choose `.mp4`, `.mov`, or `.m4v` files. It calls `NativeVideoInspector.inspect()` via the `pacelens/video_inspector` method channel.

Android uses `MediaMetadataRetriever` and `MediaExtractor`. iOS uses `AVAsset`, `AVAssetTrack`, and `AVAssetReader`. Both native paths sample presentation timestamps and report resolution, duration, nominal FPS, sampled frame count, monotonic timestamp status, duplicated timestamp status, irregular frame spacing, average frame interval, and warnings.

A video is considered supported only when it is at least 60 FPS, has stable timestamps, has monotonic timestamps, and has no duplicated timestamps. Videos below 120 FPS are allowed but warned.

## Calibration and Tracking Correction

Calibration is a manual side-on linear model. `CalibrationScreen` lets the user place two points on a known visible distance and enter metres. `CalibrationMath.createLinear()` rejects out-of-frame points, too-short pixel distances, non-positive distances, and invalid metres-per-pixel values.

`TrackingCorrectionScreen` lets the user step through observations, edit X/Y ball-center coordinates, add points, reject or accept points, mark uncertainty, and delete points. The trajectory preview is drawn by `TrajectoryPainter`.

## Speed Estimation

`SpeedEstimator` calculates release and average speed from projected ball observations. It requires:

- nominal FPS of at least 60;
- stable and ordered timestamps;
- camera motion score at or below the configured limit;
- at least four accepted, real, non-occluded observations above the confidence threshold;
- a minimum tracked time window.

The estimator projects points onto the calibration line, converts pixels to metres, rejects velocity outliers, fits linear regression slopes, computes likely speed range from residual error, and assigns `high`, `medium`, `low`, or `failed` confidence. Failure results hide speed values.

## Results, Replay, and History

`ResultsScreen` shows release speed in km/h and mph when confidence is not failed, plus likely range, average tracked speed, source FPS, calibration distance, observation counts, and warnings. Users can save the current result locally.

`ReplayScreen` shows an annotated trajectory progression over the observation list. It is a custom-painted analysis replay, not decoded video playback.

`HistoryScreen` reads saved results from `AppDatabase`, a Drift database named `pacelens`. Stored fields include video URI, source FPS, calibration distance, release and average speed, confidence, and warning messages. Video bytes are not stored.

## Tests Covering Features

Current tests cover:

- home-screen actions and warning copy in `test/widgets/app_flow_test.dart`;
- speed estimation across synthetic speeds, noisy/outlier data, low FPS warning, duplicate timestamps, insufficient observations, interpolated point exclusion, and reversed movement in `test/core/speed_estimator_test.dart`;
- video inspection payload parsing and support checks in `test/core/video_inspection_result_test.dart`;
- calibration math and unit conversion in `test/core/calibration_math_test.dart`.

Run `flutter test` and `flutter analyze` before changing feature behavior.

## Known Gaps

- Native high-speed recording is a capability-query stub, not a recording implementation.
- Imported-video frame extraction is not implemented.
- Automatic ball tracking has interfaces and entity support but no production tracker wired into the UI.
- Replay uses drawn trajectory data rather than actual video frames.
- The current production-ready analysis path depends on manually supplied or synthetic observations.
