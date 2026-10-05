import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../debug_log_buffer.dart';
import '../desktop_platform.dart';
import '../host/desktop_host_service.dart';
import '../runtime/desktop_runtime_manager.dart';
import '../../pro/pro_features.dart';
import '../../screens/analytics_screen.dart';

/// Categories shown in the Nerds tab list panel.
enum _NerdsCategory { logs, analytics, runtime, relay, services }

/// Lightweight dev console for the desktop shell Nerds tab.
///
/// Column 2: category list.
/// Column 3: detail pane for the selected category.
class NerdsShellContent extends StatefulWidget {
  const NerdsShellContent({super.key});

  @override
  State<NerdsShellContent> createState() => _NerdsShellContentState();
}

class _NerdsShellContentState extends State<NerdsShellContent> {
  // Logs stays in the enum / detail switch for the next build review.
  // Analytics is a Pro screen: listed only when Pro is compiled in.
  List<_NerdsCategory> get _visibleCategories => [
        if (ProFeatures.included) _NerdsCategory.analytics,
        _NerdsCategory.runtime,
        _NerdsCategory.relay,
        _NerdsCategory.services,
      ];

  _NerdsCategory _selected = _NerdsCategory.runtime;

  @override
  void initState() {
    super.initState();
    final visible = _visibleCategories;
    if (!visible.contains(_selected)) _selected = visible.first;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0E1117) : colorScheme.surface;

