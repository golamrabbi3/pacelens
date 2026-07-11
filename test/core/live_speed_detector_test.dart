import 'package:flutter_test/flutter_test.dart';
import 'package:pacelens/domain/services/live_speed_detector.dart';

void main() {
  group('LiveSpeedDetector', () {
    test('estimates left-to-right speed from guide-line crossings', () {
      final detector = LiveSpeedDetector();

      var update = detector.observeMotion(
        normalizedX: 0.2,
        coverage: 0.02,
        timestamp: Duration.zero,
        distanceMetres: 20,
      );

      expect(update.state, LiveSpeedDetectionState.waitingForStart);
      expect(update.speedKph, isNull);

      update = detector.observeMotion(
        normalizedX: 0.8,
        coverage: 0.02,
        timestamp: const Duration(milliseconds: 500),
        distanceMetres: 20,
      );

      expect(update.state, LiveSpeedDetectionState.complete);
      expect(update.shouldStop, isTrue);
      expect(update.direction, LiveSpeedDirection.leftToRight);
      expect(update.elapsed, const Duration(milliseconds: 500));
      expect(update.speedKph, closeTo(144, 0.001));
      expect(update.speedMph, closeTo(89.477, 0.001));
    });

    test('estimates right-to-left speed from guide-line crossings', () {
      final detector = LiveSpeedDetector();

      detector.observeMotion(
        normalizedX: 0.8,
        coverage: 0.02,
        timestamp: Duration.zero,
        distanceMetres: 18,
      );
      final update = detector.observeMotion(
        normalizedX: 0.2,
        coverage: 0.02,
        timestamp: const Duration(milliseconds: 600),
        distanceMetres: 18,
      );

      expect(update.state, LiveSpeedDetectionState.complete);
      expect(update.direction, LiveSpeedDirection.rightToLeft);
      expect(update.speedKph, closeTo(108, 0.001));
    });

    test('does not report left-to-right for right-to-left motion', () {
      final detector = LiveSpeedDetector();

      var update = detector.observeMotion(
        normalizedX: 0.8,
        coverage: 0.02,
        timestamp: Duration.zero,
        distanceMetres: 18,
      );
      expect(update.state, LiveSpeedDetectionState.waitingForStart);

      update = detector.observeMotion(
        normalizedX: 0.65,
        coverage: 0.02,
        timestamp: const Duration(milliseconds: 100),
        distanceMetres: 18,
      );
      expect(update.state, LiveSpeedDetectionState.tracking);
      expect(update.direction, LiveSpeedDirection.rightToLeft);
      expect(
        update.statusMessage,
        'Tracking from right guide to left guide...',
      );

      update = detector.observeMotion(
        normalizedX: 0.2,
        coverage: 0.02,
        timestamp: const Duration(milliseconds: 600),
        distanceMetres: 18,
      );
      expect(update.state, LiveSpeedDetectionState.complete);
      expect(update.direction, LiveSpeedDirection.rightToLeft);
      expect(update.speedKph, closeTo(108, 0.001));
    });

    test('accepts motion first detected just after the guide line', () {
      final detector = LiveSpeedDetector();

      var update = detector.observeMotion(
        normalizedX: 0.31,
        coverage: 0.02,
        timestamp: Duration.zero,
        distanceMetres: 20,
      );
      expect(update.state, LiveSpeedDetectionState.waitingForStart);

      update = detector.observeMotion(
        normalizedX: 0.38,
        coverage: 0.02,
        timestamp: const Duration(milliseconds: 100),
        distanceMetres: 20,
      );
      expect(update.state, LiveSpeedDetectionState.tracking);
      expect(update.direction, LiveSpeedDirection.leftToRight);

      update = detector.observeMotion(
        normalizedX: 0.68,
        coverage: 0.02,
        timestamp: const Duration(milliseconds: 500),
        distanceMetres: 20,
      );
      expect(update.state, LiveSpeedDetectionState.complete);
      expect(update.direction, LiveSpeedDirection.leftToRight);
      expect(update.speedMph, closeTo(89.477, 0.001));
    });

    test('uses moving-object bounds when the center does not cross guides', () {
      final detector = LiveSpeedDetector();

      var update = detector.observeMotion(
        normalizedX: 0.40,
        normalizedLeftX: 0.24,
        normalizedRightX: 0.56,
        coverage: 0.08,
        timestamp: Duration.zero,
        distanceMetres: 20,
      );
      expect(update.state, LiveSpeedDetectionState.waitingForStart);

      update = detector.observeMotion(
        normalizedX: 0.46,
        normalizedLeftX: 0.30,
        normalizedRightX: 0.62,
        coverage: 0.08,
        timestamp: const Duration(milliseconds: 100),
        distanceMetres: 20,
      );
      expect(update.state, LiveSpeedDetectionState.tracking);
      expect(update.direction, LiveSpeedDirection.leftToRight);

      update = detector.observeMotion(
        normalizedX: 0.60,
        normalizedLeftX: 0.50,
        normalizedRightX: 0.70,
        coverage: 0.08,
        timestamp: const Duration(milliseconds: 500),
        distanceMetres: 20,
      );
      expect(update.state, LiveSpeedDetectionState.complete);
      expect(update.direction, LiveSpeedDirection.leftToRight);
      expect(update.speedKph, closeTo(144, 0.001));
    });

    test('uses right-to-left bounds when the center does not cross guides', () {
      final detector = LiveSpeedDetector();

      var update = detector.observeMotion(
        normalizedX: 0.60,
        normalizedLeftX: 0.44,
        normalizedRightX: 0.76,
        coverage: 0.08,
        timestamp: Duration.zero,
        distanceMetres: 18,
      );
      expect(update.state, LiveSpeedDetectionState.waitingForStart);

      update = detector.observeMotion(
        normalizedX: 0.54,
        normalizedLeftX: 0.38,
        normalizedRightX: 0.70,
        coverage: 0.08,
        timestamp: const Duration(milliseconds: 100),
        distanceMetres: 18,
      );
      expect(update.state, LiveSpeedDetectionState.tracking);
      expect(update.direction, LiveSpeedDirection.rightToLeft);

      update = detector.observeMotion(
        normalizedX: 0.40,
        normalizedLeftX: 0.30,
        normalizedRightX: 0.50,
        coverage: 0.08,
        timestamp: const Duration(milliseconds: 600),
        distanceMetres: 18,
      );
      expect(update.state, LiveSpeedDetectionState.complete);
      expect(update.direction, LiveSpeedDirection.rightToLeft);
      expect(update.speedKph, closeTo(108, 0.001));
    });

    test('does not complete on an implausibly fast noisy crossing', () {
      final detector = LiveSpeedDetector();

      detector.observeMotion(
        normalizedX: 0.24,
        normalizedLeftX: 0.20,
        normalizedRightX: 0.28,
        coverage: 0.02,
        timestamp: Duration.zero,
        distanceMetres: 20,
      );
      final update = detector.observeMotion(
        normalizedX: 0.76,
        normalizedLeftX: 0.72,
        normalizedRightX: 0.80,
        coverage: 0.02,
        timestamp: const Duration(milliseconds: 80),
        distanceMetres: 20,
      );

      expect(update.state, LiveSpeedDetectionState.tracking);
      expect(update.speedKph, isNull);
    });

    test(
      'accepts right-to-left motion first detected just after the guide line',
      () {
        final detector = LiveSpeedDetector();

        var update = detector.observeMotion(
          normalizedX: 0.69,
          coverage: 0.02,
          timestamp: Duration.zero,
          distanceMetres: 18,
        );
        expect(update.state, LiveSpeedDetectionState.waitingForStart);

        update = detector.observeMotion(
          normalizedX: 0.62,
          coverage: 0.02,
          timestamp: const Duration(milliseconds: 100),
          distanceMetres: 18,
        );
        expect(update.state, LiveSpeedDetectionState.tracking);
        expect(update.direction, LiveSpeedDirection.rightToLeft);

        update = detector.observeMotion(
          normalizedX: 0.32,
          coverage: 0.02,
          timestamp: const Duration(milliseconds: 600),
          distanceMetres: 18,
        );
        expect(update.state, LiveSpeedDetectionState.complete);
        expect(update.direction, LiveSpeedDirection.rightToLeft);
        expect(update.speedKph, closeTo(108, 0.001));
      },
    );

    test('waits until motion starts outside a guide line', () {
      final detector = LiveSpeedDetector();

      final update = detector.observeMotion(
        normalizedX: 0.5,
        coverage: 0.02,
        timestamp: Duration.zero,
        distanceMetres: 20,
      );

      expect(update.state, LiveSpeedDetectionState.waitingForStart);
      expect(update.speedKph, isNull);
    });

    test('accepts larger moving objects but rejects full-scene motion', () {
      final detector = LiveSpeedDetector();

      final invalidDistance = detector.observeMotion(
        normalizedX: 0.2,
        coverage: 0.02,
        timestamp: Duration.zero,
        distanceMetres: 0,
      );
      expect(invalidDistance.state, LiveSpeedDetectionState.invalidDistance);

      final largerObject = detector.observeMotion(
        normalizedX: 0.2,
        coverage: 0.5,
        timestamp: Duration.zero,
        distanceMetres: 20,
      );
      expect(largerObject.state, LiveSpeedDetectionState.waitingForStart);

      final tooMuchMotion = detector.observeMotion(
        normalizedX: 0.2,
        coverage: 0.8,
        timestamp: Duration.zero,
        distanceMetres: 20,
      );
      expect(tooMuchMotion.state, LiveSpeedDetectionState.tooMuchMotion);
    });
  });
}
