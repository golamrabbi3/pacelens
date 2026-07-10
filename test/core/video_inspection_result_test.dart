import 'package:flutter_test/flutter_test.dart';
import 'package:pacelens/domain/entities/video_inspection_result.dart';

void main() {
  test(
    'parses native video inspection payload and supports valid timestamps',
    () {
      final result = VideoInspectionResult.fromMap({
        'uri': 'file:///tmp/delivery.mov',
        'width': 1920,
        'height': 1080,
        'nominalFps': 120.0,
        'durationUs': 2 * 1000 * 1000,
        'hasStableTimestamps': true,
        'isLikelyReencoded': false,
        'sampledFrameCount': 240,
        'hasMonotonicTimestamps': true,
        'hasDuplicatedTimestamps': false,
        'hasIrregularFrameSpacing': false,
        'averageFrameIntervalUs': 8333,
        'warnings': <Object?>[],
      });

      expect(result.isSupported, isTrue);
      expect(result.metadata.width, 1920);
      expect(result.metadata.nominalFps, 120);
      expect(result.averageFrameInterval!.inMicroseconds, 8333);
    },
  );

  test('rejects video below 60 fps or duplicated timestamps', () {
    final lowFps = VideoInspectionResult.fromMap({
      'uri': 'file:///tmp/slow.mov',
      'width': 1280,
      'height': 720,
      'nominalFps': 30.0,
      'durationUs': 1 * 1000 * 1000,
      'hasStableTimestamps': true,
      'isLikelyReencoded': false,
      'sampledFrameCount': 30,
      'hasMonotonicTimestamps': true,
      'hasDuplicatedTimestamps': false,
      'hasIrregularFrameSpacing': false,
      'averageFrameIntervalUs': 33333,
      'warnings': <Object?>['Video below 60 FPS is not suitable for analysis.'],
    });
    final duplicated = VideoInspectionResult.fromMap({
      'uri': 'file:///tmp/duplicate.mov',
      'width': 1920,
      'height': 1080,
      'nominalFps': 120.0,
      'durationUs': 1 * 1000 * 1000,
      'hasStableTimestamps': false,
      'isLikelyReencoded': false,
      'sampledFrameCount': 120,
      'hasMonotonicTimestamps': false,
      'hasDuplicatedTimestamps': true,
      'hasIrregularFrameSpacing': false,
      'averageFrameIntervalUs': 8333,
      'warnings': <Object?>['Video timestamps are not reliable enough.'],
    });

    expect(lowFps.isSupported, isFalse);
    expect(duplicated.isSupported, isFalse);
  });
}
