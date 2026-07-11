# PaceLens Feature Inventory

This document describes the features currently implemented in this repository. It is based on the app routes, screens, domain services, native platform channels, and tests in this checkout.

## Product Scope

PaceLens is a local-first Flutter MVP for experimental speed measurement from mobile camera input. It currently supports a live calibrated guide-line test, imported-video timestamp inspection, and a synthetic manual analysis workflow. It does not use cloud APIs, accounts, analytics SDKs, or video upload behavior.

Results are experimental estimates, not certified radar measurements.

## App Navigation

Routes are defined in `lib/app/router.dart`:

| Route | Screen | Purpose |
| --- | --- | --- |
| `/` | `HomeScreen` | Entry point, safety warning, live/import/history/setup actions. |
| `/setup` | `CameraSetupScreen` | Capture guidance and native 60 FPS camera profile query. |
| `/record` | `RecordingScreen` | Live local speed test with calibrated guide lines and AR-depth mode gate. |
| `/import` | `VideoImportScreen` | Local video picker and native timestamp inspection. |
| `/calibration` | `CalibrationScreen` | Manual side-on linear calibration for the loaded analysis model. |
| `/ball-selection` | `BallSelectionScreen` | Initial ball point review for the loaded fixture. |
| `/tracking` | `TrackingCorrectionScreen` | Manual trajectory correction and point filtering. |
| `/results` | `ResultsScreen` | Speed estimate, confidence, warnings, and save action. |
| `/replay` | `ReplayScreen` | Annotated trajectory replay over tracked observations. |
| `/history` | `HistoryScreen` | Local saved result list from Drift storage. |

## Home and Setup

`HomeScreen` exposes:

- Measure moving object: opens the setup and live recording flow.
- Analyse existing video: opens local video import.
- Previous results: opens Drift-backed saved results.
- Setup guide: opens the camera setup checklist.
- Synthetic debug analysis: debug-build-only entry into the synthetic fixture.

An app-wide version badge is rendered over every route. It reads the installed version/build from the platform package metadata generated from `pubspec.yaml`. In release builds, the same app chrome checks Google Play or the Apple App Store for a newer version and turns the badge into an update action when the store reports one.

`CameraSetupScreen` shows fixed-camera setup guidance and calls `HighSpeedCameraPlatform.getSupportedProfiles()` through Riverpod. The native capability query reports back-camera 60 FPS or higher profiles and does not silently fall back below 60 FPS.

## Live Speed Test

`RecordingScreen` is a local live estimate surface. It uses the Flutter `camera` plugin for a back-camera preview and image stream. The screen does not save video.

The default mode is calibrated guide-line measurement:

- The user enters the real distance between two on-screen guide lines.
- Camera focus and exposure are locked when supported by the device.
- Frames are sampled to a compact luma grid.
- `OpenCvMotionTracker` detects the largest changed component between consecutive frames.
- `LiveSpeedDetector` detects left-to-right or right-to-left guide crossings.
- Speed is reported in km/h and mph after a valid crossing.
- Full-scene movement is rejected as too much motion.

The recording screen also exposes an AR-depth mode selector. The Dart-side `ArDepthPlatform`, `ArDepthMotionSample`, and `ArDepthSpeedEstimator` contracts exist and are tested, but native AR-depth sampling is not implemented. Android and iOS currently return unsupported AR-depth capability responses and unsupported start-session errors.

## Native Camera Capability Channels

`lib/core/platform/high_speed_camera_platform.dart` defines the high-speed camera interface.

Android implementation:

- File: `android/app/src/main/kotlin/com/w3artists/pacelens/MainActivity.kt`
- Uses Camera2.
- Enumerates back-camera constrained high-speed video sizes and standard FPS ranges.
- Returns profiles at 60 FPS or higher.
- Native recording commands return explicit unsupported/no-recording errors.

iOS implementation:

- File: `ios/Runner/AppDelegate.swift`
- Uses AVFoundation device formats and frame-rate ranges.
- Returns back-camera formats at 60 FPS or higher.
- Marks formats with 120 FPS or higher as high-speed.
- Native recording commands return explicit unsupported/no-recording errors.

## Video Import and Timestamp Inspection

`VideoImportScreen` uses `file_selector` to choose `.mp4`, `.mov`, or `.m4v` files. It calls `NativeVideoInspector.inspect()` through the `pacelens/video_inspector` method channel.

Android uses `MediaMetadataRetriever` and `MediaExtractor`. iOS uses `AVAsset`, `AVAssetTrack`, and `AVAssetReader`.

Both native paths report:

