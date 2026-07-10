class CameraCaptureProfile {
  const CameraCaptureProfile({
    required this.cameraId,
    required this.width,
    required this.height,
    required this.minimumFps,
    required this.maximumFps,
    required this.isHighSpeed,
    required this.supportsStableTimestamps,
  });

  final String cameraId;
  final int width;
  final int height;
  final double minimumFps;
  final double maximumFps;
  final bool isHighSpeed;
  final bool supportsStableTimestamps;

  bool get isUsable => maximumFps >= 60 && supportsStableTimestamps;
  String get label => '${width}x$height @ ${maximumFps.toStringAsFixed(0)} FPS';

  factory CameraCaptureProfile.fromMap(Map<Object?, Object?> map) {
    return CameraCaptureProfile(
      cameraId: map['cameraId']?.toString() ?? 'unknown',
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      minimumFps: (map['minimumFps'] as num?)?.toDouble() ?? 0,
      maximumFps: (map['maximumFps'] as num?)?.toDouble() ?? 0,
      isHighSpeed: map['isHighSpeed'] == true,
      supportsStableTimestamps: map['supportsStableTimestamps'] != false,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'cameraId': cameraId,
      'width': width,
      'height': height,
      'minimumFps': minimumFps,
      'maximumFps': maximumFps,
      'isHighSpeed': isHighSpeed,
      'supportsStableTimestamps': supportsStableTimestamps,
    };
  }
}
