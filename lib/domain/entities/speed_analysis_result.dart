enum AnalysisConfidence { high, medium, low, failed }

class AnalysisWarning {
  const AnalysisWarning(this.message);

  final String message;
}

class SpeedAnalysisResult {
  const SpeedAnalysisResult({
    required this.releaseSpeedKph,
    required this.releaseSpeedMph,
    required this.averageSpeedKph,
    required this.averageSpeedMph,
    required this.minimumLikelySpeedKph,
    required this.maximumLikelySpeedKph,
    required this.confidence,
    required this.observationsUsed,
    required this.rejectedObservations,
    required this.warnings,
  });

  final double? releaseSpeedKph;
  final double? releaseSpeedMph;
  final double? averageSpeedKph;
  final double? averageSpeedMph;
  final double? minimumLikelySpeedKph;
  final double? maximumLikelySpeedKph;
  final AnalysisConfidence confidence;
  final int observationsUsed;
  final int rejectedObservations;
  final List<AnalysisWarning> warnings;

  bool get hasSpeed =>
      confidence != AnalysisConfidence.failed && releaseSpeedKph != null;
}
