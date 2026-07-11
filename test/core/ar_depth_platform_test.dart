import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pacelens/core/platform/ar_depth_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelArDepthPlatform', () {
    const channel = MethodChannel('test/ar_depth');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('maps supported capability response', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'checkCapability');
            return {
              'supported': true,
              'reason': 'Depth available.',
              'platform': 'test',
            };
          });
      final platform = MethodChannelArDepthPlatform(methodChannel: channel);

      final capability = await platform.checkCapability();

      expect(capability.supported, isTrue);
      expect(capability.reason, 'Depth available.');
      expect(capability.platform, 'test');
    });

    test('maps platform errors to unsupported capability', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            throw PlatformException(
              code: 'FAILED',
              message: 'Capability failed.',
            );
          });
      final platform = MethodChannelArDepthPlatform(methodChannel: channel);

      final capability = await platform.checkCapability();

      expect(capability.supported, isFalse);
      expect(capability.reason, 'Capability failed.');
    });
  });
}
