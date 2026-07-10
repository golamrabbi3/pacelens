import 'speed_analysis_result.dart';

class DeliveryResultRecord {
  const DeliveryResultRecord({
    required this.id,
    required this.createdAt,
    required this.videoUri,
    required this.sourceFps,
    required this.calibrationDistanceMetres,
    required this.releaseSpeedKph,
    required this.averageSpeedKph,
    required this.confidence,
    required this.warnings,
  });

  final String id;
  final DateTime createdAt;
  final Uri videoUri;
  final double sourceFps;
  final double calibrationDistanceMetres;
  final double? releaseSpeedKph;
  final double? averageSpeedKph;
  final AnalysisConfidence confidence;
  final List<String> warnings;
}
