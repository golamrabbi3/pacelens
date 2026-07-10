import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/storage/storage_providers.dart';
import '../../domain/entities/ball_observation.dart';
import '../../domain/entities/delivery_result_record.dart';
import '../../domain/entities/linear_calibration.dart';
import '../../domain/entities/speed_analysis_result.dart';
import '../../domain/entities/video_frame.dart';
import '../../domain/entities/video_inspection_result.dart';
import '../../domain/services/speed_estimator.dart';
import '../../domain/services/synthetic_analysis_service.dart';

export '../../domain/entities/speed_analysis_result.dart';

class AnalysisWorkflowState {
  const AnalysisWorkflowState({
    this.metadata,
    this.calibration,
    this.observations = const [],
    this.result,
    this.cameraMotionScore = 0,
    this.statusMessage = 'No analysis loaded.',
  });

  final VideoMetadata? metadata;
  final LinearCalibration? calibration;
  final List<BallObservation> observations;
  final SpeedAnalysisResult? result;
  final double cameraMotionScore;
  final String statusMessage;

  AnalysisWorkflowState copyWith({
    VideoMetadata? metadata,
    LinearCalibration? calibration,
    List<BallObservation>? observations,
    SpeedAnalysisResult? result,
    double? cameraMotionScore,
    String? statusMessage,
  }) {
    return AnalysisWorkflowState(
      metadata: metadata ?? this.metadata,
      calibration: calibration ?? this.calibration,
      observations: observations ?? this.observations,
      result: result ?? this.result,
      cameraMotionScore: cameraMotionScore ?? this.cameraMotionScore,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

final analysisWorkflowProvider =
    NotifierProvider<AnalysisWorkflowController, AnalysisWorkflowState>(
      AnalysisWorkflowController.new,
    );

class AnalysisWorkflowController extends Notifier<AnalysisWorkflowState> {
  final _uuid = const Uuid();
  final _estimator = const SpeedEstimator();

  @override
  AnalysisWorkflowState build() {
    final fixture = const SyntheticAnalysisService().generate();
    final result = _estimator.estimate(
      calibration: fixture.calibration,
      observations: fixture.observations,
      metadata: fixture.metadata,
      cameraMotionScore: 0.06,
    );
    return AnalysisWorkflowState(
      metadata: fixture.metadata,
      calibration: fixture.calibration,
      observations: fixture.observations,
      result: result,
      cameraMotionScore: 0.06,
      statusMessage: 'Synthetic debug analysis loaded.',
    );
  }

  void resetSynthetic({double metresPerSecond = 30}) {
    final fixture = const SyntheticAnalysisService().generate(
      metresPerSecond: metresPerSecond,
    );
    final result = _estimate(
      fixture.calibration,
      fixture.observations,
      fixture.metadata,
    );
    state = AnalysisWorkflowState(
      metadata: fixture.metadata,
      calibration: fixture.calibration,
      observations: fixture.observations,
      result: result,
      cameraMotionScore: 0.06,
      statusMessage:
          'Synthetic ${metresPerSecond.toStringAsFixed(0)} m/s analysis loaded.',
    );
  }

  void loadImportedVideo(VideoInspectionResult inspection) {
    state = AnalysisWorkflowState(
      metadata: inspection.metadata,
      cameraMotionScore: 0,
      statusMessage: inspection.isSupported
          ? 'Imported video metadata loaded.'
          : 'Imported video is not suitable for analysis.',
    );
  }

  void updateCalibration(LinearCalibration calibration) {
    final metadata = state.metadata;
    if (metadata == null) {
      return;
    }
    final result = _estimate(calibration, state.observations, metadata);
    state = state.copyWith(
      calibration: calibration,
      result: result,
      statusMessage: 'Calibration updated.',
    );
  }

  void updateObservation(BallObservation observation) {
    final observations = state.observations.map((current) {
      return current.frameIndex == observation.frameIndex
          ? observation
          : current;
    }).toList()..sort((a, b) => a.frameIndex.compareTo(b.frameIndex));
    _setObservations(observations, 'Manual point updated.');
  }

  void addObservation() {
    final last = state.observations.isEmpty ? null : state.observations.last;
    final frameIndex = (last?.frameIndex ?? 0) + 1;
    final timestamp =
        (last?.timestamp ?? Duration.zero) + const Duration(milliseconds: 8);
    final point =
        (last?.imagePoint ?? const Offset(160, 360)) + const Offset(12, 0);
    final observation = BallObservation(
      frameIndex: frameIndex,
      timestamp: timestamp,
      imagePoint: point,
      confidence: 0.8,
      source: ObservationSource.manual,
      isAccepted: true,
    );
    _setObservations([
      ...state.observations,
      observation,
    ], 'Manual point added.');
  }

  void deleteObservation(int frameIndex) {
    final observations = state.observations
        .where((observation) => observation.frameIndex != frameIndex)
        .toList();
    _setObservations(observations, 'Point deleted.');
  }

  void toggleAccepted(int frameIndex) {
    final observations = state.observations.map((observation) {
      if (observation.frameIndex != frameIndex) {
        return observation;
      }
      return observation.copyWith(isAccepted: !observation.isAccepted);
    }).toList();
    _setObservations(observations, 'Point acceptance changed.');
  }

  void toggleUncertain(int frameIndex) {
    final observations = state.observations.map((observation) {
      if (observation.frameIndex != frameIndex) {
        return observation;
      }
      return observation.copyWith(
        isUncertain: !observation.isUncertain,
        confidence: observation.isUncertain ? 0.85 : 0.45,
      );
    }).toList();
    _setObservations(observations, 'Point uncertainty changed.');
  }

  Future<void> saveCurrentResult() async {
    final result = state.result;
    final metadata = state.metadata;
    final calibration = state.calibration;
    if (result == null || metadata == null || calibration == null) {
      return;
    }
    final database = ref.read(appDatabaseProvider);
    await database.saveResult(
      DeliveryResultRecord(
        id: _uuid.v4(),
        createdAt: DateTime.now(),
        videoUri: metadata.uri,
        sourceFps: metadata.nominalFps,
        calibrationDistanceMetres: calibration.knownDistanceMetres,
        releaseSpeedKph: result.releaseSpeedKph,
        averageSpeedKph: result.averageSpeedKph,
        confidence: result.confidence,
        warnings: result.warnings.map((warning) => warning.message).toList(),
      ),
    );
    state = state.copyWith(statusMessage: 'Result saved locally.');
  }

  void _setObservations(List<BallObservation> observations, String message) {
    final metadata = state.metadata;
    final calibration = state.calibration;
    if (metadata == null || calibration == null) {
      return;
    }
    final result = _estimate(calibration, observations, metadata);
    state = state.copyWith(
      observations: observations,
      result: result,
      statusMessage: message,
    );
  }

  SpeedAnalysisResult _estimate(
    LinearCalibration calibration,
    List<BallObservation> observations,
    VideoMetadata metadata,
  ) {
    try {
      return _estimator.estimate(
        calibration: calibration,
        observations: observations,
        metadata: metadata,
        cameraMotionScore: state.cameraMotionScore,
      );
    } catch (_) {
      return const SpeedAnalysisResult(
        releaseSpeedKph: null,
        releaseSpeedMph: null,
        averageSpeedKph: null,
        averageSpeedMph: null,
        minimumLikelySpeedKph: null,
        maximumLikelySpeedKph: null,
        confidence: AnalysisConfidence.failed,
        observationsUsed: 0,
        rejectedObservations: 0,
        warnings: [
          AnalysisWarning('Video timestamps are not reliable enough.'),
        ],
      );
    }
  }
}
