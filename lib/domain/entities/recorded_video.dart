import 'camera_capture_profile.dart';

class RecordedVideo {
  const RecordedVideo({
    required this.uri,
    required this.width,
    required this.height,
    required this.nominalFps,
    required this.duration,
    required this.platform,
    required this.cameraProfile,
    required this.motionScore,
  });

  final Uri uri;
  final int width;
  final int height;
  final double nominalFps;
  final Duration duration;
  final String platform;
  final CameraCaptureProfile cameraProfile;
  final double motionScore;
}
