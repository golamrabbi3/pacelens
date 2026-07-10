# Next Feature Roadmap

This roadmap is based on the current PaceLens implementation documented in `FEATURES.md`. The main priority is turning the existing synthetic/manual analysis pipeline into a real imported-video workflow before expanding into native recording or advanced automation.

## Priority 1: Complete Imported-Video Analysis

### Decode Frames From Imported Videos

Extract actual video frames after `NativeVideoInspector.inspect()` succeeds.

- Add platform frame extraction behind `VideoFrameSource`.
- Return selected frames or thumbnails without streaming full-resolution video continuously through `MethodChannel`.
- Acceptance: imported videos can show real frame imagery in calibration, ball selection, tracking, and replay screens.

### Calibrate On Real Video Frames

Replace the current synthetic 1280x720 drawing surface with the selected video frame size and imagery.

- Update `CalibrationScreen` to display a real frame.
- Store calibration against actual metadata dimensions.
- Acceptance: users can tap known-distance endpoints on imported footage.

### Manual Ball Point Selection On Real Frames

Let users pick the ball center on a chosen release frame.

- Add frame scrubber or step controls around the release moment.
- Save the first `BallObservation` from user input.
- Acceptance: imported-video analysis no longer depends on synthetic observations.

## Priority 2: Improve Manual Tracking Workflow

### Frame-by-Frame Correction UI

Show each real frame while editing X/Y observation points.

- Add previous/next frame navigation.
- Support tap-to-place ball center instead of numeric-only editing.
- Keep accept/reject/uncertain controls.
- Acceptance: users can create a valid observation set manually from imported footage.

### Better Replay

Replace drawn-only replay with frame-backed annotated replay.

- Overlay trajectory and highlighted ball point on actual sampled frames.
- Keep current custom painter for annotation layers.
- Acceptance: replay visually verifies the measured delivery.

## Priority 3: Automatic Tracking Assistance

### Classical Ball Tracker

Implement a non-cloud tracker behind `BallTracker`.

- Start with template matching or frame differencing around the manually selected ball.
- Use manual corrections as override points.
- Mark low-confidence, occluded, or interpolated observations explicitly.
- Acceptance: the app proposes a trajectory that users can correct before calculation.

### Tracking Quality Diagnostics

Expose quality warnings before results.

- Flag too few points, large sideways residual, irregular spacing, and low confidence.
- Show which points were rejected by outlier filtering.
- Acceptance: users understand why an estimate failed or degraded.

## Priority 4: Native High-Speed Recording

### Android Recording

Implement Camera2 high-speed capture for supported profiles.

- Use selected `CameraCaptureProfile`.
- Preserve presentation timestamps.
- Record motion/stability score if sensors are available.
- Acceptance: supported Android devices can record footage usable by the existing import/analysis pipeline.

### iOS Recording

Implement AVFoundation high-frame-rate capture.

- Configure active format and frame duration.
- Preserve `CMSampleBuffer` timing.
- Add motion scoring through Core Motion.
- Acceptance: supported iPhones can record directly in app at 60 FPS or higher.

## Priority 5: Accuracy, Validation, and Reporting

### Measurement Validation Suite

Add repeatable fixtures for known-speed clips and edge cases.

- Include low FPS, duplicated timestamps, dropped frames, re-encoded video, and noisy tracking fixtures.
- Expand tests around `SpeedEstimator`, calibration, and inspection parsing.
- Acceptance: estimator changes are checked against known expected ranges.

### Result Export

Allow users to export a simple local report.

- Include speed, confidence, warnings, calibration distance, FPS, frame count, and timestamp diagnostics.
- Do not include video bytes unless explicitly added later.
- Acceptance: users can share or archive the measurement context.

## Priority 6: Product Polish

### Guided Setup Flow

Turn setup instructions into checklist-driven validation.

- Confirm tripod, side-on angle, lighting, FPS, and visible calibration distance.
- Warn before analysis when setup is incomplete.

### History Detail View

Add a detail screen for saved results.

- Show warnings, calibration distance, source URI, confidence, and timestamp diagnostics.
- Optional later: attach replay metadata or exported report path.

## Suggested Build Order

1. Imported-video frame extraction.
2. Real-frame calibration.
3. Manual ball selection and correction on real frames.
4. Frame-backed replay.
5. Classical tracker assistance.
6. Native recording after imported-video analysis is reliable.
