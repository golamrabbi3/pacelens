import 'dart:async';

import 'package:flutter/services.dart';

import '../../domain/entities/camera_capture_profile.dart';
import '../../domain/entities/recorded_video.dart';

enum CameraStatusKind {
  idle,
  initializing,
  ready,
  recording,
  warning,
  unsupported,
  error,
}

class CameraStatus {
  const CameraStatus({
    required this.kind,
    required this.message,
    this.motionScore = 0,
  });

  final CameraStatusKind kind;
  final String message;
  final double motionScore;

  factory CameraStatus.fromMap(Map<Object?, Object?> map) {
    return CameraStatus(
      kind: CameraStatusKind.values.firstWhere(
        (kind) => kind.name == map['kind'],
        orElse: () => CameraStatusKind.error,
      ),
      message: map['message']?.toString() ?? '',
      motionScore: (map['motionScore'] as num?)?.toDouble() ?? 0,
    );
  }
}

abstract interface class HighSpeedCameraPlatform {
  Future<List<CameraCaptureProfile>> getSupportedProfiles();

  Future<void> initialize(CameraCaptureProfile profile);

  Future<void> startRecording();

  Future<RecordedVideo> stopRecording();

  Stream<CameraStatus> watchStatus();

  Future<void> dispose();
}

class MethodChannelHighSpeedCameraPlatform implements HighSpeedCameraPlatform {
  MethodChannelHighSpeedCameraPlatform({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  }) : _methodChannel =
           methodChannel ?? const MethodChannel('pacelens/high_speed_camera'),
       _eventChannel =
           eventChannel ??
           const EventChannel('pacelens/high_speed_camera/status');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  @override
  Future<List<CameraCaptureProfile>> getSupportedProfiles() async {
    final result = await _methodChannel.invokeListMethod<Object?>(
      'getSupportedProfiles',
    );
    return (result ?? const <Object?>[])
        .whereType<Map<Object?, Object?>>()
        .map(CameraCaptureProfile.fromMap)
        .where((profile) => profile.maximumFps >= 60)
        .toList()
      ..sort(_profileSort);
  }

  @override
  Future<void> initialize(CameraCaptureProfile profile) {
    return _methodChannel.invokeMethod<void>('initialize', profile.toMap());
  }

  @override
  Future<void> startRecording() {
    return _methodChannel.invokeMethod<void>('startRecording');
  }

  @override
  Future<RecordedVideo> stopRecording() async {
    final map = await _methodChannel.invokeMapMethod<Object?, Object?>(
      'stopRecording',
    );
    if (map == null) {
      throw PlatformException(
        code: 'NO_RECORDING',
        message: 'No recorded video was returned by the native layer.',
      );
    }
    final profile = CameraCaptureProfile.fromMap(
      (map['cameraProfile'] as Map<Object?, Object?>?) ?? const {},
    );
    return RecordedVideo(
      uri: Uri.parse(map['uri']?.toString() ?? ''),
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      nominalFps: (map['nominalFps'] as num?)?.toDouble() ?? 0,
      duration: Duration(
        milliseconds: (map['durationMs'] as num?)?.toInt() ?? 0,
      ),
      platform: map['platform']?.toString() ?? 'unknown',
      cameraProfile: profile,
      motionScore: (map['motionScore'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Stream<CameraStatus> watchStatus() {
    return _eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map<Object?, Object?>) {
        return CameraStatus.fromMap(event);
      }
      return CameraStatus(
        kind: CameraStatusKind.error,
        message: event.toString(),
      );
    });
  }

  @override
  Future<void> dispose() {
    return _methodChannel.invokeMethod<void>('dispose');
  }
}

int _profileSort(CameraCaptureProfile a, CameraCaptureProfile b) {
  final aScore = _profileScore(a);
  final bScore = _profileScore(b);
  return bScore.compareTo(aScore);
}

int _profileScore(CameraCaptureProfile profile) {
  final fpsScore = profile.maximumFps >= 240
      ? 600
      : profile.maximumFps >= 120
      ? 400
      : profile.maximumFps >= 60
      ? 200
      : 0;
  final resolutionScore = profile.width >= 1920 && profile.height >= 1080
      ? 90
      : profile.width >= 1280 && profile.height >= 720
      ? 70
      : 10;
  final highSpeedScore = profile.isHighSpeed ? 20 : 0;
  final timestampScore = profile.supportsStableTimestamps ? 20 : -100;
  return fpsScore + resolutionScore + highSpeedScore + timestampScore;
}
