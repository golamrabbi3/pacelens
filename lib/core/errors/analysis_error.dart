sealed class AnalysisError implements Exception {
  const AnalysisError();
}

class UnsupportedFrameRate extends AnalysisError {
  const UnsupportedFrameRate();
}

class InvalidTimestamps extends AnalysisError {
  const InvalidTimestamps();
}

class InvalidCalibration extends AnalysisError {
  const InvalidCalibration();
}

class BallNotFound extends AnalysisError {
  const BallNotFound();
}

class TrackingLost extends AnalysisError {
  const TrackingLost();
}

class InsufficientObservations extends AnalysisError {
  const InsufficientObservations();
}

class ExcessiveCameraMovement extends AnalysisError {
  const ExcessiveCameraMovement();
}

class AnalysisCancelled extends AnalysisError {
  const AnalysisCancelled();
}

class UnexpectedAnalysisError extends AnalysisError {
  const UnexpectedAnalysisError(this.cause);

  final Object cause;
}
