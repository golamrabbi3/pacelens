import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pacelens/domain/entities/ball_observation.dart';
import 'package:pacelens/domain/entities/linear_calibration.dart';
import 'package:pacelens/domain/entities/speed_analysis_result.dart';
import 'package:pacelens/domain/entities/video_frame.dart';
import 'package:pacelens/domain/services/speed_estimator.dart';
import 'package:pacelens/domain/services/synthetic_analysis_service.dart';

void main() {
  const estimator = SpeedEstimator();

  test(
    'estimates constant-speed synthetic trajectories at 20, 30, and 40 m/s',
    () {
      for (final speed in [20.0, 30.0, 40.0]) {
        final fixture = const SyntheticAnalysisService().generate(
          metresPerSecond: speed,
          includeOutlier: false,
          includeDroppedFrame: false,
          noisePixels: 0,
        );

        final result = estimator.estimate(
          calibration: fixture.calibration,
          observations: fixture.observations,
          metadata: fixture.metadata,
          cameraMotionScore: 0,
        );

        expect(result.confidence, isNot(AnalysisConfidence.failed));
        expect(result.releaseSpeedKph, closeTo(speed * 3.6, 1.0));
        expect(result.releaseSpeedMph, closeTo(speed * 2.236936, 1.0));
      }
    },
  );

  test('handles dropped frames and noisy observations with an outlier', () {
    final fixture = const SyntheticAnalysisService().generate();

    final result = estimator.estimate(
      calibration: fixture.calibration,
      observations: fixture.observations,
      metadata: fixture.metadata,
      cameraMotionScore: 0.05,
    );

    expect(result.confidence, isNot(AnalysisConfidence.failed));
    expect(result.releaseSpeedKph, closeTo(108, 8));
    expect(result.rejectedObservations, greaterThanOrEqualTo(1));
  });

  test('fails on duplicated timestamps', () {
    final fixture = const SyntheticAnalysisService().generate(
      includeOutlier: false,
    );
    final duplicated = [...fixture.observations];
    duplicated[2] = duplicated[2].copyWith(timestamp: duplicated[1].timestamp);

    expect(
      () => estimator.estimate(
        calibration: fixture.calibration,
        observations: duplicated,
        metadata: fixture.metadata,
        cameraMotionScore: 0,
      ),
      throwsA(anything),
    );
  });

  test('fails when there are too few real observations', () {
    final fixture = const SyntheticAnalysisService().generate();
    final result = estimator.estimate(
      calibration: fixture.calibration,
      observations: fixture.observations.take(3).toList(),
      metadata: fixture.metadata,
      cameraMotionScore: 0,
    );

    expect(result.confidence, AnalysisConfidence.failed);
    expect(
      result.warnings.single.message,
      'The ball was tracked for too few frames.',
    );
  });

  test('degrades confidence below 120 fps', () {
    final fixture = const SyntheticAnalysisService().generate(
      fps: 60,
      includeOutlier: false,
    );
    final result = estimator.estimate(
      calibration: fixture.calibration,
      observations: fixture.observations,
      metadata: VideoMetadata(
        uri: fixture.metadata.uri,
        width: fixture.metadata.width,
        height: fixture.metadata.height,
        nominalFps: 60,
        duration: fixture.metadata.duration,
        hasStableTimestamps: true,
        isLikelyReencoded: false,
      ),
      cameraMotionScore: 0,
    );

    expect(
      result.confidence.index,
      greaterThanOrEqualTo(AnalysisConfidence.medium.index),
    );
    expect(
      result.warnings.map((warning) => warning.message),
      contains('120 FPS or higher is recommended.'),
    );
  });

  test('excludes interpolated points from critical estimate', () {
    final fixture = const SyntheticAnalysisService().generate(
      includeOutlier: false,
    );
    final interpolated = fixture.observations.map((observation) {
      if (observation.frameIndex == 5 || observation.frameIndex == 6) {
        return observation.copyWith(source: ObservationSource.interpolated);
      }
      return observation;
    }).toList();

    final result = estimator.estimate(
      calibration: fixture.calibration,
      observations: interpolated,
      metadata: fixture.metadata,
      cameraMotionScore: 0,
    );

    expect(result.confidence, isNot(AnalysisConfidence.failed));
    expect(result.observationsUsed, lessThan(fixture.observations.length));
  });

  test('supports reversed movement by reporting positive speed', () {
    final calibration = LinearCalibration.fromPoints(
      pointA: const Offset(100, 100),
      pointB: const Offset(500, 100),
      knownDistanceMetres: 8,
      frameSize: const Size(640, 360),
    );
    final observations = List.generate(10, (index) {
      return BallObservation(
        frameIndex: index,
        timestamp: Duration(microseconds: (index / 120 * 1000000).round()),
        imagePoint: Offset(450 - index * 12.5, 100),
        confidence: 0.9,
        source: ObservationSource.manual,
        isAccepted: true,
      );
    });
    final result = estimator.estimate(
      calibration: calibration,
      observations: observations,
      metadata: VideoMetadata(
        uri: Uri.parse('synthetic://reverse'),
        width: 640,
        height: 360,
        nominalFps: 120,
        duration: const Duration(milliseconds: 100),
        hasStableTimestamps: true,
        isLikelyReencoded: false,
      ),
      cameraMotionScore: 0,
    );

    expect(result.releaseSpeedKph, greaterThan(0));
  });
}
