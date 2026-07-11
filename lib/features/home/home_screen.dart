import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../analysis/analysis_controller.dart';

const experimentalWarning =
    'PaceLens provides an experimental camera-based moving-object speed estimate. Results depend on camera placement, frame rate, lighting, calibration, timestamp quality, tracking accuracy, and perspective. It is not a certified radar-speed measurement system.';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('PaceLens')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Moving-object speed analysis',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            experimentalWarning,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _HomeAction(
            icon: Icons.videocam,
            title: 'Measure moving object',
            subtitle: 'Use OpenCV live motion tracking with a fixed camera.',
            onTap: () => context.push('/setup'),
          ),
          _HomeAction(
            icon: Icons.video_file,
            title: 'Analyse existing video',
            subtitle:
                'Use only footage with valid timestamps and at least 60 FPS.',
            onTap: () => context.push('/import'),
          ),
          _HomeAction(
            icon: Icons.history,
            title: 'Previous results',
            subtitle:
                'Local saved analyses only. Video bytes are not stored in the database.',
            onTap: () => context.push('/history'),
          ),
          _HomeAction(
            icon: Icons.rule,
            title: 'Setup guide',
            subtitle: 'Tripod, side-on view, bright lighting, 120 or 240 FPS.',
            onTap: () => context.push('/setup'),
          ),
          if (kDebugMode)
            _HomeAction(
              icon: Icons.science,
              title: 'Synthetic debug analysis',
              subtitle:
                  'Generated moving-dot trajectory with known timestamps and speed.',
              onTap: () {
                ref.read(analysisWorkflowProvider.notifier).resetSynthetic();
                context.push('/calibration');
              },
            ),
        ],
      ),
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
