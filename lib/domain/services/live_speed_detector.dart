enum LiveSpeedDirection { leftToRight, rightToLeft }

enum LiveSpeedDetectionState {
  waitingForStart,
  tracking,
  tooMuchMotion,
  invalidDistance,
  complete,
}

class LiveSpeedDetectionUpdate {
  const LiveSpeedDetectionUpdate({
    required this.state,
    required this.elapsed,
    required this.statusMessage,
    this.speedKph,
    this.direction,
  });

  final LiveSpeedDetectionState state;
  final Duration elapsed;
  final String statusMessage;
  final double? speedKph;
  final LiveSpeedDirection? direction;

  bool get shouldStop => state == LiveSpeedDetectionState.complete;

  double? get speedMph {
    final speed = speedKph;
    return speed == null ? null : speed / 1.609344;
  }
}

class LiveSpeedDetector {
  LiveSpeedDetector({
    this.leftGuide = 0.27,
    this.rightGuide = 0.73,
    this.maxMotionCoverage = 0.70,
    this.minimumDirectionDelta = 0.04,
    this.guideHitTolerance = 0.06,
    this.minimumElapsed = const Duration(milliseconds: 120),
  }) : assert(leftGuide > 0 && leftGuide < rightGuide && rightGuide < 1);

  final double leftGuide;
  final double rightGuide;
  final double maxMotionCoverage;
  final double minimumDirectionDelta;
  final double guideHitTolerance;
  final Duration minimumElapsed;

  LiveSpeedDirection? _direction;
  Duration? _startedAt;
  double? _lastMotionX;
  double? _lastMotionLeftX;
  double? _lastMotionRightX;
  Duration? _lastMotionAt;

  void reset() {
    _direction = null;
    _startedAt = null;
    _lastMotionX = null;
    _lastMotionLeftX = null;
    _lastMotionRightX = null;
    _lastMotionAt = null;
  }

  LiveSpeedDetectionUpdate observeNoMotion(Duration timestamp) {
    final startedAt = _startedAt;
    if (startedAt == null ||
        timestamp - startedAt > const Duration(milliseconds: 250)) {
      reset();
      return const LiveSpeedDetectionUpdate(
        state: LiveSpeedDetectionState.waitingForStart,
        elapsed: Duration.zero,
        statusMessage: 'Waiting for a moving object to cross a guide line...',
      );
    }
    return LiveSpeedDetectionUpdate(
      state: LiveSpeedDetectionState.tracking,
      elapsed: timestamp - startedAt,
      statusMessage: _trackingMessage(_direction),
      direction: _direction,
    );
  }

  LiveSpeedDetectionUpdate observeMotion({
    required double normalizedX,
    double? normalizedLeftX,
    double? normalizedRightX,
    required double coverage,
    required Duration timestamp,
    required double distanceMetres,
  }) {
    if (distanceMetres <= 0 || !distanceMetres.isFinite) {
      return LiveSpeedDetectionUpdate(
        state: LiveSpeedDetectionState.invalidDistance,
        elapsed: Duration.zero,
        statusMessage: 'Enter a valid distance.',
        direction: _direction,
      );
    }
    if (coverage > maxMotionCoverage) {
      return LiveSpeedDetectionUpdate(
        state: LiveSpeedDetectionState.tooMuchMotion,
        elapsed: Duration.zero,
        statusMessage: 'Too much scene movement. Hold the phone steady.',
        direction: _direction,
      );
    }

    final leftX = normalizedLeftX ?? normalizedX;
    final rightX = normalizedRightX ?? normalizedX;
    final previousX = _lastMotionX;
    final previousLeftX = _lastMotionLeftX;
    final previousRightX = _lastMotionRightX;
    final previousAt = _lastMotionAt;
    _lastMotionX = normalizedX;
    _lastMotionLeftX = leftX;
    _lastMotionRightX = rightX;
    _lastMotionAt = timestamp;

    if (_direction == null) {
      _tryStartDirection(
        normalizedX: normalizedX,
        previousLeftX: previousLeftX,
        previousRightX: previousRightX,
        previousX: previousX,
        previousAt: previousAt,
      );
    }

    final currentDirection = _direction;
    final startedAt = _startedAt;
    if (currentDirection == null || startedAt == null) {
      return const LiveSpeedDetectionUpdate(
        state: LiveSpeedDetectionState.waitingForStart,
        elapsed: Duration.zero,
        statusMessage: 'Keep the object moving through a guide line.',
      );
    }

    final reachedTarget =
        (currentDirection == LiveSpeedDirection.leftToRight &&
            rightX >= rightGuide - guideHitTolerance) ||
        (currentDirection == LiveSpeedDirection.rightToLeft &&
            leftX <= leftGuide + guideHitTolerance);
    final elapsed = timestamp - startedAt;
    if (!reachedTarget || elapsed <= minimumElapsed) {
      return LiveSpeedDetectionUpdate(
        state: LiveSpeedDetectionState.tracking,
        elapsed: elapsed.isNegative ? Duration.zero : elapsed,
        statusMessage: _trackingMessage(currentDirection),
        direction: currentDirection,
      );
    }

    final elapsedSeconds =
        elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final speedKph = distanceMetres / elapsedSeconds * 3.6;
    return LiveSpeedDetectionUpdate(
      state: LiveSpeedDetectionState.complete,
      elapsed: elapsed,
      speedKph: speedKph,
      statusMessage: 'Speed estimated from live camera motion.',
      direction: currentDirection,
    );
  }

  void _tryStartDirection({
    required double normalizedX,
    required double? previousX,
    required double? previousLeftX,
    required double? previousRightX,
    required Duration? previousAt,
  }) {
    if (previousX == null ||
        previousLeftX == null ||
        previousRightX == null ||
        previousAt == null) {
      return;
    }

    final movement = normalizedX - previousX;
    if (movement.abs() < minimumDirectionDelta) {
      return;
    }

    final previousTouchesLeftGuide =
        previousLeftX <= leftGuide + guideHitTolerance;
    final previousTouchesRightGuide =
        previousRightX >= rightGuide - guideHitTolerance;

    if (movement > 0 && previousTouchesLeftGuide) {
      _direction = LiveSpeedDirection.leftToRight;
      _startedAt = previousAt;
    } else if (movement < 0 && previousTouchesRightGuide) {
      _direction = LiveSpeedDirection.rightToLeft;
      _startedAt = previousAt;
    }
  }

  static String _trackingMessage(LiveSpeedDirection? direction) {
    return switch (direction) {
      LiveSpeedDirection.leftToRight =>
        'Tracking from left guide to right guide...',
      LiveSpeedDirection.rightToLeft =>
        'Tracking from right guide to left guide...',
      null => 'Move the object through a guide line first.',
    };
  }
}
