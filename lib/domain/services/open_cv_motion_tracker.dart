import 'dart:math' as math;
import 'dart:typed_data';

import 'package:opencv_dart/opencv.dart' as cv;

class MotionFrame {
  const MotionFrame({
    required this.width,
    required this.height,
    required this.gridWidth,
    required this.gridHeight,
    required this.step,
    required this.values,
  });

  final int width;
  final int height;
  final int gridWidth;
  final int gridHeight;
  final int step;
  final Uint8List values;

  bool matches(MotionFrame other) {
    return width == other.width &&
        height == other.height &&
        gridWidth == other.gridWidth &&
        gridHeight == other.gridHeight &&
        step == other.step &&
        values.length == other.values.length;
  }
}

class MotionSample {
  const MotionSample({
    required this.x,
    required this.leftX,
    required this.rightX,
    required this.coverage,
  });

  final double x;
  final double leftX;
  final double rightX;
  final double coverage;
}

class OpenCvMotionTracker {
  const OpenCvMotionTracker({
    this.threshold = 22,
    this.minimumChangedPixels = 12,
    this.minimumComponentPixels = 10,
  });

  final int threshold;
  final int minimumChangedPixels;
  final int minimumComponentPixels;

  MotionSample? detect(MotionFrame previous, MotionFrame current) {
    if (!previous.matches(current)) {
      return null;
    }

    final previousMat = cv.Mat.fromList(
      previous.gridHeight,
      previous.gridWidth,
      cv.MatType.CV_8UC1,
      previous.values,
    );
    final currentMat = cv.Mat.fromList(
      current.gridHeight,
      current.gridWidth,
      cv.MatType.CV_8UC1,
      current.values,
    );
    cv.Mat? diff;
    cv.Mat? mask;
    try {
      diff = cv.absDiff(previousMat, currentMat);
      final thresholdResult = cv.threshold(
        diff,
        threshold.toDouble(),
        255,
        cv.THRESH_BINARY,
      );
      mask = thresholdResult.$2;

      final changed = cv.countNonZero(mask);
      if (changed < minimumChangedPixels) {
        return null;
      }

      final bounds = _largestChangedComponent(previous, current);
      if (bounds == null || bounds.changed < minimumComponentPixels) {
        return null;
      }

      return MotionSample(
        x: bounds.center,
        leftX: bounds.left,
        rightX: bounds.right,
        coverage: changed / current.values.length,
      );
    } finally {
      mask?.dispose();
      diff?.dispose();
      currentMat.dispose();
      previousMat.dispose();
    }
  }

  _MotionBounds? _largestChangedComponent(
    MotionFrame previous,
    MotionFrame current,
  ) {
    final changedMask = Uint8List(current.values.length);
    for (var i = 0; i < current.values.length; i++) {
      final delta = (current.values[i] - previous.values[i]).abs();
      if (delta > threshold) {
        changedMask[i] = 1;
      }
    }

    final visited = Uint8List(current.values.length);
    _MotionBounds? largest;
    final stack = <int>[];
    for (var start = 0; start < changedMask.length; start++) {
      if (changedMask[start] == 0 || visited[start] == 1) {
        continue;
      }

      var count = 0;
      var sumX = 0;
      var minX = current.gridWidth;
      var maxX = -1;
      stack
        ..clear()
        ..add(start);
      visited[start] = 1;

      while (stack.isNotEmpty) {
        final index = stack.removeLast();
        final x = index % current.gridWidth;
        final y = index ~/ current.gridWidth;
        count++;
        sumX += x;
        minX = math.min(minX, x);
        maxX = math.max(maxX, x);

        for (var dy = -1; dy <= 1; dy++) {
          final ny = y + dy;
          if (ny < 0 || ny >= current.gridHeight) {
            continue;
          }
          for (var dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) {
              continue;
            }
            final nx = x + dx;
            if (nx < 0 || nx >= current.gridWidth) {
              continue;
            }
            final next = ny * current.gridWidth + nx;
            if (changedMask[next] == 0 || visited[next] == 1) {
              continue;
            }
            visited[next] = 1;
            stack.add(next);
          }
        }
      }

      if (maxX < minX) {
        continue;
      }
      if (largest == null || count > largest.changed) {
        final divisor = math.max(1, current.gridWidth - 1);
        largest = _MotionBounds(
          left: (minX / divisor).clamp(0, 1),
          right: (maxX / divisor).clamp(0, 1),
          center: (sumX / count / divisor).clamp(0, 1),
          changed: count,
        );
      }
    }

    return largest;
  }
}

class _MotionBounds {
  const _MotionBounds({
    required this.left,
    required this.right,
    required this.center,
    required this.changed,
  });

  final double left;
  final double right;
  final double center;
  final int changed;
}
