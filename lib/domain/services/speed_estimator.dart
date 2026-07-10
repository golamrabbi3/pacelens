import 'dart:math' as math;
import 'dart:ui';

import '../../core/errors/analysis_error.dart';
import '../../core/math/calibration_math.dart';
import '../../core/math/speed_units.dart';
import '../../core/math/statistics.dart';
import '../entities/ball_observation.dart';
import '../entities/linear_calibration.dart';
import '../entities/speed_analysis_result.dart';
import '../entities/video_frame.dart';

class SpeedEstimatorConfig {
  const SpeedEstimatorConfig({
    this.minimumWindow = const Duration(milliseconds: 30),
    this.preferredWindow = const Duration(milliseconds: 90),
    this.minimumRealObservations = 4,
    this.minimumConfidence = 0.45,
    this.maximumCameraMotionScore = 0.6,
  });

  final Duration minimumWindow;
  final Duration preferredWindow;
  final int minimumRealObservations;
  final double minimumConfidence;
  final double maximumCameraMotionScore;
}

class SpeedEstimator {
  const SpeedEstimator({this.config = const SpeedEstimatorConfig()});

  final SpeedEstimatorConfig config;

  SpeedAnalysisResult estimate({
    required LinearCalibration calibration,
    required List<BallObservation> observations,
    required VideoMetadata metadata,
    required double cameraMotionScore,
  }) {
    final warnings = <AnalysisWarning>[];
    if (metadata.nominalFps < 60) {
      return _failed('Video timestamps are not reliable enough.');
    }
    if (metadata.nominalFps < 120) {
      warnings.add(const AnalysisWarning('120 FPS or higher is recommended.'));
    }
    if (!metadata.hasStableTimestamps) {
      return _failed('Video timestamps are not reliable enough.');
    }
    if (cameraMotionScore > config.maximumCameraMotionScore) {
      return _failed('The phone moved during recording.');
    }
    if (cameraMotionScore > 0.25) {
      warnings.add(const AnalysisWarning('The phone moved during recording.'));
    }
    if (calibration.confidence < 0.5) {
      warnings.add(const AnalysisWarning('Use a longer calibration distance.'));
    }

    final sorted = [...observations]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _validateTimestamps(sorted);

    final usable = sorted.where((observation) {
      return observation.isAccepted &&
          observation.isReal &&
          !observation.isOccluded &&
          observation.confidence >= config.minimumConfidence;
    }).toList();

    final rejected = observations.length - usable.length;
    if (usable.length < config.minimumRealObservations) {
      return _failed(
        'The ball was tracked for too few frames.',
        rejectedObservations: rejected,
      );
    }

    final duration = usable.last.timestamp - usable.first.timestamp;
    if (duration < config.minimumWindow) {
      return _failed(
        'The ball was tracked for too few frames.',
        rejectedObservations: rejected,
      );
    }
    if (duration < const Duration(milliseconds: 50)) {
      warnings.add(
        const AnalysisWarning('The ball was tracked for too few frames.'),
      );
    }

    final projected = usable
        .map(
          (observation) => CalibrationMath.projectPixels(
            observation.imagePoint,
            calibration,
          ),
        )
        .toList();
    final projectedMetres = projected
        .map(
          (pixels) => CalibrationMath.pixelsToMetres(
            pixels - projected.first,
            calibration,
          ),
        )
        .toList();
    final seconds = usable
        .map(
          (observation) => CalibrationMath.secondsBetween(
            usable.first.timestamp,
            observation.timestamp,
          ),
        )
        .toList();

    final filteredIndices = _rejectOutliers(seconds, projectedMetres);
    final releaseIndices = filteredIndices.where((index) {
      final elapsed = usable[index].timestamp - usable.first.timestamp;
      return elapsed <= config.preferredWindow ||
          elapsed <= config.minimumWindow;
    }).toList();

    final releaseWindow =
        releaseIndices.length >= config.minimumRealObservations
        ? releaseIndices
        : filteredIndices.take(math.min(filteredIndices.length, 8)).toList();
    if (releaseWindow.length < config.minimumRealObservations) {
      return _failed(
        'The ball was tracked for too few frames.',
        rejectedObservations: rejected + usable.length - filteredIndices.length,
      );
    }

    final releaseSlopeMps = _slopeFor(
      releaseWindow,
      seconds,
      projectedMetres,
    ).abs();
    final averageSlopeMps = _slopeFor(
      filteredIndices,
      seconds,
      projectedMetres,
    ).abs();
    final residualMetres = Statistics.residualRootMeanSquare(
      x: filteredIndices.map((i) => seconds[i]).toList(),
      y: filteredIndices.map((i) => projectedMetres[i]).toList(),
      slope: averageSlopeMps,
    );

    if (filteredIndices.length < 6) {
      warnings.add(
        const AnalysisWarning('The ball was tracked for too few frames.'),
      );
    }
    final totalDisplacement = (projectedMetres.last - projectedMetres.first)
        .abs();
    final sidewaysResidual = _sidewaysResidual(usable, calibration);
    if (sidewaysResidual > 28 || sidewaysResidual > totalDisplacement * 0.25) {
      warnings.add(
        const AnalysisWarning('The camera should be positioned more side-on.'),
      );
    }
    if (metadata.isLikelyReencoded) {
      warnings.add(
        const AnalysisWarning('The imported video may have been re-encoded.'),
      );
    }
    if (filteredIndices.length < usable.length) {
      warnings.add(
        const AnalysisWarning(
          'Some tracking points were rejected as outliers.',
        ),
      );
    }

    final uncertaintyKph = math.max(
      2.0,
      SpeedUnits.metresPerSecondToKph(residualMetres * 18),
    );
    final releaseKph = SpeedUnits.metresPerSecondToKph(releaseSlopeMps);
    final averageKph = SpeedUnits.metresPerSecondToKph(averageSlopeMps);

    return SpeedAnalysisResult(
      releaseSpeedKph: releaseKph,
      releaseSpeedMph: SpeedUnits.metresPerSecondToMph(releaseSlopeMps),
      averageSpeedKph: averageKph,
      averageSpeedMph: SpeedUnits.metresPerSecondToMph(averageSlopeMps),
      minimumLikelySpeedKph: math.max(0, releaseKph - uncertaintyKph),
      maximumLikelySpeedKph: releaseKph + uncertaintyKph,
      confidence: _confidenceFor(
        warnings,
        filteredIndices.length,
        residualMetres,
        metadata.nominalFps,
      ),
      observationsUsed: filteredIndices.length,
      rejectedObservations: rejected + usable.length - filteredIndices.length,
      warnings: warnings,
    );
  }

