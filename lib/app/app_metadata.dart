import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const _packageId = 'com.w3artists.pacelens';

class AppVersionInfo {
  const AppVersionInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
  });

  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;

  String get displayVersion {
    if (buildNumber.isEmpty || buildNumber == version) {
      return 'v$version';
    }
    return 'v$version+$buildNumber';
  }

  static const fallback = AppVersionInfo(
    appName: 'PaceLens',
    packageName: _packageId,
    version: '1.0.0',
    buildNumber: '1',
  );
}

class AppUpdateStatus {
  const AppUpdateStatus({
    required this.localVersion,
    required this.storeVersion,
    required this.storeUri,
    this.releaseNotes,
  });

  final String localVersion;
  final String storeVersion;
  final Uri storeUri;
  final String? releaseNotes;
}

final appVersionInfoProvider = FutureProvider<AppVersionInfo>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return AppVersionInfo(
      appName: info.appName,
      packageName: info.packageName,
      version: info.version,
      buildNumber: info.buildNumber,
    );
  } catch (_) {
    return AppVersionInfo.fallback;
  }
});

final appUpdateStatusProvider = FutureProvider<AppUpdateStatus?>((ref) async {
  if (!kReleaseMode || kIsWeb) {
    return null;
  }

  try {
    final info = await PackageInfo.fromPlatform();
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _checkGooglePlay(info),
      TargetPlatform.iOS => _checkAppStore(info),
      _ => null,
    };
  } catch (_) {
    return null;
  }
});

Future<AppUpdateStatus?> _checkAppStore(PackageInfo info) async {
  final lookupUri = Uri.https('itunes.apple.com', '/lookup', {
    'bundleId': _packageId,
    'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
  });
  final response = await http.get(lookupUri);
  if (response.statusCode != 200) {
    return null;
  }

  final payload = jsonDecode(response.body) as Map<String, dynamic>;
  final results = payload['results'] as List<dynamic>? ?? const [];
  if (results.isEmpty) {
    return null;
  }

  final app = results.first as Map<String, dynamic>;
  final storeVersion = _cleanVersion(app['version']?.toString() ?? '');
  final storeUrl = app['trackViewUrl']?.toString();
  if (storeVersion.isEmpty || storeUrl == null) {
    return null;
  }

  return _updateStatusOrNull(
    localVersion: info.version,
    storeVersion: storeVersion,
    storeUri: Uri.parse(storeUrl),
    releaseNotes: app['releaseNotes']?.toString(),
  );
}

Future<AppUpdateStatus?> _checkGooglePlay(PackageInfo info) async {
  final storeUri = Uri.https('play.google.com', '/store/apps/details', {
    'id': _packageId,
    'hl': 'en_US',
    'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
  });
  final response = await http.get(storeUri);
  if (response.statusCode != 200) {
    return null;
  }

  final match = RegExp(
    r'\[\[\[\"(\d+\.\d+(\.[a-z]+)?(\.([^"]|\\")*)?)\"\]\]',
  ).firstMatch(response.body);
  final storeVersion = _cleanVersion(match?.group(1) ?? '');
  if (storeVersion.isEmpty) {
    return null;
  }

  return _updateStatusOrNull(
    localVersion: info.version,
    storeVersion: storeVersion,
    storeUri: storeUri,
  );
}

AppUpdateStatus? _updateStatusOrNull({
  required String localVersion,
  required String storeVersion,
  required Uri storeUri,
  String? releaseNotes,
}) {
  final cleanLocal = _cleanVersion(localVersion);
  final cleanStore = _cleanVersion(storeVersion);
  if (cleanLocal.isEmpty || cleanStore.isEmpty) {
    return null;
  }
  if (!_isNewerVersion(cleanStore, cleanLocal)) {
    return null;
  }
  return AppUpdateStatus(
    localVersion: cleanLocal,
    storeVersion: cleanStore,
    storeUri: storeUri,
    releaseNotes: releaseNotes,
  );
}

String _cleanVersion(String version) {
  return RegExp(r'\d+(\.\d+)?(\.\d+)?').stringMatch(version) ?? '';
}

bool _isNewerVersion(String storeVersion, String localVersion) {
  final store = _versionParts(storeVersion);
  final local = _versionParts(localVersion);
  for (var index = 0; index < store.length; index++) {
    if (store[index] > local[index]) {
      return true;
    }
    if (store[index] < local[index]) {
      return false;
    }
  }
  return false;
}

List<int> _versionParts(String version) {
  final parts = version.split('.').map((part) => int.tryParse(part) ?? 0);
  return [...parts, 0, 0, 0].take(3).toList();
}

class PaceLensAppChrome extends ConsumerWidget {
  const PaceLensAppChrome({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        child,
        Positioned(
          right: 8,
          bottom: 8,
          child: SafeArea(
            minimum: const EdgeInsets.only(bottom: 4),
            child: _VersionBadge(
              version: ref.watch(appVersionInfoProvider),
              update: ref.watch(appUpdateStatusProvider),
            ),
          ),
        ),
      ],
    );
  }
}

class _VersionBadge extends StatelessWidget {
  const _VersionBadge({required this.version, required this.update});

  final AsyncValue<AppVersionInfo> version;
  final AsyncValue<AppUpdateStatus?> update;

  @override
  Widget build(BuildContext context) {
    final versionText = version.maybeWhen(
      data: (info) => info.displayVersion,
      orElse: () => 'v...',
    );
    final updateStatus = update.maybeWhen(
      data: (status) => status,
      orElse: () => null,
    );

    if (updateStatus != null) {
      return FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          textStyle: Theme.of(context).textTheme.labelSmall,
        ),
        icon: const Icon(Icons.system_update_alt, size: 16),
        label: Text('$versionText · Update ${updateStatus.storeVersion}'),
        onPressed: () => _showUpdateDialog(context, updateStatus),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          versionText,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Future<void> _showUpdateDialog(
    BuildContext context,
    AppUpdateStatus status,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Available'),
          content: Text(
            'A newer PaceLens version is available: ${status.storeVersion}. '
            'You are using ${status.localVersion}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await launchUrl(
                  status.storeUri,
                  mode: LaunchMode.externalApplication,
                );
                navigator.pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
