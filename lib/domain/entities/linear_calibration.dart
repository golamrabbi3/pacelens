import 'dart:math' as math;
import 'dart:ui';

class LinearCalibration {
  const LinearCalibration({
    required this.pointA,
    required this.pointB,
    required this.knownDistanceMetres,
    required this.metresPerPixel,
    required this.directionX,
    required this.directionY,
    required this.confidence,
  });

  final Offset pointA;
  final Offset pointB;
  final double knownDistanceMetres;
  final double metresPerPixel;
  final double directionX;
  final double directionY;
  final double confidence;

  Offset get direction => Offset(directionX, directionY);
  double get pixelDistance => (pointB - pointA).distance;

  static LinearCalibration fromPoints({
    required Offset pointA,
    required Offset pointB,
    required double knownDistanceMetres,
    Size? frameSize,
  }) {
    final delta = pointB - pointA;
    final pixelDistance = delta.distance;
    if (pixelDistance <= 0 || !pixelDistance.isFinite) {
      throw const FormatException('Calibration points must be distinct.');
    }
    if (knownDistanceMetres <= 0 || !knownDistanceMetres.isFinite) {
      throw const FormatException('Calibration distance must be positive.');
    }
    final directionX = delta.dx / pixelDistance;
    final directionY = delta.dy / pixelDistance;
    final metresPerPixel = knownDistanceMetres / pixelDistance;
    final confidence = _confidenceFor(
      pixelDistance,
      knownDistanceMetres,
      frameSize,
    );
    return LinearCalibration(
      pointA: pointA,
      pointB: pointB,
      knownDistanceMetres: knownDistanceMetres,
      metresPerPixel: metresPerPixel,
      directionX: directionX,
      directionY: directionY,
      confidence: confidence,
    );
  }

  static double _confidenceFor(
    double pixelDistance,
    double knownDistanceMetres,
    Size? frameSize,
  ) {
    final lengthScore = (pixelDistance / 400).clamp(0.25, 1.0);
    final distanceScore = (knownDistanceMetres / 10).clamp(0.25, 1.0);
    var edgeScore = 1.0;
    if (frameSize != null) {
      final diagonal = math.sqrt(
        frameSize.width * frameSize.width + frameSize.height * frameSize.height,
      );
      edgeScore = (pixelDistance / (diagonal * 0.3)).clamp(0.25, 1.0);
    }
    return math.min(lengthScore, math.min(distanceScore, edgeScore)).toDouble();
  }
}
