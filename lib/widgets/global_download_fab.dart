import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../services/local_model_download_service.dart';
import '../services/local_sd_asset_download_service.dart';
import '../services/model_download_service.dart';
import '../models/model_download_job.dart';

/// Global download indicator. Stateful so speed text can be throttled — otherwise
/// every byte/s tick rebuilds the pill and it visually flashes.
class GlobalDownloadFAB extends StatefulWidget {
  /// Bottom of the screen header. When set, the pill straddles that edge
  /// (~30% on the bar, ~70% on the content below).
  final double? headerBottom;

  const GlobalDownloadFAB({super.key, this.headerBottom});

  @override
  State<GlobalDownloadFAB> createState() => _GlobalDownloadFABState();
}

class _GlobalDownloadFABState extends State<GlobalDownloadFAB> {
  String _stableStatus = '';
  int? _lastSpeed;
  DateTime _lastSpeedSample = DateTime.fromMillisecondsSinceEpoch(0);

  /// Separate from speed sampling — must not reset on every non-zero speed tick
  /// or Android (which reports continuous B/s) freezes the label after ~1%.
  DateTime _lastStatusPaint = DateTime.fromMillisecondsSinceEpoch(0);

  String _statusLabel({
    required double? progressValue,
    required int? bytesPerSecond,
    required String fallback,
  }) {
    if (progressValue == null) return fallback;
    final pct = '${(progressValue * 100).toStringAsFixed(0)}%';

    // Keep last known speed briefly so 0-spikes don't collapse the label.
    final now = DateTime.now();
    var speed = bytesPerSecond;
    if (speed != null && speed > 0) {
      _lastSpeed = speed;
      _lastSpeedSample = now;
    } else if (_lastSpeed != null &&
        now.difference(_lastSpeedSample) < const Duration(seconds: 2)) {
      speed = _lastSpeed;
    } else {
      speed = null;
      _lastSpeed = null;
    }

    // Quantize speed display so tiny changes don't relayout every tick.
    final compact = _compactSpeed(speed);
    final next = compact != null ? '$pct · $compact' : pct;

    // Throttle visible status updates to ~4 Hz (paint clock, not speed clock).
    if (next != _stableStatus) {
      final elapsed = now.difference(_lastStatusPaint);
      if (_stableStatus.isEmpty ||
          elapsed >= const Duration(milliseconds: 250)) {
        _stableStatus = next;
        _lastStatusPaint = now;
      }
    }
    return _stableStatus.isEmpty ? next : _stableStatus;
  }

