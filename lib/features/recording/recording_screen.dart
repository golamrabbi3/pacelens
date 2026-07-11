import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/platform/ar_depth_platform.dart';
import '../../domain/entities/ar_depth_capability.dart';
import '../../domain/entities/ar_depth_motion_sample.dart';
import '../../domain/entities/speed_measurement_mode.dart';
import '../../domain/services/ar_depth_speed_estimator.dart';
import '../../domain/services/live_speed_detector.dart';
import '../../domain/services/open_cv_motion_tracker.dart';

const _leftGuide = 0.27;
const _rightGuide = 0.73;

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Object? _error;
  late final TextEditingController _distanceController;
  final _testClock = Stopwatch();
  final _liveSpeedDetector = LiveSpeedDetector(
    leftGuide: _leftGuide,
    rightGuide: _rightGuide,
  );
  final _arDepthPlatform = MethodChannelArDepthPlatform();
  final _arDepthSpeedEstimator = ArDepthSpeedEstimator();
  final _motionTracker = const OpenCvMotionTracker();
  StreamSubscription<ArDepthMotionSample>? _arDepthSamples;
  Timer? _ticker;
  MotionFrame? _previousFrame;
  SpeedMeasurementMode _mode = SpeedMeasurementMode.calibratedGuides;
  ArDepthCapability? _arDepthCapability;
  double? _lastMotionX;
  double? _speedKph;
  double? _arDepthConfidence;
  Duration _elapsed = Duration.zero;
  String _status = 'Ready. No video will be saved.';
  bool _isInitializing = true;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _distanceController = TextEditingController(text: '20.12');
    _loadArDepthCapability();
    _openCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _arDepthSamples?.cancel();
    unawaited(_arDepthPlatform.stopSession());
    _distanceController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (_mode == SpeedMeasurementMode.arDepth) {
      if (state == AppLifecycleState.inactive) {
        _stopLiveTest(resetStatus: false);
      }
      return;
    }
    if (controller == null) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _stopLiveTest(resetStatus: false);
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _openCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady = controller?.value.isInitialized == true;
    final canStart = _mode == SpeedMeasurementMode.arDepth
        ? _arDepthCapability?.supported == true
        : isReady;
    return Scaffold(
      appBar: AppBar(title: const Text('Recording')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ColoredBox(
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _CameraPreviewContent(
                      controller: controller,
                      error: _error,
                      isInitializing: _isInitializing,
                      isArDepthMode: _mode == SpeedMeasurementMode.arDepth,
                      onRetry: _openCamera,
                    ),
                    if (isReady)
                      _SpeedGuideOverlay(
                        motionX: _lastMotionX,
                        isTesting: _isTesting,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _LiveSpeedTestCard(
            mode: _mode,
            arDepthCapability: _arDepthCapability,
            distanceController: _distanceController,
            canStart: canStart,
            isTesting: _isTesting,
            elapsed: _elapsed,
            speedKph: _speedKph,
            arDepthConfidence: _arDepthConfidence,
            status: _status,
            onModeChanged: _selectMode,
            onDistanceChanged: (_) => setState(() {}),
            onStart: _startLiveTest,
            onStop: () => _stopLiveTest(),
            onReset: _resetLiveTest,
          ),
          const SizedBox(height: 10),
          const Card(
            child: ListTile(
              dense: true,
              leading: Icon(Icons.info_outline),
              title: Text('Local live estimate'),
              subtitle: Text(
                'OpenCV watches guide-line crossings for calibrated mph. AR depth uses a native depth channel when the device supports it.',
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            key: const ValueKey('recordingBackToSetupButton'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to camera setup'),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go('/setup');
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.video_file),
            label: const Text('Analyse existing video'),
            onPressed: () => context.push('/import'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadArDepthCapability() async {
    final capability = await _arDepthPlatform.checkCapability();
    if (!mounted) {
      return;
    }
    setState(() {
      _arDepthCapability = capability;
      if (_mode == SpeedMeasurementMode.arDepth && !capability.supported) {
        _status = 'AR depth unavailable: ${capability.reason}';
      }
    });
  }

  Future<void> _openCamera() async {
    setState(() {
      _isInitializing = true;
      _error = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException(
          'NO_CAMERA',
          'No camera was found on this device.',
        );
      }
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      await _stabilizeCameraForMotionTracking(controller);
      await _controller?.dispose();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isInitializing = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _controller = null;
        _isInitializing = false;
        _isTesting = false;
        _error = error;
        _status = 'Camera is unavailable.';
      });
    }
  }

  Future<void> _startLiveTest() async {
    if (_isTesting) {
      return;
    }
    if (_mode == SpeedMeasurementMode.arDepth) {
      await _startArDepthTest();
      return;
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    await _stabilizeCameraForMotionTracking(controller);
    _resetTrackingState();
    setState(() {
      _isTesting = true;
      _clearSpeedValues();
      _elapsed = Duration.zero;
      _status = 'Watching for a moving object at either guide line...';
    });
    _testClock
      ..reset()
      ..start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted && _isTesting) {
        setState(() => _elapsed = _testClock.elapsed);
      }
    });
    try {
      await controller.startImageStream(_handleFrame);
    } catch (error) {
      _testClock.stop();
      _ticker?.cancel();
      if (!mounted) {
        return;
      }
      setState(() {
        _isTesting = false;
        _status = 'Could not start live frame analysis.';
      });
      _showCameraError(error);
    }
  }

  Future<void> _stabilizeCameraForMotionTracking(
    CameraController controller,
  ) async {
    if (!controller.value.isInitialized) {
      return;
    }
    await _tryCameraSetting(
      () => controller.setFocusPoint(const Offset(0.5, 0.5)),
    );
    await _tryCameraSetting(
      () => controller.setExposurePoint(const Offset(0.5, 0.5)),
    );
    await _tryCameraSetting(() => controller.setFocusMode(FocusMode.locked));
    await _tryCameraSetting(
      () => controller.setExposureMode(ExposureMode.locked),
    );
  }

  Future<void> _tryCameraSetting(Future<void> Function() setting) async {
    try {
      await setting();
    } on CameraException {
      // Some devices do not support locking focus or exposure.
    }
  }

  Future<void> _startArDepthTest() async {
    final capability =
        _arDepthCapability ?? await _arDepthPlatform.checkCapability();
    if (!capability.supported) {
      setState(() {
        _arDepthCapability = capability;
        _status = 'AR depth unavailable: ${capability.reason}';
      });
      return;
    }

    _resetTrackingState();
    await _controller?.dispose();
    _controller = null;
    _arDepthSamples = _arDepthPlatform.watchSamples().listen(
      _handleArDepthSample,
      onError: (Object error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _status = 'AR depth sample error: $error';
          _isTesting = false;
        });
      },
    );
    setState(() {
      _isTesting = true;
      _isInitializing = false;
      _error = null;
      _clearSpeedValues();
      _elapsed = Duration.zero;
      _status = 'Starting experimental AR depth session...';
    });
    _testClock
      ..reset()
      ..start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted && _isTesting) {
        setState(() => _elapsed = _testClock.elapsed);
      }
    });
    try {
      await _arDepthPlatform.startSession();
      _setStatus('Watching AR world-position motion...');
    } catch (error) {
      _testClock.stop();
      _ticker?.cancel();
      await _arDepthSamples?.cancel();
      _arDepthSamples = null;
      if (!mounted) {
        return;
      }
      setState(() {
        _isTesting = false;
        _status = 'Could not start AR depth: $error';
      });
    }
  }

  Future<void> _stopLiveTest({bool resetStatus = true}) async {
    final controller = _controller;
    _testClock.stop();
    _ticker?.cancel();
    if (controller?.value.isStreamingImages == true) {
      try {
        await controller!.stopImageStream();
      } catch (error) {
        _showCameraError(error);
      }
    }
    await _arDepthSamples?.cancel();
    _arDepthSamples = null;
    try {
      await _arDepthPlatform.stopSession();
    } catch (_) {
      // Best-effort cleanup; the platform may not have an active AR session.
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isTesting = false;
      _elapsed = _testClock.elapsed;
      if (resetStatus && !_hasSpeedResult) {
        _status = switch (_mode) {
          SpeedMeasurementMode.calibratedGuides =>
            'Stopped before the object crossed both guide lines.',
          SpeedMeasurementMode.arDepth =>
            'Stopped before AR depth speed was calculated.',
        };
      }
    });
  }

  void _resetLiveTest() {
    _stopLiveTest(resetStatus: false);
    _testClock.reset();
    _resetTrackingState();
    setState(() {
      _elapsed = Duration.zero;
      _clearSpeedValues();
      _status = 'Ready. No video will be saved.';
    });
  }

  void _resetTrackingState() {
    _previousFrame = null;
    _liveSpeedDetector.reset();
    _arDepthSpeedEstimator.reset();
    _lastMotionX = null;
  }

  void _clearSpeedValues() {
    _speedKph = null;
    _arDepthConfidence = null;
  }

  bool get _hasSpeedResult => _speedKph != null;

  void _selectMode(Set<SpeedMeasurementMode> selection) {
    if (_isTesting || selection.isEmpty) {
      return;
    }
    final mode = selection.first;
    setState(() {
      _mode = mode;
      _clearSpeedValues();
      _elapsed = Duration.zero;
      _status = switch (mode) {
        SpeedMeasurementMode.calibratedGuides =>
          'Calibrated mph uses the real guide-line distance.',
        SpeedMeasurementMode.arDepth =>
          _arDepthCapability?.supported == true
              ? 'AR depth mph is experimental and device-dependent.'
              : 'AR depth unavailable: ${_arDepthCapability?.reason ?? 'checking support...'}',
      };
    });
  }

  void _handleFrame(CameraImage image) {
    if (!_isTesting || !mounted) {
      return;
    }
    final frame = _sampleLuma(image);
    if (frame == null) {
      return;
    }
    final previous = _previousFrame;
    _previousFrame = frame;
    if (previous == null || !previous.matches(frame)) {
      return;
    }

    final motion = _motionTracker.detect(previous, frame);
    final now = _testClock.elapsed;
    if (motion == null) {
      _setStatusThrottled(
        _liveSpeedDetector.observeNoMotion(now).statusMessage,
      );
      return;
    }
    setState(() => _lastMotionX = motion.x);

    if (_mode == SpeedMeasurementMode.arDepth) {
      return;
    }
    _handleCalibratedMotion(motion, now);
  }

  void _handleCalibratedMotion(MotionSample motion, Duration now) {
    final distanceMetres = double.tryParse(_distanceController.text);
    final update = _liveSpeedDetector.observeMotion(
      normalizedX: motion.x,
      normalizedLeftX: motion.leftX,
      normalizedRightX: motion.rightX,
      coverage: motion.coverage,
      timestamp: now,
      distanceMetres: distanceMetres ?? 0,
    );
    if (!update.shouldStop) {
      if (update.state == LiveSpeedDetectionState.invalidDistance ||
          update.state == LiveSpeedDetectionState.tooMuchMotion) {
        _setStatus(update.statusMessage);
      } else {
        _setStatusThrottled(update.statusMessage);
      }
      return;
    }
    setState(() {
      _speedKph = update.speedKph;
      _elapsed = update.elapsed;
      _status = update.statusMessage;
    });
    _stopLiveTest(resetStatus: false);
  }

  void _handleArDepthSample(ArDepthMotionSample sample) {
    if (!_isTesting || !mounted) {
      return;
    }
    final update = _arDepthSpeedEstimator.observe(sample);
    setState(() {
      _arDepthConfidence = update.confidence;
      if (update.speedKph != null) {
        _speedKph = update.speedKph;
      }
      _status = update.statusMessage;
    });
  }

  void _setStatusThrottled(String status) {
    final elapsedMs = _testClock.elapsedMilliseconds;
    if (elapsedMs % 250 > 60 || _status == status) {
      return;
    }
    _setStatus(status);
  }

  void _setStatus(String status) {
    if (_status == status) {
      return;
    }
    setState(() => _status = status);
  }

  void _showCameraError(Object error) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Camera error: $error')));
  }
}

