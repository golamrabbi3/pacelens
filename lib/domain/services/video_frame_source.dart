import '../entities/video_frame.dart';

abstract interface class VideoFrameSource {
  Future<VideoMetadata> inspect(Uri videoUri);

  Stream<VideoFrame> frames({
    required Uri videoUri,
    required Duration start,
    Duration? end,
  });

  Future<VideoFrame> frameAt({
    required Uri videoUri,
    required Duration timestamp,
  });
}
