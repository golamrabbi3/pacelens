import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/ball_observation.dart';
import '../analysis/analysis_controller.dart';
import '../analysis/trajectory_painter.dart';

class TrackingCorrectionScreen extends ConsumerStatefulWidget {
  const TrackingCorrectionScreen({super.key});

  @override
  ConsumerState<TrackingCorrectionScreen> createState() =>
      _TrackingCorrectionScreenState();
}

class _TrackingCorrectionScreenState
    extends ConsumerState<TrackingCorrectionScreen> {
  int _selectedIndex = 0;
  late final TextEditingController _xController;
  late final TextEditingController _yController;

  @override
  void initState() {
    super.initState();
    _xController = TextEditingController();
    _yController = TextEditingController();
  }

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analysisWorkflowProvider);
    final observations = state.observations;
    if (observations.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No observations loaded.')),
      );
    }
    _selectedIndex = _selectedIndex.clamp(0, observations.length - 1);
    final selected = observations[_selectedIndex];
    _xController.text = selected.imagePoint.dx.toStringAsFixed(1);
    _yController.text = selected.imagePoint.dy.toStringAsFixed(1);
    return Scaffold(
      appBar: AppBar(title: const Text('Trajectory correction')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: CustomPaint(
              painter: TrajectoryPainter(
                observations: observations,
                calibration: state.calibration,
                highlightFrameIndex: selected.frameIndex,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _selectedIndex.toDouble(),
            min: 0,
            max: (observations.length - 1).toDouble(),
            divisions: observations.length - 1,
            label: 'Frame ${selected.frameIndex}',
            onChanged: (value) =>
                setState(() => _selectedIndex = value.round()),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _xController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(labelText: 'X px'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _yController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(labelText: 'Y px'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Apply manual point',
                icon: const Icon(Icons.check),
                onPressed: () {
                  final x = double.tryParse(_xController.text);
                  final y = double.tryParse(_yController.text);
                  if (x == null || y == null) {
                    return;
                  }
                  ref
                      .read(analysisWorkflowProvider.notifier)
                      .updateObservation(
                        selected.copyWith(
                          imagePoint: Offset(x, y),
                          source: ObservationSource.manual,
                          confidence: 0.9,
                          isAccepted: true,
                        ),
                      );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add point'),
                onPressed: () => ref
                    .read(analysisWorkflowProvider.notifier)
                    .addObservation(),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.visibility_off),
                label: Text(
                  selected.isAccepted ? 'Mark rejected' : 'Mark accepted',
                ),
                onPressed: () => ref
                    .read(analysisWorkflowProvider.notifier)
                    .toggleAccepted(selected.frameIndex),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.help),
                label: Text(
                  selected.isUncertain ? 'Clear uncertain' : 'Mark uncertain',
                ),
                onPressed: () => ref
                    .read(analysisWorkflowProvider.notifier)
                    .toggleUncertain(selected.frameIndex),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                onPressed: () => ref
                    .read(analysisWorkflowProvider.notifier)
                    .deleteObservation(selected.frameIndex),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: Text(
                'Frame ${selected.frameIndex} • ${selected.timestamp.inMilliseconds} ms',
              ),
              subtitle: Text(
                '${selected.source.name} • confidence ${selected.confidence.toStringAsFixed(2)} • '
                '${selected.isAccepted ? 'accepted' : 'rejected'}',
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.speed),
            label: const Text('Calculate speed'),
            onPressed: () => context.push('/results'),
          ),
        ],
      ),
    );
  }
}