class _LiveSpeedTestCard extends StatelessWidget {
  const _LiveSpeedTestCard({
    required this.mode,
    required this.arDepthCapability,
    required this.distanceController,
    required this.canStart,
    required this.isTesting,
    required this.elapsed,
    required this.speedKph,
    required this.arDepthConfidence,
    required this.status,
    required this.onModeChanged,
    required this.onDistanceChanged,
    required this.onStart,
    required this.onStop,
    required this.onReset,
  });

  final SpeedMeasurementMode mode;
  final ArDepthCapability? arDepthCapability;
  final TextEditingController distanceController;
  final bool canStart;
  final bool isTesting;
  final Duration elapsed;
  final double? speedKph;
  final double? arDepthConfidence;
  final String status;
  final ValueChanged<Set<SpeedMeasurementMode>> onModeChanged;
  final ValueChanged<String> onDistanceChanged;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final speed = speedKph;
    final arDepthSupported = arDepthCapability?.supported == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Live speed test',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<SpeedMeasurementMode>(
                segments: [
                  for (final value in SpeedMeasurementMode.values)
                    ButtonSegment<SpeedMeasurementMode>(
                      value: value,
                      enabled:
                          !isTesting &&
                          (value != SpeedMeasurementMode.arDepth ||
                              arDepthSupported),
                      label: Text(value.label),
                    ),
                ],
                selected: {mode},
                onSelectionChanged: isTesting ? null : onModeChanged,
              ),
            ),
            if (mode == SpeedMeasurementMode.calibratedGuides) ...[
              const SizedBox(height: 8),
              TextField(
                controller: distanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Real distance between guide lines in metres',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: onDistanceChanged,
              ),
            ],
            if (mode == SpeedMeasurementMode.arDepth) ...[
              const SizedBox(height: 8),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  arDepthSupported ? Icons.view_in_ar : Icons.block,
                ),
                title: const Text('Experimental AR depth'),
                subtitle: Text(
                  arDepthCapability?.reason ??
                      'Checking AR depth support on this device...',
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  icon: Icon(isTesting ? Icons.stop : Icons.play_arrow),
                  label: Text(isTesting ? 'Stop test' : 'Start speed test'),
                  onPressed: canStart ? (isTesting ? onStop : onStart) : null,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  onPressed: onReset,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final metrics = _metricsForMode(
                  mode: mode,
                  elapsed: elapsed,
                  speedKph: speed,
                  arDepthConfidence: arDepthConfidence,
                );
                return Row(
                  children: [
                    for (final metric in metrics) ...[
                      Expanded(child: metric),
                      if (metric != metrics.last) const SizedBox(width: 8),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Text(status),
          ],
        ),
      ),
    );
  }
}

