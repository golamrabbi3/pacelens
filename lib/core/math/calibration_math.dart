import 'dart:math' as math;
import 'dart:ui';

import '../../core/errors/analysis_error.dart';
import '../../domain/entities/linear_calibration.dart';

class CalibrationMath {
  const CalibrationMath._();

  static LinearCalibration createLinear({
    required Offset pointA,
    required Offset pointB,
    required double knownDistanceMetres,
    required Size frameSize,
  }) {
    if (!_insideFrame(pointA, frameSize) || !_insideFrame(pointB, frameSize)) {
      throw const InvalidCalibration();
    }
    final pixelDistance = (pointB - pointA).distance;
    if (pixelDistance < 40 || knownDistanceMetres <= 0) {
      throw const InvalidCalibration();
    }
    final metresPerPixel = knownDistanceMetres / pixelDistance;
    if (!metresPerPixel.isFinite || metresPerPixel <= 0 || metresPerPixel > 1) {
      throw const InvalidCalibration();
    }
    try {
      return LinearCalibration.fromPoints(
        pointA: pointA,
        pointB: pointB,
        knownDistanceMetres: knownDistanceMetres,
        frameSize: frameSize,
      );
    } on FormatException {
      throw const InvalidCalibration();
    }
  }

  static double projectPixels(Offset point, LinearCalibration calibration) {
    final relative = point - calibration.pointA;
    return relative.dx * calibration.directionX +
        relative.dy * calibration.directionY;
  }

  static double projectedDisplacementPixels(
    Offset from,
    Offset to,
    LinearCalibration calibration,
  ) {
    return projectPixels(to, calibration) - projectPixels(from, calibration);
  }

  static double pixelsToMetres(double pixels, LinearCalibration calibration) {
    return pixels * calibration.metresPerPixel;
  }

  static double secondsBetween(Duration a, Duration b) {
    return (b.inMicroseconds - a.inMicroseconds) /
        Duration.microsecondsPerSecond;
  }

  static bool _insideFrame(Offset point, Size frameSize) {
    return point.dx >= 0 &&
        point.dy >= 0 &&
        point.dx <= frameSize.width &&
        point.dy <= frameSize.height &&
        point.dx.isFinite &&
        point.dy.isFinite &&
        math.max(frameSize.width, frameSize.height) > 0;
  }
}
