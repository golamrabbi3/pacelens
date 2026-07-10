import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pacelens/core/errors/analysis_error.dart';
import 'package:pacelens/core/math/calibration_math.dart';
import 'package:pacelens/core/math/speed_units.dart';

void main() {
  test('calculates calibration distance and normalized direction', () {
    final calibration = CalibrationMath.createLinear(
      pointA: const Offset(10, 20),
      pointB: const Offset(110, 20),
      knownDistanceMetres: 5,
      frameSize: const Size(200, 100),
    );

    expect(calibration.pixelDistance, 100);
    expect(calibration.metresPerPixel, 0.05);
    expect(calibration.directionX, 1);
    expect(calibration.directionY, 0);
  });

  test(
    'projects point onto calibration line and converts pixels to metres',
    () {
      final calibration = CalibrationMath.createLinear(
        pointA: const Offset(100, 50),
        pointB: const Offset(500, 50),
        knownDistanceMetres: 20,
        frameSize: const Size(640, 360),
      );

      final projected = CalibrationMath.projectPixels(
        const Offset(350, 80),
        calibration,
      );
      expect(projected, 250);
      expect(CalibrationMath.pixelsToMetres(projected, calibration), 12.5);
    },
  );

  test('converts timestamps and speed units', () {
    final seconds = CalibrationMath.secondsBetween(
      const Duration(milliseconds: 100),
      const Duration(milliseconds: 350),
    );

    expect(seconds, 0.25);
    expect(SpeedUnits.metresPerSecondToKph(30), 108);
    expect(SpeedUnits.metresPerSecondToMph(30), closeTo(67.108, 0.001));
  });

  test('rejects invalid calibration', () {
    expect(
      () => CalibrationMath.createLinear(
        pointA: Offset.zero,
        pointB: Offset.zero,
        knownDistanceMetres: 10,
        frameSize: const Size(640, 360),
      ),
      throwsA(isA<InvalidCalibration>()),
    );
  });
}