List<_SpeedMetric> _metricsForMode({
  required SpeedMeasurementMode mode,
  required Duration elapsed,
  required double? speedKph,
  required double? arDepthConfidence,
}) {
  return switch (mode) {
    SpeedMeasurementMode.calibratedGuides => [
      _SpeedMetric(label: 'Time', value: _formatElapsed(elapsed)),
      _SpeedMetric(
        label: 'km/h',
        value: speedKph == null
            ? '-- km/h'
            : '${speedKph.toStringAsFixed(1)} km/h',
      ),
      _SpeedMetric(
        label: 'mph',
        value: speedKph == null
            ? '-- mph'
            : '${(speedKph / 1.609344).toStringAsFixed(1)} mph',
      ),
    ],
    SpeedMeasurementMode.arDepth => [
      _SpeedMetric(label: 'Time', value: _formatElapsed(elapsed)),
      _SpeedMetric(
        label: 'mph',
        value: speedKph == null
            ? '-- mph'
            : '${(speedKph / 1.609344).toStringAsFixed(1)} mph',
      ),
      _SpeedMetric(
        label: 'Confidence',
        value: arDepthConfidence == null
            ? '--'
            : '${(arDepthConfidence * 100).toStringAsFixed(0)}%',
      ),
    ],
  };
}

