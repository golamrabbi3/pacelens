import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/platform/platform_providers.dart';
import '../../domain/entities/camera_capture_profile.dart';
import '../home/home_screen.dart';

final cameraProfilesProvider = FutureProvider<List<CameraCaptureProfile>>((
  ref,
) {
  return ref.watch(highSpeedCameraPlatformProvider).getSupportedProfiles();
});

class CameraSetupScreen extends ConsumerWidget {
  const CameraSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(cameraProfilesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Camera setup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(experimentalWarning),
          const SizedBox(height: 16),
          const _SetupChecklist(),
          const SizedBox(height: 16),
          Text(
            'Native capability query',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          profiles.when(
            data: (profiles) {
              if (profiles.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No 60 FPS or higher camera profile was reported. PaceLens will not silently fall back below 60 FPS.',
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final profile in profiles)
                    Card(
                      child: ListTile(
                        title: Text(profile.label),
                        subtitle: Text(
                          'Camera ${profile.cameraId} • min ${profile.minimumFps.toStringAsFixed(0)} FPS • '
                          '${profile.isHighSpeed ? 'high-speed' : 'standard'} • '
                          '${profile.supportsStableTimestamps ? 'stable timestamps' : 'timestamp risk'}',
                        ),
                        leading: Icon(
                          profile.isUsable ? Icons.check_circle : Icons.warning,
                          color: profile.isUsable
                              ? Colors.lightGreenAccent
                              : Colors.orangeAccent,
                        ),
                      ),
                    ),
                ],
              );
            },
            error: (error, stackTrace) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Capability query failed: $error'),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.videocam),
            label: const Text('Open recording screen'),
            onPressed: () => context.push('/record'),
          ),
        ],
      ),
    );
  }
}

class _SetupChecklist extends StatelessWidget {
  const _SetupChecklist();

  @override
  Widget build(BuildContext context) {
    const items = [
      'Mount the phone on a tripod.',
      'Position it side-on to the pitch.',
      'Keep the measurement region visible.',
      'Use bright lighting.',
      'Avoid digital zoom.',
      'Use 120 or 240 FPS.',
      'Record in landscape orientation.',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Before recording',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
