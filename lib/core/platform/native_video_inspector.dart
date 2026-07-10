import 'package:flutter/services.dart';

import '../../domain/entities/video_inspection_result.dart';

abstract interface class NativeVideoInspector {
  Future<VideoInspectionResult> inspect(Uri uri);
}

class MethodChannelNativeVideoInspector implements NativeVideoInspector {
  MethodChannelNativeVideoInspector({MethodChannel? methodChannel})
    : _methodChannel =
          methodChannel ?? const MethodChannel('pacelens/video_inspector');

  final MethodChannel _methodChannel;

  @override
  Future<VideoInspectionResult> inspect(Uri uri) async {
    final map = await _methodChannel.invokeMapMethod<Object?, Object?>(
      'inspectVideo',
      {'uri': uri.toString()},
    );
    if (map == null) {
      throw PlatformException(
        code: 'NO_METADATA',
        message: 'The native layer returned no video metadata.',
      );
    }
    return VideoInspectionResult.fromMap(map);
  }
}
