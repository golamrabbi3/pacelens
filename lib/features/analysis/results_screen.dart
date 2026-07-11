import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../analysis/analysis_controller.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisWorkflowProvider);
    final result = state.result;
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: result == null
          ? const Center(child: Text('No result available.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated speed',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.hasSpeed
                              ? '${result.releaseSpeedKph!.round()} km/h'
                              : 'No speed shown',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        if (result.hasSpeed)
                          Text('${result.releaseSpeedMph!.round()} mph'),
                        const SizedBox(height: 8),
                        Text(
                          'Confidence: ${confidenceLabel(result.confidence)}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (result.hasSpeed)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.straighten),
                      title: Text(
                        'Likely range: ${result.minimumLikelySpeedKph!.round()}-'
                        '${result.maximumLikelySpeedKph!.round()} km/h',
                      ),
                      subtitle: Text(
                        'Average tracked speed: ${result.averageSpeedKph!.round()} km/h',
                      ),
                    ),
                  ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.video_settings),
                    title: Text(
                      'Source FPS: ${state.metadata?.nominalFps.toStringAsFixed(0) ?? 'unknown'}',
                    ),
                    subtitle: Text(
                      '${result.observationsUsed} reliable observations • '
                      '${result.rejectedObservations} rejected • '
                      'motion score ${state.cameraMotionScore.toStringAsFixed(2)}',
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.architecture),
                    title: Text(
                      'Calibration distance: '
                      '${state.calibration?.knownDistanceMetres.toStringAsFixed(1) ?? '-'} m',
                    ),
                    subtitle: const Text(
                      'Linear side-on approximation. No 3D reconstruction.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Warnings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (result.warnings.isEmpty)
                  const Text('No major warnings.')
                else
                  for (final warning in result.warnings)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber),
                        title: Text(warning.message),
                      ),
                    ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save result locally'),
                  onPressed: () async {
                    await ref
                        .read(analysisWorkflowProvider.notifier)
                        .saveCurrentResult();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Result saved locally.')),
                      );
                    }
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.slow_motion_video),
                  label: const Text('Annotated replay'),
                  onPressed: () => context.push('/replay'),
                ),
              ],
            ),
    );
  }
}