  String? _compactSpeed(int? bytesPerSec) {
    if (bytesPerSec == null || bytesPerSec <= 0) return null;
    // Round to reduce flicker (0.1 MB or whole KB steps).
    if (bytesPerSec < 1024) return '$bytesPerSec B/s';
    if (bytesPerSec < 1024 * 1024) {
      final kb = (bytesPerSec / 1024).round();
      return '$kb KB/s';
    }
    final mb = (bytesPerSec / (1024 * 1024) * 10).round() / 10;
    return '${mb.toStringAsFixed(1)} MB/s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localDownloads = LocalModelDownloadService.instance;
    final sdDownloads = LocalSdAssetDownloadService.instance;
    final modelDownloads = ModelDownloadService.instance;
    return ListenableBuilder(
      listenable:
          Listenable.merge([localDownloads, sdDownloads, modelDownloads]),
      builder: (context, _) {
        return Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            final assetJob = modelDownloads.firstActiveJob;

            LocalModelEntry? onDeviceActive;
            for (final e in localDownloads.entries) {
              if (e.status == LocalModelStatus.downloading) {
                onDeviceActive = e;
                break;
              }
            }
            LocalSdAssetEntry? sdActive;
            for (final e in sdDownloads.entries) {
              if (e.status == LocalSdAssetStatus.downloading) {
                sdActive = e;
                break;
              }
            }
            final hasAsset = assetJob != null;
            final hasOnDevice = onDeviceActive != null;
            final hasSd = sdActive != null;
            final hasLmStudio = settingsProvider.isDownloading &&
                settingsProvider.downloadJobId != null;

            if (!hasAsset && !hasOnDevice && !hasSd && !hasLmStudio) {
              _stableStatus = '';
              _lastSpeed = null;
              return const SizedBox.shrink();
            }

            String label;
            double? progressValue;
            String statusLabel;
            VoidCallback onTap;
            VoidCallback? onCancel;

            if (hasAsset) {
              final job = assetJob;
              progressValue = job.progress > 0 ? job.progress : null;
              label = job.displayName;
              statusLabel = _statusLabel(
                progressValue: progressValue,
                bytesPerSecond: job.bytesPerSecond,
                fallback: job.status == ModelDownloadJobStatus.extracting
                    ? 'Extracting…'
                    : 'Starting…',
              );
              onTap = () => _showAssetDetails(context, job.id);
            } else if (hasOnDevice) {
              final e = onDeviceActive;
              progressValue = e.progress > 0 ? e.progress : null;
              label = e.spec.displayName;
              statusLabel = _statusLabel(
                progressValue: progressValue,
                bytesPerSecond: e.bytesPerSecond,
                fallback: 'Starting…',
              );
              onTap = () =>
                  _showOnDeviceDetails(context, localDownloads, e.spec.id);
            } else if (hasSd) {
              final e = sdActive;
              progressValue = e.progress > 0 ? e.progress : null;
              label = e.spec.displayName;
              statusLabel = _statusLabel(
                progressValue: progressValue,
                bytesPerSecond: e.bytesPerSecond,
                fallback: 'Starting…',
              );
              onTap = () => _showSdDetails(context, sdDownloads, e.spec.id);
            } else {
              final progress =
                  settingsProvider.downloadStatus?['downloaded_bytes'] as int?;
              final total =
                  settingsProvider.downloadStatus?['total_size_bytes'] as int?;
              progressValue = (progress != null && total != null && total > 0)
                  ? progress / total
                  : null;
              final status =
                  settingsProvider.downloadStatus?['status'] as String? ??
                      'downloading';
              final speed =
                  settingsProvider.downloadStatus?['bytes_per_second'] as num?;
              label =
                  settingsProvider.downloadModelLabel ?? l10n.downloadNewModel;
              statusLabel = _statusLabel(
                progressValue: progressValue,
                bytesPerSecond: speed?.round(),
                fallback: status,
              );
              onTap = () => _showLmStudioDetails(context);
              onCancel =
                  () => _cancelLmStudioDownload(context, settingsProvider);
            }

            final topInset = MediaQuery.paddingOf(context).top;
            final headerBottom = widget.headerBottom;
            // ~48px pill: sit 30% on the header, 70% on the sheet below.
            final top =
                headerBottom != null ? headerBottom - 48 * 0.30 : topInset + 8;
            return Positioned(
              top: top,
              left: 16,
              right: 16,
              child: Center(
                child: _buildFAB(
                  context,
                  label: label,
                  statusLabel: statusLabel,
                  progressValue: progressValue,
                  onTap: onTap,
                  onCancel: onCancel,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFAB(
    BuildContext context, {
    required String label,
    required String statusLabel,
    required double? progressValue,
    required VoidCallback onTap,
    VoidCallback? onCancel,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progressValue,
                            strokeWidth: 2.5,
                            color: scheme.primary,
                            backgroundColor: scheme.primary.withOpacity(0.15),
                          ),
                          Icon(Icons.download_outlined,
                              size: 12, color: scheme.onPrimaryContainer),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: 220, minWidth: 120),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: scheme.onPrimaryContainer,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            height: 14,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: scheme.onPrimaryContainer
                                      .withOpacity(0.85),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onCancel != null)
              IconButton(
                tooltip: l10n.cancel,
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                color: scheme.onPrimaryContainer,
                onPressed: onCancel,
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
      ),
    );
  }

  void _showAssetDetails(BuildContext context, String jobId) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        return ListenableBuilder(
          listenable: ModelDownloadService.instance,
          builder: (ctx, _) {
            final job = ModelDownloadService.instance.job(jobId);
            if (job == null || !job.isActive) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(AppLocalizations.of(ctx).downloadFinished),
              );
            }
            final pct = job.progress;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(value: pct > 0 ? pct : null),
                    const SizedBox(height: 8),
                    Text(
                      '${(pct * 100).toStringAsFixed(1)}%'
                      '${job.bytesPerSecond > 0 ? '  ·  ${_compactSpeed(job.bytesPerSecond)!}' : ''}',
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                        child: Text(AppLocalizations.of(ctx).close),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSdDetails(
    BuildContext context,
    LocalSdAssetDownloadService svc,
    String specId,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        return ListenableBuilder(
          listenable: svc,
          builder: (ctx, _) {
            final entry = svc.entryById(specId);
            if (entry == null ||
                entry.status != LocalSdAssetStatus.downloading) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(AppLocalizations.of(ctx).downloadFinished),
              );
            }
            final pct = entry.progress;
            final l10n = AppLocalizations.of(ctx);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.spec.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(value: pct > 0 ? pct : null),
                    const SizedBox(height: 8),
                    Text(
                      '${(pct * 100).toStringAsFixed(1)}%'
                      '${entry.bytesPerSecond > 0 ? '  ·  ${_compactSpeed(entry.bytesPerSecond)!}' : ''}',
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.cancel_outlined),
                          label: Text(l10n.cancel),
                          onPressed: () {
                            svc.cancel(specId);
                            Navigator.of(sheetCtx).pop();
                          },
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                          child: Text(l10n.close),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showOnDeviceDetails(
    BuildContext context,
    LocalModelDownloadService svc,
    String specId,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        return ListenableBuilder(
          listenable: svc,
          builder: (ctx, _) {
            final entry = svc.entryById(specId);
            final l10n = AppLocalizations.of(ctx);
            if (entry == null) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.downloadFinished),
              );
            }
            final pct = entry.progress;
            final done = entry.status == LocalModelStatus.ready;
            final failed = entry.status == LocalModelStatus.failed;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(
                        done
                            ? Icons.check_circle
                            : failed
                                ? Icons.error
                                : Icons.cloud_download_outlined,
                        color: done
                            ? Colors.green
                            : failed
                                ? Colors.red
                                : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.spec.displayName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(value: pct > 0 ? pct : null),
                    const SizedBox(height: 8),
                    Text('${(pct * 100).toStringAsFixed(1)}%  ·  '
                        '${_fmt(entry.bytesDownloaded)} / '
                        '${_fmt(entry.bytesTotal ?? entry.spec.sizeMb * 1024 * 1024)}'
                        '${entry.bytesPerSecond > 0 ? '  ·  ${_compactSpeed(entry.bytesPerSecond)!}' : ''}'),
                    if (failed && entry.errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        entry.errorMessage!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (entry.status == LocalModelStatus.downloading)
                          TextButton.icon(
                            icon: const Icon(Icons.cancel_outlined),
                            label: Text(l10n.cancel),
                            onPressed: () {
                              svc.cancel(specId);
                              Navigator.of(sheetCtx).pop();
                            },
                          ),
                        TextButton(
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                          child: Text(l10n.close),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLmStudioDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Consumer<SettingsProvider>(
        builder: (dialogBodyContext, settingsProvider, child) {
          final progress =
              settingsProvider.downloadStatus?['downloaded_bytes'] as int?;
          final total =
              settingsProvider.downloadStatus?['total_size_bytes'] as int?;
          final speed =
              settingsProvider.downloadStatus?['bytes_per_second'] as num?;
          final estimatedCompletion = settingsProvider
              .downloadStatus?['estimated_completion'] as String?;
          final status =
              settingsProvider.downloadStatus?['status'] as String? ??
                  'downloading';

          final progressValue = (progress != null && total != null && total > 0)
              ? progress / total
              : 0.0;

          int? etaSeconds;
          if (estimatedCompletion != null) {
            try {
              final completionTime = DateTime.parse(estimatedCompletion);
              etaSeconds = completionTime.difference(DateTime.now()).inSeconds;
              if (etaSeconds < 0) etaSeconds = 0;
            } catch (_) {}
          }

          return AlertDialog(
            title: Row(children: [
              Icon(
                status == 'completed'
                    ? Icons.check_circle
                    : status == 'failed'
                        ? Icons.error
                        : Icons.download,
                color: status == 'completed'
                    ? Colors.green
                    : status == 'failed'
                        ? Colors.red
                        : Theme.of(dialogBodyContext).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(dialogBodyContext).downloadProgress),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progressValue),
                const SizedBox(height: 8),
                Text('${(progressValue * 100).toStringAsFixed(1)}%'),
                const SizedBox(height: 16),
                _row(
                    dialogBodyContext,
                    AppLocalizations.of(dialogBodyContext).progressLabel,
                    '${_fmt(progress)} / ${_fmt(total)}'),
                _row(
                    dialogBodyContext,
                    AppLocalizations.of(dialogBodyContext).speedLabel,
                    _formatSpeed(speed, dialogBodyContext)),
                _row(
                    dialogBodyContext,
                    AppLocalizations.of(dialogBodyContext).etaLabel,
                    _formatTime(etaSeconds, dialogBodyContext)),
                _row(dialogBodyContext,
                    AppLocalizations.of(dialogBodyContext).statusLabel, status),
              ],
            ),
            actions: [
              if (status != 'completed' &&
                  status != 'failed' &&
                  status != 'cancelled' &&
                  status != 'canceled')
                TextButton.icon(
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(AppLocalizations.of(dialogBodyContext).cancel),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await _cancelLmStudioDownload(context, settingsProvider);
                  },
                ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(AppLocalizations.of(dialogBodyContext).close),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _cancelLmStudioDownload(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await settingsProvider.cancelLmStudioDownload();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? l10n.downloadCancelled : l10n.downloadCancelFailed,
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _fmt(int? bytes) {
    if (bytes == null) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatSpeed(num? bytesPerSec, BuildContext context) {
    if (bytesPerSec == null || bytesPerSec <= 0) {
      return AppLocalizations.of(context).calculating;
    }
    final bps = bytesPerSec.toDouble();
    if (bps < 1024) return '${bps.toStringAsFixed(0)} B/s';
    if (bps < 1024 * 1024) {
      return '${(bps / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bps / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String _formatTime(int? seconds, BuildContext context) {
    if (seconds == null || seconds <= 0) {
      return AppLocalizations.of(context).calculating;
    }
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).toStringAsFixed(0)}m';
    return '${(seconds / 3600).toStringAsFixed(1)}h';
  }
}
