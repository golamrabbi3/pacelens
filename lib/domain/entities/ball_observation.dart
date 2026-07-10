import 'dart:ui';

enum ObservationSource {
  manual,
  opticalFlow,
  templateMatch,
  motionDetection,
  combined,
  interpolated,
}

class BallObservation {
  const BallObservation({
    required this.frameIndex,
    required this.timestamp,
    required this.imagePoint,
    required this.confidence,
    required this.source,
    required this.isAccepted,
    this.isOccluded = false,
    this.isUncertain = false,
  });

  final int frameIndex;
  final Duration timestamp;
  final Offset imagePoint;
  final double confidence;
  final ObservationSource source;
  final bool isAccepted;
  final bool isOccluded;
  final bool isUncertain;

  bool get isReal => source != ObservationSource.interpolated;

  BallObservation copyWith({
    int? frameIndex,
    Duration? timestamp,
    Offset? imagePoint,
    double? confidence,
    ObservationSource? source,
    bool? isAccepted,
    bool? isOccluded,
    bool? isUncertain,
  }) {
    return BallObservation(
      frameIndex: frameIndex ?? this.frameIndex,
      timestamp: timestamp ?? this.timestamp,
      imagePoint: imagePoint ?? this.imagePoint,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
      isAccepted: isAccepted ?? this.isAccepted,
      isOccluded: isOccluded ?? this.isOccluded,
      isUncertain: isUncertain ?? this.isUncertain,
    );
  }
}
