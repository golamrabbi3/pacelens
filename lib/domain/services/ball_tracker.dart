import '../entities/ball_observation.dart';
import '../entities/ball_selection.dart';
import '../entities/video_frame.dart';

abstract interface class BallTracker {
  Future<TrackerInitializationResult> initialize({
    required VideoFrame frame,
    required BallSelection selection,
  });

  Future<BallTrackResult> track({
    required BallTrackState previousState,
    required VideoFrame frame,
  });
}

class TrackerInitializationResult {
  const TrackerInitializationResult({
    required this.state,
    required this.observation,
  });

  final BallTrackState state;
  final BallObservation observation;
}

class BallTrackState {
  const BallTrackState({
    required this.lastObservation,
    required this.missingFrameCount,
  });

  final BallObservation lastObservation;
  final int missingFrameCount;
}

class BallTrackResult {
  const BallTrackResult({
    required this.state,
    required this.observation,
    required this.isLost,
  });

  final BallTrackState state;
  final BallObservation? observation;
  final bool isLost;
}
