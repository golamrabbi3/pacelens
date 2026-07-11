import '../entities/ar_depth_motion_sample.dart';

enum ArDepthSpeedState {
  waitingForMotion,
  lowConfidence,
  invalidTimestamp,
  tracking,
}

class ArDepthSpeedUpdate {
  const ArDepthSpeedUpdate({
    required this.state,
    required this.statusMessage,
    this.speedKph,
    this.confidence,
  });

  final ArDepthSpeedState state;
  final String statusMessage;
  final double? speedKph;
  final double? confidence;

  double? get speedMph {
    final speed = speedKph;
    return speed == null ? null : speed / 1.609344;
  }
}

class ArDepthSpeedEstimator {
  ArDepthSpeedEstimator({this.minimumConfidence = 0.35});

  final double minimumConfidence;

  ArDepthMotionSample? _previousSample;

  void reset() {
    _previousSample = null;
  }

  ArDepthSpeedUpdate observe(ArDepthMotionSample sample) {
    if (sample.confidence < minimumConfidence) {
      _previousSample = sample;
      return ArDepthSpeedUpdate(
        state: ArDepthSpeedState.lowConfidence,
        statusMessage: 'AR depth confidence is too low for mph.',
        confidence: sample.confidence,
      );
    }

    final previous = _previousSample;
    _previousSample = sample;
    if (previous == null) {
      return ArDepthSpeedUpdate(
        state: ArDepthSpeedState.waitingForMotion,
        statusMessage: 'Waiting for AR world-position motion...',
        confidence: sample.confidence,
      );
    }

    final elapsedSeconds =
        (sample.timestamp - previous.timestamp).inMicroseconds /
        Duration.microsecondsPerSecond;
    if (elapsedSeconds <= 0) {
      return ArDepthSpeedUpdate(
        state: ArDepthSpeedState.invalidTimestamp,
        statusMessage: 'AR depth timestamps are not valid.',
        confidence: sample.confidence,
      );
    }

    final metres = previous.distanceTo(sample);
    final speedKph = metres / elapsedSeconds * 3.6;
    return ArDepthSpeedUpdate(
      state: ArDepthSpeedState.tracking,
      statusMessage: 'Experimental AR depth speed estimate.',
      speedKph: speedKph,
      confidence: sample.confidence,
    );
  }
}