- URI, resolution, duration, and nominal/computed FPS.
- sampled frame count.
- monotonic timestamp status.
- duplicated timestamp status.
- irregular frame spacing status.
- average frame interval.
- warning messages for low FPS, unreliable timestamps, irregular frame spacing, and likely re-encoding where available.

A video is considered supported only when it is at least 60 FPS, has stable timestamps, has monotonic timestamps, and has no duplicated timestamps. Videos below 120 FPS are allowed but warned.

Imported-video metadata is loaded into the analysis workflow, but decoded frame extraction is not implemented yet. The UI explicitly states that real frame extraction and frame-by-frame calibration are the next implementation step.

## Synthetic Manual Analysis Flow

The current full recorded-video analysis path uses a synthetic debug fixture from `SyntheticAnalysisService`.

That path supports:

- generated high-FPS moving-dot metadata and observations.
- manual linear side-on calibration.
- initial ball-point review.
- manual observation editing, adding, deleting, acceptance toggling, and uncertainty toggling.
- timestamp-based speed estimation.
- confidence and warning generation.
- annotated trajectory replay.
- local result saving.

The analysis controller initializes with the synthetic fixture, so route-level tests and debug builds have a complete path without requiring real video files.

## Calibration and Tracking Correction

Calibration is a manual side-on linear model. `CalibrationScreen` lets the user place two points on a known visible distance and enter metres. `CalibrationMath.createLinear()` rejects out-of-frame points, too-short pixel distances, non-positive distances, and invalid metres-per-pixel values.

`TrackingCorrectionScreen` lets the user step through observations, edit X/Y ball-center coordinates, add points, reject or accept points, mark uncertainty, and delete points. The trajectory preview is drawn by `TrajectoryPainter`.

These screens currently operate on the loaded synthetic model or imported metadata dimensions, not decoded imported-video frames.

## Speed Estimation

There are separate estimators for live and recorded-style workflows:

- `LiveSpeedDetector` estimates speed from guide-line crossings and elapsed time in the live camera preview.
- `ArDepthSpeedEstimator` estimates speed from consecutive 3D world-position samples, but native sample production is not implemented.
- `SpeedEstimator` calculates release and average speed from projected ball observations in the manual analysis workflow.

`SpeedEstimator` requires:

- nominal FPS of at least 60.
- stable and ordered timestamps.
- camera motion score at or below the configured limit.
- at least four accepted, real, non-occluded observations above the confidence threshold.
- a minimum tracked time window.

It projects points onto the calibration line, converts pixels to metres, rejects velocity outliers, fits linear regression slopes, computes a likely speed range from residual error, and assigns `high`, `medium`, `low`, or `failed` confidence. Failure results hide speed values.

## Results, Replay, and History

`ResultsScreen` shows release speed in km/h and mph when confidence is not failed, plus likely range, average tracked speed, source FPS, calibration distance, observation counts, and warnings. Users can save the current result locally.

`ReplayScreen` shows an annotated trajectory progression over the observation list. It is a custom-painted analysis replay, not decoded video playback.

`HistoryScreen` reads saved results from `AppDatabase`, a Drift database named `pacelens`. Stored fields include video URI, source FPS, calibration distance, release and average speed, confidence, and warning messages. Video bytes are not stored.

## Tests Covering Features

Current tests cover:

- home/import/recording route flow and warning copy in `test/widgets/app_flow_test.dart`;
- guide-line live speed detection, direction handling, noisy crossings, distance validation, and full-scene movement rejection in `test/core/live_speed_detector_test.dart`;
- OpenCV changed-pixel centroid and coverage detection in `test/core/open_cv_motion_tracker_test.dart`;
- AR-depth capability parsing/channel errors and AR-depth speed estimation in `test/core/ar_depth_platform_test.dart` and `test/core/ar_depth_speed_estimator_test.dart`;
- speed estimation across synthetic speeds, noisy/outlier data, low FPS warning, duplicate timestamps, insufficient observations, interpolated point exclusion, and reversed movement in `test/core/speed_estimator_test.dart`;
- video inspection payload parsing and support checks in `test/core/video_inspection_result_test.dart`;
- calibration math and unit conversion in `test/core/calibration_math_test.dart`.

Run `flutter test` and `flutter analyze` before changing feature behavior.

## Known Gaps

- Imported-video frame extraction is not implemented.
- Imported-video calibration, ball selection, tracking correction, and replay do not yet show real decoded frames.
- Native high-speed recording is a capability-query stub, not a recording implementation.
- Native AR-depth sampling is not implemented.
- Automatic cricket-ball tracking for imported footage has interfaces and low-level motion utilities but no production UI workflow.
- Replay uses drawn trajectory data rather than actual video frames.
- History has a list view but no detail/export/report flow.
