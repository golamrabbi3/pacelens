import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analysis/analysis_controller.dart';
import '../analysis/trajectory_painter.dart';

class ReplayScreen extends ConsumerStatefulWidget {
  const ReplayScreen({super.key});

  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends ConsumerState<ReplayScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analysisWorkflowProvider);
    final observations = state.observations;
    if (observations.isEmpty) {
      return const Scaffold(body: Center(child: Text('No replay data.')));
    }
    _index = _index.clamp(0, observations.length - 1);
    final current = observations[_index];
    return Scaffold(
      appBar: AppBar(title: const Text('Annotated replay')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: CustomPaint(
              painter: TrajectoryPainter(
                observations: observations.take(_index + 1).toList(),
                calibration: state.calibration,
                highlightFrameIndex: current.frameIndex,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _index.toDouble(),
            min: 0,
            max: (observations.length - 1).toDouble(),
            divisions: observations.length - 1,
            label: 'Frame ${current.frameIndex}',
            onChanged: (value) => setState(() => _index = value.round()),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.adjust),
              title: Text(
                'Frame ${current.frameIndex} • ${current.timestamp.inMilliseconds} ms',
              ),
              subtitle: Text(
                'Confidence ${current.confidence.toStringAsFixed(2)} • '
                '${current.isAccepted ? 'accepted' : 'rejected'} • ${current.source.name}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
