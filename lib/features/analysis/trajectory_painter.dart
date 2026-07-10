import 'package:flutter/material.dart';

import '../../domain/entities/ball_observation.dart';
import '../../domain/entities/linear_calibration.dart';

class TrajectoryPainter extends CustomPainter {
  const TrajectoryPainter({
    required this.observations,
    required this.calibration,
    this.highlightFrameIndex,
  });

  final List<BallObservation> observations;
  final LinearCalibration? calibration;
  final int? highlightFrameIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 1280;
    final scaleY = size.height / 720;
    Offset map(Offset p) => Offset(p.dx * scaleX, p.dy * scaleY);

    final pitchPaint = Paint()
      ..color = const Color(0xff1d2a24)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, pitchPaint);

    final lanePaint = Paint()
      ..color = const Color(0xff456052)
      ..strokeWidth = 2;
    for (
      var y = size.height * 0.25;
      y <= size.height * 0.75;
      y += size.height * 0.25
    ) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lanePaint);
    }

    final calibrationValue = calibration;
    if (calibrationValue != null) {
      final calibrationPaint = Paint()
        ..color = Colors.cyanAccent
        ..strokeWidth = 3;
      canvas.drawLine(
        map(calibrationValue.pointA),
        map(calibrationValue.pointB),
        calibrationPaint,
      );
    }

    final accepted = observations
        .where((observation) => observation.isAccepted)
        .toList();
    if (accepted.length > 1) {
      final path = Path()
        ..moveTo(
          map(accepted.first.imagePoint).dx,
          map(accepted.first.imagePoint).dy,
        );
      for (final observation in accepted.skip(1)) {
        path.lineTo(
          map(observation.imagePoint).dx,
          map(observation.imagePoint).dy,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.yellowAccent
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    for (final observation in observations) {
      final point = map(observation.imagePoint);
      final isHighlighted = observation.frameIndex == highlightFrameIndex;
      final color = !observation.isAccepted
          ? Colors.redAccent
          : observation.source == ObservationSource.manual
          ? Colors.lightGreenAccent
          : Colors.orangeAccent;
      canvas.drawCircle(
        point,
        isHighlighted ? 7 : 5,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        point,
        isHighlighted ? 10 : 8,
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TrajectoryPainter oldDelegate) {
    return oldDelegate.observations != observations ||
        oldDelegate.calibration != calibration ||
        oldDelegate.highlightFrameIndex != highlightFrameIndex;
  }
}
