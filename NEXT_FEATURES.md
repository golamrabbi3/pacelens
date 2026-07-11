# Next Feature Roadmap

This roadmap is based on the current PaceLens implementation documented in `FEATURES.md`. The app now has a live calibrated guide-line speed test, native imported-video timestamp inspection, and a synthetic manual analysis flow. The main priority is still turning imported-video inspection into real frame-backed analysis, while hardening the live test that already exists.

## Priority 1: Complete Imported-Video Analysis

### Decode Frames From Imported Videos

Extract real frames after `NativeVideoInspector.inspect()` succeeds.

- Implement a platform-backed `VideoFrameSource`.
- Return selected frames or compact thumbnails without continuously streaming full-resolution video through `MethodChannel`.
- Preserve native presentation timestamps for every decoded frame.
- Acceptance: imported videos can show real frame imagery in calibration, ball selection, tracking, and replay screens.

### Calibrate On Real Video Frames

Replace the synthetic 1280x720 drawing surface with the selected video frame size and imagery.

- Display a decoded frame in `CalibrationScreen`.
- Store calibration against actual video dimensions.
- Keep the current side-on linear calibration validation.
- Acceptance: users can tap known-distance endpoints on imported footage.

### Select The Ball On A Real Release Frame

Let users choose the release frame and tap the ball center.

- Add frame step controls or a simple scrubber around the release moment.
- Save the first real `BallObservation` from user input.
- Show timestamp and frame index while selecting.
- Acceptance: imported-video analysis no longer depends on synthetic observations.

## Priority 2: Manual Tracking On Real Frames

### Frame-by-Frame Correction UI

Use decoded video frames while editing observation points.

- Add previous/next frame navigation.
- Support tap-to-place ball center instead of numeric-only editing.
- Keep accept/reject/uncertain/delete controls.
- Acceptance: users can manually create a valid observation set from imported footage.

### Frame-Backed Replay

Replace drawn-only replay with sampled frames plus annotation overlays.

- Overlay trajectory and highlighted ball point on actual frames.
- Reuse `TrajectoryPainter` for annotation layers.
- Keep playback lightweight by sampling or caching frames intentionally.
- Acceptance: replay visually verifies the measured delivery against the source video.

## Priority 3: Harden The Live Speed Test

### Live Measurement Diagnostics

Expose why the live guide-line test is waiting, rejected, or complete.

- Show distance validation, movement coverage, detected direction, and elapsed crossing time.
- Add clearer warnings for poor lighting, too much scene movement, and missed guide-line crossings.
- Acceptance: users can understand and correct failed live attempts without reading logs.

### Save Live Results

Let the existing live result flow write to history.

- Add a local result record type or metadata flag for live guide-line measurements.
- Store distance, elapsed time, direction, speed, and warning context.
- Keep the current privacy rule: no video bytes stored.
- Acceptance: completed live speed tests can be reviewed later in `HistoryScreen`.

## Priority 4: Automatic Tracking Assistance

### Classical Imported-Video Ball Tracker

Implement a non-cloud tracker behind `BallTracker`.

- Start with template matching or frame differencing around the manually selected ball.
- Use manual corrections as override points.
- Mark low-confidence, occluded, or interpolated observations explicitly.
- Acceptance: the app proposes an imported-video trajectory that users can correct before calculation.

### Tracking Quality Diagnostics

Expose quality warnings before results.

- Flag too few points, large sideways residual, irregular spacing, low confidence, and rejected outliers.
- Show which points were excluded from the final estimate.
- Acceptance: users understand why an estimate failed or degraded.

## Priority 5: Native Capture And AR Depth

### Native High-Speed Recording

Implement device-specific recording after imported-video analysis is reliable.

- Android: Camera2 constrained high-speed capture with preserved timestamps.
- iOS: AVFoundation high-frame-rate capture with configured frame duration.
- Record motion/stability score when available.
- Acceptance: supported devices can record footage usable by the same import/analysis pipeline.

### AR-Depth Sampling

Turn the current AR-depth contracts into a real native sampling path.

- Android: implement ARCore depth/world-position sampling or keep unsupported with a stricter platform gate.
- iOS: implement ARKit scene-depth/world-position sampling where supported.
- Feed native samples into `ArDepthSpeedEstimator`.
- Acceptance: AR-depth mode can produce tested samples on at least one supported device class, or it is hidden until supported.

## Priority 6: Accuracy, Validation, And Reporting

### Measurement Validation Suite

Add repeatable fixtures for known-speed clips and edge cases.

- Include low FPS, duplicated timestamps, dropped frames, re-encoded video, noisy tracking, and poor side-on calibration fixtures.
- Expand tests around `SpeedEstimator`, frame extraction, calibration, and inspection parsing.
- Acceptance: estimator and frame-source changes are checked against known expected ranges.

### History Detail And Export

Add a detail/report flow for saved results.

- Show warnings, calibration distance, source URI, confidence, timestamp diagnostics, and live-measurement metadata where applicable.
- Export a simple local report with speed, confidence, warnings, FPS/frame count, and calibration context.
- Do not include video bytes unless that is explicitly added later.
- Acceptance: users can review or share the measurement context, not just the final speed.

## Suggested Build Order

1. Imported-video frame extraction.
2. Real-frame calibration.
3. Manual ball selection and correction on real frames.
4. Frame-backed replay.
5. Live measurement diagnostics and history saving.
6. Classical imported-video tracker assistance.
7. Native high-speed recording.
8. AR-depth sampling only after a real supported-device implementation is chosen.
