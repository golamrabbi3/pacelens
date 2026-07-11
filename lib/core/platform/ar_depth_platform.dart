import 'dart:async';

import 'package:flutter/services.dart';

import '../../domain/entities/ar_depth_capability.dart';
import '../../domain/entities/ar_depth_motion_sample.dart';

abstract interface class ArDepthPlatform {
  Future<ArDepthCapability> checkCapability();

  Future<void> startSession();

  Future<void> stopSession();

  Stream<ArDepthMotionSample> watchSamples();
}

class MethodChannelArDepthPlatform implements ArDepthPlatform {
  MethodChannelArDepthPlatform({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  }) : _methodChannel =
           methodChannel ?? const MethodChannel('pacelens/ar_depth'),
       _eventChannel =
           eventChannel ?? const EventChannel('pacelens/ar_depth/samples');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  @override
  Future<ArDepthCapability> checkCapability() async {
    try {
      final map = await _methodChannel.invokeMapMethod<Object?, Object?>(
        'checkCapability',
      );
      return ArDepthCapability.fromMap(map ?? const <Object?, Object?>{});
    } on MissingPluginException {
      return const ArDepthCapability(
        supported: false,
        reason: 'AR depth native channel is not available on this platform.',
        platform: 'unknown',
      );
    } on PlatformException catch (error) {
      return ArDepthCapability(
        supported: false,
        reason: error.message ?? 'AR depth capability check failed.',
        platform: 'unknown',
      );
    }
  }

  @override
  Future<void> startSession() {
    return _methodChannel.invokeMethod<void>('startSession');
  }

  @override
  Future<void> stopSession() {
    return _methodChannel.invokeMethod<void>('stopSession');
  }

  @override
  Stream<ArDepthMotionSample> watchSamples() {
    return _eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map<Object?, Object?>) {
        return ArDepthMotionSample.fromMap(event);
      }
      throw FormatException('Unexpected AR depth sample: $event');
    });
  }
}
