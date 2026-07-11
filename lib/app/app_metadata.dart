import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_version_plus/model/version_status.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

final appUpdateStatusProvider = FutureProvider<VersionStatus?>((ref) async {
  if (!kReleaseMode || kIsWeb) {
    return null;
  }

  try {
    final newVersion = NewVersionPlus(
      androidId: _packageId,
      iOSId: _packageId,
      androidPlayStoreCountry: 'en_US',
      androidHtmlReleaseNotes: true,
    );
    final status = await newVersion.getVersionStatus();
    if (status?.canUpdate == true) {
      return status;
    }
  } catch (_) {
    return null;
  }

  return null;
});

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
  final AsyncValue<VersionStatus?> update;

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

  void _showUpdateDialog(BuildContext context, VersionStatus status) {
    NewVersionPlus(
      androidId: _packageId,
      iOSId: _packageId,
      androidPlayStoreCountry: 'en_US',
      androidHtmlReleaseNotes: true,
    ).showUpdateDialog(
      context: context,
      versionStatus: status,
      dialogTitle: 'Update Available',
      dialogText:
          'A newer PaceLens version is available: ${status.storeVersion}. '
          'You are using ${status.localVersion}.',
      updateButtonText: 'Update',
      dismissButtonText: 'Later',
      launchModeVersion: LaunchModeVersion.external,
    );
  }
}
