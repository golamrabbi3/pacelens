import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/math/calibration_math.dart';
import '../../domain/entities/linear_calibration.dart';
import '../analysis/analysis_controller.dart';
import '../analysis/trajectory_painter.dart';

class CalibrationScreen extends ConsumerStatefulWidget {
  const CalibrationScreen({super.key});

  @override
  ConsumerState<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends ConsumerState<CalibrationScreen> {
  late Offset _pointA;
  late Offset _pointB;
  late final TextEditingController _distanceController;

  @override
  void initState() {
    super.initState();
    final calibration = ref.read(analysisWorkflowProvider).calibration;
    _pointA = calibration?.pointA ?? const Offset(100, 360);
    _pointB = calibration?.pointB ?? const Offset(600, 360);
    _distanceController = TextEditingController(
      text: (calibration?.knownDistanceMetres ?? 10).toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analysisWorkflowProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Calibration')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Linear side-on calibration is an approximation. Place two points on a visible known distance parallel to the ball path.',
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapUp: (details) {
                    final mapped = Offset(
                      details.localPosition.dx / constraints.maxWidth * 1280,
                      details.localPosition.dy / constraints.maxHeight * 720,
                    );
                    setState(() {
                      if ((mapped - _pointA).distance <
                          (mapped - _pointB).distance) {
                        _pointA = mapped;
                      } else {
                        _pointB = mapped;
                      }
                    });
                  },
                  child: CustomPaint(
                    painter: TrajectoryPainter(
                      observations: state.observations,
                      calibration: LinearCalibration.fromPoints(
                        pointA: _pointA,
                        pointB: _pointB,
                        knownDistanceMetres:
                            double.tryParse(_distanceController.text) ?? 10,
                        frameSize: const Size(1280, 720),
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _distanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Known distance in metres',
              helperText: 'Use the longest clearly visible measured distance.',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Use calibration'),
            onPressed: () {
              final distance = double.tryParse(_distanceController.text) ?? 0;
              try {
                final calibration = CalibrationMath.createLinear(
                  pointA: _pointA,
                  pointB: _pointB,
                  knownDistanceMetres: distance,
                  frameSize: const Size(1280, 720),
                );
                ref
                    .read(analysisWorkflowProvider.notifier)
                    .updateCalibration(calibration);
                context.go('/ball-selection');
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Invalid calibration. Use distinct in-frame points and a positive distance.',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
