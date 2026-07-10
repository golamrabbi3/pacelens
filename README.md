# PaceLens

PaceLens is a Flutter MVP for estimating cricket-ball speed from mobile phone video using local processing only.

**PaceLens provides an experimental camera-based cricket-ball speed estimate. Results depend on camera placement, frame rate, lighting, calibration, timestamp quality, tracking accuracy, and perspective. It is not a certified radar-speed measurement system.**

## Current vertical slice

This project currently proves the manual-analysis pipeline before automatic tracking:

1. Synthetic high-FPS moving-dot video fixture.
2. Manual linear side-on calibration.
3. Manual ball-point correction.
4. Timestamp-based speed calculation.
5. Confidence and warning generation.
6. Annotated replay.
7. Drift-backed local result history.
8. Android/iOS native capability channels for high-speed camera profile queries.
9. Local video selection and native imported-video metadata/timestamp inspection.

The app does not use cloud APIs, hosted AI services, analytics SDKs, accounts, or internet permission.

## Architecture

```text
lib/
├── app/                 # Material app, router, theme
├── core/
│   ├── errors/          # Explicit analysis errors
│   ├── math/            # Calibration, projection, statistics, units
│   ├── platform/        # High-speed camera platform channel interface
│   └── storage/         # Drift database
├── domain/
│   ├── entities/        # Camera, video, calibration, observations, results
│   └── services/        # Speed estimator, tracker and frame-source contracts
└── features/            # Home, setup, calibration, selection, correction, replay, history
```

Native code lives in `android/` and `ios/`.

For a route-by-route inventory of implemented features, current MVP limits, and test coverage, see [`FEATURES.md`](FEATURES.md).

## Platform capability model

Flutter does not assume that one camera plugin exposes identical high-speed capture on every device.

Android uses a Kotlin `MethodChannel` backed by Camera2 capability queries. It enumerates back-camera 60 FPS or higher profiles and marks constrained high-speed profiles where Camera2 exposes them.

iOS uses a Swift `MethodChannel` backed by AVFoundation format/frame-rate-range enumeration.

Recording commands currently return explicit unsupported errors. Full recording should be implemented with:

- Android: Camera2 constrained high-speed capture, MediaCodec/MediaExtractor timestamps, sensors for motion score.
- iOS: AVFoundation frame-duration configuration, CMSampleBuffer timestamps, Core Motion stability scoring.

The import screen uses `file_selector` to choose a local video. Android inspects the selected video with `MediaMetadataRetriever` and `MediaExtractor`; iOS inspects it with `AVAsset` and `AVAssetReader`. Both native paths sample presentation timestamps and report:

- duration
- resolution
- nominal or computed FPS
- sampled frame count
- monotonic timestamp status
- duplicated timestamp status
- irregular frame spacing warnings
- below-120-FPS and below-60-FPS warnings

Do not pass full-resolution video frames continuously through `MethodChannel`.

## Running

```sh
flutter pub get
dart run build_runner build
flutter test
flutter run
```

## Known limitations

- Real high-speed recording is not complete.
- Imported video metadata and timestamp inspection is complete; imported-video frame extraction and calibration from real decoded frames is not complete.
- Automatic classical ball tracking is not complete.
- The synthetic debug path is the working MVP path.
- Linear calibration assumes a stationary side-on camera and ball movement approximately parallel to the calibration line.
- No 3D reconstruction or broadcast-footage analysis is attempted.
- Speeds are hidden when confidence is failed.

## Privacy

Processing is local. Video bytes are not stored inside the database. Android does not declare internet permission, and iOS does not add networking entitlements.
