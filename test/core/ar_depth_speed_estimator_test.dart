import 'package:flutter_test/flutter_test.dart';
import 'package:pacelens/domain/entities/ar_depth_motion_sample.dart';
import 'package:pacelens/domain/services/ar_depth_speed_estimator.dart';

void main() {
  group('ArDepthMotionSample', () {
    test('parses normal samples and measures 3D distance', () {
      final sample = ArDepthMotionSample.fromMap({
        'timestampUs': 500000,
        'xMetres': 0.0,
        'yMetres': 0.0,
        'zMetres': 0.0,
        'confidence': 0.9,
        'trackingState': 'normal',
      });
      final next = ArDepthMotionSample.fromMap({
        'timestampUs': 1000000,
        'xMetres': 3.0,
        'yMetres': 4.0,
        'zMetres': 0.0,
        'confidence': 0.8,
        'trackingState': 'normal',
      });

      expect(sample.timestamp, const Duration(milliseconds: 500));
      expect(sample.distanceTo(next), 5);
    });

    test('rejects missing depth values', () {
      expect(
        () => ArDepthMotionSample.fromMap({
          'timestampUs': 1,
          'xMetres': 0.0,
          'confidence': 0.9,
        }),
        throwsFormatException,
      );
    });
  });

  group('ArDepthSpeedEstimator', () {
    test('calculates mph from consecutive world positions', () {
      final estimator = ArDepthSpeedEstimator();

      var update = estimator.observe(
        const ArDepthMotionSample(
          timestamp: Duration.zero,
          xMetres: 0,
          yMetres: 0,
          zMetres: 0,
          confidence: 0.9,
          trackingState: 'normal',
        ),
      );
      expect(update.state, ArDepthSpeedState.waitingForMotion);

      update = estimator.observe(
        const ArDepthMotionSample(
          timestamp: Duration(seconds: 1),
          xMetres: 10,
          yMetres: 0,
          zMetres: 0,
          confidence: 0.8,
          trackingState: 'normal',
        ),
      );

      expect(update.state, ArDepthSpeedState.tracking);
      expect(update.speedKph, closeTo(36, 0.001));
      expect(update.speedMph, closeTo(22.369, 0.001));
    });

    test('reports low confidence and invalid timestamps', () {
      final estimator = ArDepthSpeedEstimator();

      var update = estimator.observe(
        const ArDepthMotionSample(
          timestamp: Duration.zero,
          xMetres: 0,
          yMetres: 0,
          zMetres: 0,
          confidence: 0.1,
          trackingState: 'limited',
        ),
      );
      expect(update.state, ArDepthSpeedState.lowConfidence);

      update = estimator.observe(
        const ArDepthMotionSample(
          timestamp: Duration.zero,
          xMetres: 1,
          yMetres: 0,
          zMetres: 0,
          confidence: 0.9,
          trackingState: 'normal',
        ),
      );
      expect(update.state, ArDepthSpeedState.invalidTimestamp);
    });
  });
}
