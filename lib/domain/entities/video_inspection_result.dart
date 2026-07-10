import 'video_frame.dart';

class VideoInspectionResult {
  const VideoInspectionResult({
    required this.metadata,
    required this.sampledFrameCount,
    required this.hasMonotonicTimestamps,
    required this.hasDuplicatedTimestamps,
    required this.hasIrregularFrameSpacing,
    required this.averageFrameInterval,
    required this.warnings,
  });

  final VideoMetadata metadata;
  final int sampledFrameCount;
  final bool hasMonotonicTimestamps;
  final bool hasDuplicatedTimestamps;
  final bool hasIrregularFrameSpacing;
  final Duration? averageFrameInterval;
  final List<String> warnings;

  bool get isSupported {
    return metadata.nominalFps >= 60 &&
        metadata.hasStableTimestamps &&
        hasMonotonicTimestamps &&
        !hasDuplicatedTimestamps;
  }

  factory VideoInspectionResult.fromMap(Map<Object?, Object?> map) {
    return VideoInspectionResult(
      metadata: VideoMetadata(
        uri: Uri.parse(map['uri']?.toString() ?? ''),
        width: (map['width'] as num?)?.toInt() ?? 0,
        height: (map['height'] as num?)?.toInt() ?? 0,
        nominalFps: (map['nominalFps'] as num?)?.toDouble() ?? 0,
        duration: Duration(
          microseconds: (map['durationUs'] as num?)?.toInt() ?? 0,
        ),
        hasStableTimestamps: map['hasStableTimestamps'] == true,
        isLikelyReencoded: map['isLikelyReencoded'] == true,
      ),
      sampledFrameCount: (map['sampledFrameCount'] as num?)?.toInt() ?? 0,
      hasMonotonicTimestamps: map['hasMonotonicTimestamps'] == true,
      hasDuplicatedTimestamps: map['hasDuplicatedTimestamps'] == true,
      hasIrregularFrameSpacing: map['hasIrregularFrameSpacing'] == true,
      averageFrameInterval: map['averageFrameIntervalUs'] == null
          ? null
          : Duration(
              microseconds: (map['averageFrameIntervalUs'] as num).toInt(),
            ),
      warnings: (map['warnings'] as List<Object?>? ?? const [])
          .map((warning) => warning.toString())
          .toList(),
    );
  }
}
