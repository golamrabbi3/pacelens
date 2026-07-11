import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pacelens/domain/services/open_cv_motion_tracker.dart';

void main() {
  test(
    'OpenCvMotionTracker detects changed-pixel centroid and coverage',
    () {
      final tracker = OpenCvMotionTracker(
        minimumChangedPixels: 2,
        minimumComponentPixels: 2,
      );
      final previous = MotionFrame(
        width: 10,
        height: 5,
        gridWidth: 10,
        gridHeight: 5,
        step: 1,
        values: Uint8List(50),
      );
      final currentValues = Uint8List(50);
      currentValues[2 * 10 + 7] = 255;
      currentValues[2 * 10 + 8] = 255;
      currentValues[3 * 10 + 7] = 255;
      currentValues[3 * 10 + 8] = 255;
      final current = MotionFrame(
        width: 10,
        height: 5,
        gridWidth: 10,
        gridHeight: 5,
        step: 1,
        values: currentValues,
      );

      final motion = tracker.detect(previous, current);

      expect(motion, isNotNull);
      expect(motion!.x, closeTo(7.5 / 9, 0.001));
      expect(motion.leftX, closeTo(7 / 9, 0.001));
      expect(motion.rightX, closeTo(8 / 9, 0.001));
      expect(motion.coverage, closeTo(4 / 50, 0.001));
    },
    skip:
        'Requires OpenCV native library from the app build; flutter test host does not provide libdartcv.dylib.',
  );
}
