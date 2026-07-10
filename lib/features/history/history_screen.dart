import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../core/storage/storage_providers.dart';
import '../../domain/entities/delivery_result_record.dart';

final historyProvider = StreamProvider<List<DeliveryResultRecord>>((ref) {
  return ref.watch(appDatabaseProvider).watchResults();
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Previous results')),
      body: history.when(
        data: (records) {
          if (records.isEmpty) {
            return const Center(child: Text('No saved results yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final record = records[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.speed),
                  title: Text(
                    record.releaseSpeedKph == null
                        ? 'Failed analysis'
                        : '${record.releaseSpeedKph!.round()} km/h',
                  ),
                  subtitle: Text(
                    '${record.createdAt.toLocal()} • ${confidenceLabel(record.confidence)} • '
                    '${record.sourceFps.toStringAsFixed(0)} FPS',
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemCount: records.length,
          );
        },
        error: (error, stackTrace) =>
            Center(child: Text('Could not load history: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
