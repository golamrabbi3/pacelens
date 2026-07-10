import 'dart:ui';

class BallSelection {
  const BallSelection({
    required this.frameIndex,
    required this.timestamp,
    required this.position,
    required this.searchRadiusPixels,
  });

  final int frameIndex;
  final Duration timestamp;
  final Offset position;
  final double searchRadiusPixels;
}