class _SpeedMetric extends StatelessWidget {
  const _SpeedMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedGuideOverlay extends StatelessWidget {
  const _SpeedGuideOverlay({required this.motionX, required this.isTesting});

  final double? motionX;
  final bool isTesting;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _SpeedGuidePainter(
          motionX: motionX,
          isTesting: isTesting,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _SpeedGuidePainter extends CustomPainter {
  const _SpeedGuidePainter({
    required this.motionX,
    required this.isTesting,
    required this.color,
  });

  final double? motionX;
  final bool isTesting;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = color
      ..strokeWidth = 3;
    final labelPaint = Paint()..color = Colors.black.withValues(alpha: 0.45);
    for (final x in [_leftGuide * size.width, _rightGuide * size.width]) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), guidePaint);
      canvas.drawRect(Rect.fromLTWH(x - 18, 8, 36, 24), labelPaint);
    }
    final motion = motionX;
    if (isTesting && motion != null) {
      canvas.drawCircle(
        Offset(motion * size.width, size.height / 2),
        9,
        Paint()..color = Colors.redAccent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedGuidePainter oldDelegate) {
    return oldDelegate.motionX != motionX ||
        oldDelegate.isTesting != isTesting ||
        oldDelegate.color != color;
  }
}

class _CameraPreviewContent extends StatelessWidget {
  const _CameraPreviewContent({
    required this.controller,
    required this.error,
    required this.isInitializing,
    required this.isArDepthMode,
    required this.onRetry,
  });

