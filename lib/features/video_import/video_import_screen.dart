import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/platform/platform_providers.dart';
import '../../domain/entities/video_inspection_result.dart';
import '../analysis/analysis_controller.dart';

class VideoImportScreen extends ConsumerStatefulWidget {
  const VideoImportScreen({super.key});

  @override
  ConsumerState<VideoImportScreen> createState() => _VideoImportScreenState();
}

class _VideoImportScreenState extends ConsumerState<VideoImportScreen> {
  VideoInspectionResult? _inspection;
  Object? _error;
  bool _isInspecting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video import')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Imported-video analysis requires native MediaExtractor/AVAssetReader timestamp inspection. If timestamps are duplicated, missing, or irregular, analysis fails instead of inventing timing.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: _isInspecting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.video_file),
            label: const Text('Choose local video'),
            onPressed: _isInspecting ? null : () => _pickAndInspect(ref),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.error),
                title: const Text('Import failed'),
                subtitle: Text(_error.toString()),
              ),
            ),
          if (_inspection != null) _InspectionCard(inspection: _inspection!),
          const SizedBox(height: 16),
          if (kDebugMode)
            FilledButton.icon(
              icon: const Icon(Icons.science),
              label: const Text('Use synthetic debug video'),
              onPressed: () {
                ref.read(analysisWorkflowProvider.notifier).resetSynthetic();
                context.push('/calibration');
              },
            ),
        ],
      ),
    );
  }

  Future<void> _pickAndInspect(WidgetRef ref) async {
    setState(() {
      _isInspecting = true;
      _error = null;
      _inspection = null;
    });
    try {
      const videoTypeGroup = XTypeGroup(
        label: 'Videos',
        extensions: ['mp4', 'mov', 'm4v'],
        mimeTypes: ['video/mp4', 'video/quicktime', 'video/*'],
      );
      final file = await openFile(acceptedTypeGroups: [videoTypeGroup]);
      final path = file?.path;
      if (path == null || path.isEmpty) {
        return;
      }
      final uri = path.startsWith('content://')
          ? Uri.parse(path)
          : Uri.file(path);
      final inspection = await ref
          .read(nativeVideoInspectorProvider)
          .inspect(uri);
      ref.read(analysisWorkflowProvider.notifier).loadImportedVideo(inspection);
      setState(() => _inspection = inspection);
    } catch (error) {
      setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() => _isInspecting = false);
      }
    }
  }
}

class _InspectionCard extends StatelessWidget {
  const _InspectionCard({required this.inspection});

  final VideoInspectionResult inspection;

  @override
  Widget build(BuildContext context) {
    final metadata = inspection.metadata;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  inspection.isSupported ? Icons.check_circle : Icons.warning,
                  color: inspection.isSupported
                      ? Colors.lightGreenAccent
                      : Colors.orangeAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    inspection.isSupported
                        ? 'Video timestamps look usable'
                        : 'Video is not ready for analysis',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _FactRow(
              label: 'Resolution',
              value: '${metadata.width}x${metadata.height}',
            ),
            _FactRow(
              label: 'Nominal FPS',
              value: metadata.nominalFps.toStringAsFixed(1),
            ),
            _FactRow(
              label: 'Duration',
              value: '${metadata.duration.inMilliseconds} ms',
            ),
            _FactRow(
              label: 'Sampled frames',
              value: '${inspection.sampledFrameCount}',
            ),
            _FactRow(
              label: 'Average interval',
              value: inspection.averageFrameInterval == null
                  ? 'unknown'
                  : '${inspection.averageFrameInterval!.inMicroseconds / 1000} ms',
            ),
            _FactRow(
              label: 'Timestamps',
              value:
                  inspection.hasMonotonicTimestamps &&
                      !inspection.hasDuplicatedTimestamps
                  ? 'monotonic'
                  : 'invalid',
            ),
            if (inspection.warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Warnings', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              for (final warning in inspection.warnings)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(warning)),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Native inspection is complete. Real frame extraction and frame-by-frame calibration are the next implementation step.',
            ),
          ],
        ),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 132,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
