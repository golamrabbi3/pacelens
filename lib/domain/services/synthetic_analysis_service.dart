import 'dart:math' as math;
import 'dart:ui';

import '../entities/ball_observation.dart';
import '../entities/linear_calibration.dart';
import '../entities/video_frame.dart';

class SyntheticAnalysisFixture {
  const SyntheticAnalysisFixture({
    required this.metadata,
    required this.calibration,
    required this.observations,
    required this.expectedMetresPerSecond,
  });

  final VideoMetadata metadata;
  final LinearCalibration calibration;
  final List<BallObservation> observations;
  final double expectedMetresPerSecond;
}

class SyntheticAnalysisService {
  const SyntheticAnalysisService();

  SyntheticAnalysisFixture generate({
    double metresPerSecond = 30,
    double fps = 120,
    double metresPerPixel = 0.02,
    int frameCount = 18,
    double noisePixels = 1.1,
    bool includeOutlier = true,
    bool includeDroppedFrame = true,
  }) {
    final calibration = LinearCalibration.fromPoints(
      pointA: const Offset(100, 360),
      pointB: const Offset(600, 360),
      knownDistanceMetres: 10,
      frameSize: const Size(1280, 720),
    );
    final random = math.Random(7);
    final observations = <BallObservation>[];
    for (var frame = 0; frame < frameCount; frame++) {
      if (includeDroppedFrame && frame == 9) {
        continue;
      }
      final seconds = frame / fps;
      var x = 160 + (metresPerSecond * seconds) / metresPerPixel;
      var y = 360 + math.sin(frame / 2) * 1.8;
      x += (random.nextDouble() - 0.5) * noisePixels;
      y += (random.nextDouble() - 0.5) * noisePixels;
      var confidence = 0.88;
      if (includeOutlier && frame == 12) {
        x += 42;
        y += 24;
        confidence = 0.35;
      }
      observations.add(
        BallObservation(
          frameIndex: frame,
          timestamp: Duration(
            microseconds: (seconds * Duration.microsecondsPerSecond).round(),
          ),
          imagePoint: Offset(x, y),
          confidence: confidence,
          source: ObservationSource.manual,
          isAccepted: true,
          isUncertain: confidence < 0.5,
        ),
      );
    }

    return SyntheticAnalysisFixture(
      metadata: VideoMetadata(
        uri: Uri.parse('synthetic://moving-dot-30ms'),
        width: 1280,
        height: 720,
        nominalFps: fps,
        duration: Duration(
          microseconds: ((frameCount - 1) / fps * 1000000).round(),
        ),
        hasStableTimestamps: true,
        isLikelyReencoded: false,
      ),
      calibration: calibration,
      observations: observations,
      expectedMetresPerSecond: metresPerSecond,
    );
  }
}