  final CameraController? controller;
  final Object? error;
  final bool isInitializing;
  final bool isArDepthMode;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (isArDepthMode) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'AR depth mode uses the native AR camera session when supported.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (controller != null && controller.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: _effectivePreviewAspectRatio(controller),
          child: CameraPreview(controller),
        ),
      );
    }
    if (isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography, size: 40),
            const SizedBox(height: 12),
            Text(
              error == null ? 'Camera is unavailable.' : 'Camera error: $error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

MotionFrame? _sampleLuma(CameraImage image) {
  if (image.planes.isEmpty || image.width <= 0 || image.height <= 0) {
    return null;
  }
  final width = image.width;
  final height = image.height;
  final step = math.max(3, math.min(width ~/ 160, height ~/ 90));
  final gridWidth = width ~/ step;
  final gridHeight = height ~/ step;
  if (gridWidth <= 0 || gridHeight <= 0) {
    return null;
  }
  final values = Uint8List(gridWidth * gridHeight);
  final plane = image.planes.first;
  final bytes = plane.bytes;
  var index = 0;
  for (var gy = 0; gy < gridHeight; gy++) {
    final y = gy * step;
    for (var gx = 0; gx < gridWidth; gx++) {
      final x = gx * step;
      values[index++] = _luminanceAt(image, bytes, plane.bytesPerRow, x, y);
    }
  }
  return MotionFrame(
    width: width,
    height: height,
    gridWidth: gridWidth,
    gridHeight: gridHeight,
    step: step,
    values: values,
  );
}

int _luminanceAt(
  CameraImage image,
  Uint8List bytes,
  int bytesPerRow,
  int x,
  int y,
) {
  if (image.format.group == ImageFormatGroup.bgra8888) {
    final offset = y * bytesPerRow + x * 4;
    if (offset + 2 >= bytes.length) {
      return 0;
    }
    final b = bytes[offset];
    final g = bytes[offset + 1];
    final r = bytes[offset + 2];
    return (0.299 * r + 0.587 * g + 0.114 * b).round();
  }
  final offset = y * bytesPerRow + x;
  if (offset >= bytes.length) {
    return 0;
  }
  return bytes[offset];
}

double _effectivePreviewAspectRatio(CameraController controller) {
  final orientation = _effectivePreviewOrientation(controller);
  final isLandscape =
      orientation == DeviceOrientation.landscapeLeft ||
      orientation == DeviceOrientation.landscapeRight;
  return isLandscape
      ? controller.value.aspectRatio
      : 1 / controller.value.aspectRatio;
}

DeviceOrientation _effectivePreviewOrientation(CameraController controller) {
  return controller.value.isRecordingVideo
      ? controller.value.recordingOrientation!
      : (controller.value.previewPauseOrientation ??
            controller.value.lockedCaptureOrientation ??
            controller.value.deviceOrientation);
}

String _formatElapsed(Duration elapsed) {
  final seconds = elapsed.inMilliseconds / Duration.millisecondsPerSecond;
  return '${seconds.toStringAsFixed(2)} s';
}
