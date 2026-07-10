import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'high_speed_camera_platform.dart';
import 'native_video_inspector.dart';

final highSpeedCameraPlatformProvider = Provider<HighSpeedCameraPlatform>((
  ref,
) {
  final platform = MethodChannelHighSpeedCameraPlatform();
  ref.onDispose(platform.dispose);
  return platform;
});

final nativeVideoInspectorProvider = Provider<NativeVideoInspector>((ref) {
  return MethodChannelNativeVideoInspector();
});
