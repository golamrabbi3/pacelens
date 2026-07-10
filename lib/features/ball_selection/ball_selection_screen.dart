import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../analysis/analysis_controller.dart';
import '../analysis/trajectory_painter.dart';

class BallSelectionScreen extends ConsumerWidget {
  const BallSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisWorkflowProvider);
    final first = state.observations.isEmpty ? null : state.observations.first;
    return Scaffold(
      appBar: AppBar(title: const Text('Ball selection')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Select a frame immediately after release, then place the ball centre. This debug fixture is preselected and can be corrected in the next step.',
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: CustomPaint(
              painter: TrajectoryPainter(
                observations: first == null ? const [] : [first],
                calibration: state.calibration,
                highlightFrameIndex: first?.frameIndex,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (first != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.adjust),
                title: Text(
                  'Frame ${first.frameIndex} at ${first.timestamp.inMilliseconds} ms',
                ),
                subtitle: Text(
                  'Search radius: 28 px • source: ${first.source.name}',
                ),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.edit_location),
            label: const Text('Correct trajectory'),
            onPressed: () => context.go('/tracking'),
          ),
        ],
      ),
    );
  }
}
