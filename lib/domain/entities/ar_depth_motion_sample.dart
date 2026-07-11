import 'dart:math' as math;

class ArDepthMotionSample {
  const ArDepthMotionSample({
    required this.timestamp,
    required this.xMetres,
    required this.yMetres,
    required this.zMetres,
    required this.confidence,
    required this.trackingState,
  });

  final Duration timestamp;
  final double xMetres;
  final double yMetres;
  final double zMetres;
  final double confidence;
  final String trackingState;

  factory ArDepthMotionSample.fromMap(Map<Object?, Object?> map) {
    final timestampUs = (map['timestampUs'] as num?)?.toInt();
    final x = (map['xMetres'] as num?)?.toDouble();
    final y = (map['yMetres'] as num?)?.toDouble();
    final z = (map['zMetres'] as num?)?.toDouble();
    final confidence = (map['confidence'] as num?)?.toDouble();
    if (timestampUs == null ||
        timestampUs < 0 ||
        x == null ||
        y == null ||
        z == null ||
        confidence == null ||
        !x.isFinite ||
        !y.isFinite ||
        !z.isFinite ||
        !confidence.isFinite) {
      throw const FormatException('Invalid AR depth motion sample.');
    }
    return ArDepthMotionSample(
      timestamp: Duration(microseconds: timestampUs),
      xMetres: x,
      yMetres: y,
      zMetres: z,
      confidence: confidence.clamp(0, 1),
      trackingState: map['trackingState']?.toString() ?? 'unknown',
    );
  }

  double distanceTo(ArDepthMotionSample other) {
    final dx = other.xMetres - xMetres;
    final dy = other.yMetres - yMetres;
    final dz = other.zMetres - zMetres;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }
}