    return ColoredBox(
      color: bg,
      child: Row(
        children: [
          SizedBox(
            width: 240,
            child: _buildCategoryList(context),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: _buildDetail(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1117) : cs.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Nerds',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          ..._visibleCategories.map((cat) {
            final active = cat == _selected;
            return ListTile(
              dense: true,
              selected: active,
              selectedTileColor: cs.primaryContainer.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              leading: Icon(_iconFor(cat), size: 20),
              title: Text(_labelFor(cat)),
              onTap: () => setState(() => _selected = cat),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetail(BuildContext context) {
    switch (_selected) {
      case _NerdsCategory.logs:
        return const _LogsDetail();
      case _NerdsCategory.analytics:
        return const AnalyticsScreen(embedded: true);
      case _NerdsCategory.runtime:
        return const _RuntimeDetail();
      case _NerdsCategory.relay:
        return const _RelayDetail();
      case _NerdsCategory.services:
        return const _ServicesDetail();
    }
  }

  IconData _iconFor(_NerdsCategory cat) {
    switch (cat) {
      case _NerdsCategory.logs:
        return Icons.article_outlined;
      case _NerdsCategory.analytics:
        return Icons.insights_outlined;
      case _NerdsCategory.runtime:
        return Icons.memory_rounded;
      case _NerdsCategory.relay:
        return ProFeatures.included
            ? Icons.cloud_sync_rounded
            : Icons.usb_rounded;
      case _NerdsCategory.services:
        return Icons.dns_outlined;
    }
  }

  String _labelFor(_NerdsCategory cat) {
    switch (cat) {
      case _NerdsCategory.logs:
        return 'Logs';
      case _NerdsCategory.analytics:
        return 'Analytics';
      case _NerdsCategory.runtime:
        return 'Runtime';
      case _NerdsCategory.relay:
        // The public build shares over USB only (no relay).
        return ProFeatures.included ? 'Relay' : 'Host';
      case _NerdsCategory.services:
        return 'Services';
    }
  }
}

/// Shows llama-server sidecar runtime status.
class _RuntimeDetail extends StatelessWidget {
  const _RuntimeDetail();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (!DesktopPlatform.supportsSidecarRuntime) {
      return Center(
        child: Text('Runtime not available on this platform',
            style: theme.textTheme.bodyLarge?.copyWith(color: cs.outline)),
      );
    }

    return ListenableBuilder(
      listenable: DesktopRuntimeManager.instance,
      builder: (context, _) {
        final rt = DesktopRuntimeManager.instance;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('llama-server Runtime',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _StatusRow(
              label: 'Status',
              value: rt.isRunning
                  ? 'Running'
                  : (rt.isStarting ? 'Starting...' : 'Stopped'),
              color: rt.isRunning ? Colors.green : cs.outline,
            ),
            _StatusRow(label: 'Port', value: rt.port.toString()),
            _StatusRow(label: 'URL', value: rt.baseUrl),
            if (rt.lastError != null)
              _StatusRow(label: 'Error', value: rt.lastError!, color: cs.error),
            const SizedBox(height: 20),
            Row(
              children: [
                if (!rt.isRunning)
                  FilledButton.tonalIcon(
                    onPressed: () => rt.ensureBuiltinRunning(),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Start'),
                  ),
                if (rt.isRunning) ...[
                  FilledButton.tonalIcon(
                    onPressed: () => rt.stop(),
                    icon: const Icon(Icons.stop_rounded, size: 18),
                    label: const Text('Stop'),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Shows relay/host connection status.
class _RelayDetail extends StatelessWidget {
  const _RelayDetail();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!DesktopPlatform.supportsHostMode) {
      return Center(
        child: Text('Host mode not available',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.outline)),
      );
    }

    return ListenableBuilder(
      listenable: DesktopHostService.instance,
      builder: (context, _) {
        final host = DesktopHostService.instance;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(ProFeatures.included ? 'Desktop Host & Relay' : 'Desktop Host',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _StatusRow(
              label: 'Enabled',
              value: host.isEnabled ? 'Yes' : 'No',
              color: host.isEnabled ? Colors.green : null,
            ),
            _StatusRow(
              label: 'USB',
              value: host.isUsbPeerConnected
                  ? 'iPhone connected'
                  : 'Not connected',
              color: host.isUsbPeerConnected ? Colors.green : null,
            ),
            if (ProFeatures.included) ...[
              _StatusRow(
                label: 'Relay',
                value: host.isRelayConnected ? 'Connected' : 'Disconnected',
                color: host.isRelayConnected ? Colors.green : null,
              ),
              _StatusRow(
                label: 'Session',
                value: host.sessionId ?? 'None',
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Live debug log viewer backed by [DebugLogBuffer].
class _LogsDetail extends StatefulWidget {
  const _LogsDetail();

  @override
  State<_LogsDetail> createState() => _LogsDetailState();
}

enum _LogFilter { all, errors, info }

class _ParsedLog {
  final _LogLevel level;
  final String text;

  const _ParsedLog(this.level, this.text);
}

enum _LogLevel { debug, info, warn, error }

class _LogsDetailState extends State<_LogsDetail> {
  final _scrollController = ScrollController();
  _LogFilter _filter = _LogFilter.all;
  bool _pinToBottom = true;

  @override
  void initState() {
    super.initState();
    DebugLogBuffer.instance.install();
    DebugLogBuffer.instance.addListener(_onLogs);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    DebugLogBuffer.instance.removeListener(_onLogs);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    _pinToBottom = pos.pixels >= pos.maxScrollExtent - 48;
  }

  void _onLogs() {
    if (!mounted) return;
    setState(() {});
    if (!_pinToBottom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  _ParsedLog _parse(String raw) {
    final text = raw.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
    final lower = text.toLowerCase();
    if (lower.contains('exception') ||
        lower.contains('error') ||
        lower.contains('failed') ||
        lower.contains('fatal')) {
      return _ParsedLog(_LogLevel.error, text);
    }
    if (lower.contains('warning') || lower.contains('warn')) {
      return _ParsedLog(_LogLevel.warn, text);
    }
    if (lower.contains('success') ||
        lower.contains('connected') ||
        lower.contains('initialized') ||
        lower.contains('listening')) {
      return _ParsedLog(_LogLevel.info, text);
    }
    return _ParsedLog(_LogLevel.debug, text);
  }

  Color _colorFor(_LogLevel level, ColorScheme cs) {
    return switch (level) {
      _LogLevel.error => const Color(0xFFF87171),
      _LogLevel.warn => const Color(0xFFFBBF24),
      _LogLevel.info => const Color(0xFF34D399),
      _LogLevel.debug => cs.onSurface.withValues(alpha: 0.55),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final parsed = DebugLogBuffer.instance.lines.map(_parse).toList();
    final visible = parsed.where((line) {
      return switch (_filter) {
        _LogFilter.all => true,
        _LogFilter.errors =>
          line.level == _LogLevel.error || line.level == _LogLevel.warn,
        _LogFilter.info =>
          line.level == _LogLevel.info || line.level == _LogLevel.debug,
      };
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          child: Row(
            children: [
              Text('Logs',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              Text(
                '${visible.length}',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Copy all',
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                      text: visible.map((e) => e.text).join('\n')));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logs copied')),
                  );
                },
              ),
              IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                onPressed: () => DebugLogBuffer.instance.clear(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Wrap(
            spacing: 8,
            children: [
              for (final filter in _LogFilter.values)
                ChoiceChip(
                  label: Text(switch (filter) {
                    _LogFilter.all => 'All',
                    _LogFilter.errors => 'Issues',
                    _LogFilter.info => 'Quiet',
                  }),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B0E14) : const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: visible.isEmpty
                ? Center(
                    child: Text(
                      'No logs yet — app output appears here.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.outline),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                    itemCount: visible.length,
                    itemBuilder: (context, i) {
                      final line = visible[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: SelectableText(
                          line.text,
                          style: TextStyle(
                            fontFamily: 'Menlo',
                            fontFamilyFallback: const [
                              'SF Mono',
                              'monospace',
                            ],
                            fontSize: 12,
                            height: 1.45,
                            color: _colorFor(line.level, cs),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

/// Shows service probe status from DesktopHostService.
class _ServicesDetail extends StatelessWidget {
  const _ServicesDetail();

  String _stateLabel(DesktopServiceState state) {
    switch (state) {
      case DesktopServiceState.online:
        return 'Online';
      case DesktopServiceState.offline:
        return 'Offline';
      case DesktopServiceState.checking:
        return 'Checking...';
      case DesktopServiceState.disabled:
        return 'Disabled';
      case DesktopServiceState.unknown:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!DesktopPlatform.supportsHostMode) {
      return Center(
        child: Text('Service probing not available',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.outline)),
      );
    }

    return ListenableBuilder(
      listenable: DesktopHostService.instance,
      builder: (context, _) {
        final host = DesktopHostService.instance;
        final services = host.services;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Text('Local Services',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => host.probeServices(),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (services.isEmpty)
              Text('No services configured.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline))
            else
              ...services.map((s) => _StatusRow(
                    label: s.label,
                    value: _stateLabel(s.state),
                    color: s.state == DesktopServiceState.online
                        ? Colors.green
                        : (s.state == DesktopServiceState.checking
                            ? Colors.orange
                            : null),
                  )),
          ],
        );
      },
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatusRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium?.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}