  List<int> _rejectOutliers(List<double> seconds, List<double> metres) {
    if (seconds.length < 6) {
      return List<int>.generate(seconds.length, (index) => index);
    }
    final velocities = <double>[];
    for (var i = 1; i < seconds.length; i++) {
      final dt = seconds[i] - seconds[i - 1];
      if (dt > 0) {
        velocities.add((metres[i] - metres[i - 1]) / dt);
      }
    }
    final median = Statistics.median(velocities);
    final mad = Statistics.medianAbsoluteDeviation(velocities);
    if (mad == 0) {
      return List<int>.generate(seconds.length, (index) => index);
    }
    final accepted = <int>{0};
    for (var i = 1; i < seconds.length; i++) {
      final dt = seconds[i] - seconds[i - 1];
      if (dt <= 0) {
        continue;
      }
      final velocity = (metres[i] - metres[i - 1]) / dt;
      if ((velocity - median).abs() <= mad * 4.5) {
        accepted.add(i - 1);
        accepted.add(i);
      }
    }
    return accepted.toList()..sort();
  }

  double _slopeFor(
    List<int> indices,
    List<double> seconds,
    List<double> metres,
  ) {
    return Statistics.linearRegressionSlope(
      x: indices.map((i) => seconds[i]).toList(),
      y: indices.map((i) => metres[i]).toList(),
    );
  }

  double _sidewaysResidual(
    List<BallObservation> observations,
    LinearCalibration calibration,
  ) {
    final normal = Offset(-calibration.directionY, calibration.directionX);
    final offsets = observations.map((observation) {
      final relative = observation.imagePoint - calibration.pointA;
      return (relative.dx * normal.dx + relative.dy * normal.dy).abs();
    }).toList();
    return Statistics.median(offsets);
  }

  void _validateTimestamps(List<BallObservation> observations) {
    for (var i = 1; i < observations.length; i++) {
      if (observations[i].timestamp <= observations[i - 1].timestamp) {
        throw const InvalidTimestamps();
      }
    }
    if (observations.length < 3) {
      return;
    }
    final intervals = <double>[];
    for (var i = 1; i < observations.length; i++) {
      intervals.add(
        (observations[i].timestamp - observations[i - 1].timestamp)
            .inMicroseconds
            .toDouble(),
      );
    }
    final median = Statistics.median(intervals);
    if (median <= 0) {
      throw const InvalidTimestamps();
    }
    final mad = Statistics.medianAbsoluteDeviation(intervals);
    if (mad > median * 0.65) {
      throw const InvalidTimestamps();
    }
  }

  AnalysisConfidence _confidenceFor(
    List<AnalysisWarning> warnings,
    int observations,
    double residualMetres,
    double fps,
  ) {
    var score = 3;
    if (fps < 120) {
      score--;
    }
    if (observations < 8) {
      score--;
    }
    if (residualMetres > 0.12) {
      score--;
    }
    if (warnings.length >= 3) {
      score--;
    }
    if (score >= 3) {
      return AnalysisConfidence.high;
    }
    if (score == 2) {
      return AnalysisConfidence.medium;
    }
    return AnalysisConfidence.low;
  }

  SpeedAnalysisResult _failed(String warning, {int rejectedObservations = 0}) {
    return SpeedAnalysisResult(
      releaseSpeedKph: null,
      releaseSpeedMph: null,
      averageSpeedKph: null,
      averageSpeedMph: null,
      minimumLikelySpeedKph: null,
      maximumLikelySpeedKph: null,
      confidence: AnalysisConfidence.failed,
      observationsUsed: 0,
      rejectedObservations: rejectedObservations,
      warnings: [AnalysisWarning(warning)],
    );
  }
}
