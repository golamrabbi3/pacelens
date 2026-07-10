class VideoFrame {
  const VideoFrame({
    required this.index,
    required this.timestamp,
    required this.width,
    required this.height,
    required this.imageHandle,
  });

  final int index;
  final Duration timestamp;
  final int width;
  final int height;
  final Object imageHandle;
}

class VideoMetadata {
  const VideoMetadata({
    required this.uri,
    required this.width,
    required this.height,
    required this.nominalFps,
    required this.duration,
    required this.hasStableTimestamps,
    required this.isLikelyReencoded,
  });

  final Uri uri;
  final int width;
  final int height;
  final double nominalFps;
  final Duration duration;
  final bool hasStableTimestamps;
  final bool isLikelyReencoded;
}
