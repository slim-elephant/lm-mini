import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../pro/pro_features.dart';
import '../../providers/settings_provider.dart';
import '../../services/kokoro_model_manager.dart';
import '../../utils/layout_utils.dart';
import '../../widgets/desktop_settings_controls.dart';
import '../../widgets/glass_settings_scaffold.dart';
import '../desktop_platform.dart';
import '../host/desktop_host_service.dart';
import '../runtime/desktop_runtime_manager.dart';

/// Desktop-only “Share with phone” host panel (Connect merge UI shell).
class DesktopHostScreen extends StatefulWidget {
  final bool embedded;
  const DesktopHostScreen({super.key, this.embedded = false});

  @override
  State<DesktopHostScreen> createState() => _DesktopHostScreenState();
}

class _DesktopHostScreenState extends State<DesktopHostScreen> {
  final _host = DesktopHostService.instance;
  final _runtime = DesktopRuntimeManager.instance;
  final _kokoroModels = KokoroModelManager();
  bool _binaryReady = false;
  bool _kokoroModelReady = false;
  bool _kokoroDownloading = false;
  double _kokoroDownloadProgress = 0;

  String get _here => DesktopPlatform.thisMachine;

  late final TextEditingController _a1111Ctrl;
  late final TextEditingController _comfyCtrl;

  @override
  void initState() {
    super.initState();
    _a1111Ctrl = TextEditingController();
    _comfyCtrl = TextEditingController();
    _host.addListener(_onChanged);
    _runtime.addListener(_onChanged);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _host.ensureLoaded();
    if (!mounted) return;
    final settings = context.read<SettingsProvider>().settings;
    _host.syncFromAppSettings(settings);
    _syncControllers();
    await _refreshBinary();
    await _refreshKokoroModel();
    unawaited(_host.probeServices());
  }

  Future<void> _refreshKokoroModel() async {
    final ready = await _kokoroModels.isModelReady();
    if (!mounted) return;
    setState(() {
      _kokoroModelReady = ready;
      _kokoroDownloading = _kokoroModels.isDownloading;
      _kokoroDownloadProgress = _kokoroModels.downloadProgress;
    });
  }

  Future<void> _downloadKokoro() async {
    setState(() {
      _kokoroDownloading = true;
      _kokoroDownloadProgress = 0;
    });
    final sub = _kokoroModels.progressStream.listen((p) {
      if (mounted) setState(() => _kokoroDownloadProgress = p);
    });
    final ok = await _kokoroModels.downloadModel();
    await sub.cancel();
    if (!mounted) return;
    setState(() {
      _kokoroDownloading = false;
      _kokoroModelReady = ok;
    });
    if (ok && _host.kokoroEnabled) {
      await _host.ensureKokoroShared();
    }
  }

  Future<void> _onShareKokoro(bool enabled) async {
    if (enabled && !_kokoroModelReady && !_kokoroDownloading) {
      unawaited(_downloadKokoro());
    }
    await _host.setKokoroEnabled(enabled);
  }

  void _syncControllers() {
    _a1111Ctrl.text = _host.a1111Url;
    _comfyCtrl.text = _host.comfyUiUrl;
  }

  @override
  void dispose() {
    _host.removeListener(_onChanged);
    _runtime.removeListener(_onChanged);
    _a1111Ctrl.dispose();
    _comfyCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshBinary() async {
    final path = await _runtime.resolveBinaryPath();
    if (!mounted) return;
    setState(() => _binaryReady = path != null);
  }

  Widget _toggleRow({
    IconData? icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return DesktopPreferenceRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _navRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return DesktopPreferenceRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  Widget _sectionHint(String text, ColorScheme cs) {
    return Text(
      text,
      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
    );
  }

  /// Phone Remote Access is Pro; this Mac screen is not gated.
  Widget _phoneNeedsProNote(ColorScheme cs) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.orange,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'The phone needs LM Mini Pro to scan. Without it, Remote Access '
              'opens the paywall instead of pairing.',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _serviceColor(DesktopServiceState state, ColorScheme cs) {
    switch (state) {
      case DesktopServiceState.online:
        return const Color(0xFF34C759);
      case DesktopServiceState.offline:
        return cs.onSurfaceVariant;
      case DesktopServiceState.checking:
      case DesktopServiceState.unknown:
      case DesktopServiceState.disabled:
        return cs.onSurfaceVariant.withValues(alpha: 0.5);
    }
  }

  String _serviceStateLabel(DesktopServiceState state) {
    switch (state) {
      case DesktopServiceState.online:
        return 'Connected';
      case DesktopServiceState.offline:
        return 'Not running';
      case DesktopServiceState.checking:
        return 'Checking…';
      case DesktopServiceState.unknown:
        return '—';
      case DesktopServiceState.disabled:
        return 'Off';
    }
  }

  Widget _serviceRow(DesktopServiceStatus s, ColorScheme cs) {
    // Builtin boots on demand, so "offline" really means "ready to start".
    final readyOnDemand =
        s.readyOnDemand && s.state == DesktopServiceState.offline;
    final color = readyOnDemand ? cs.primary : _serviceColor(s.state, cs);
    final statusText = readyOnDemand ? 'Ready' : _serviceStateLabel(s.state);
    final statusColor = (s.isOnline || readyOnDemand)
        ? (s.isOnline ? const Color(0xFF34C759) : cs.primary)
        : cs.onSurfaceVariant;
    final subtitle = [
      if (s.detail != null && s.detail!.isNotEmpty) s.detail!,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: s.state == DesktopServiceState.checking
                ? const CircularProgressIndicator(strokeWidth: 2)
                : Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: (s.isOnline || readyOnDemand)
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _connectedServicesSection(ColorScheme cs) {
    final visible = _host.services
        .where((s) => s.state != DesktopServiceState.disabled)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('Connected services')),
            if (_host.isProbing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Re-check services',
                icon: Icon(Icons.refresh_rounded,
                    size: 18, color: cs.onSurfaceVariant),
                onPressed: () => _host.probeServices(),
              ),
          ],
        ),
        const SizedBox(height: 4),
        _sectionHint(
          !ProFeatures.included
              ? (_host.isUsbPeerConnected
                  ? 'Local services on $_here. Your iPhone connected via USB can use them.'
                  : 'Local services on $_here. Connect your iPhone with a USB cable to use them.')
              : _host.isEnabled && !_host.isRelayConnected
                  ? 'These are local services on $_here. Phones cannot use them until Share with phone says Connected.'
                  : 'Local services on $_here. Phones can use them only while Share with phone is Connected.',
          cs,
        ),
        const SizedBox(height: 8),
        GlassSettingsCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: visible.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No services enabled yet. Turn on a model source below.',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < visible.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            indent: 40,
                            color: cs.outlineVariant.withValues(alpha: 0.4),
                          ),
                        _serviceRow(visible[i], cs),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _encryptionCard(BuildContext context, ColorScheme cs) {
    final key = _host.encryptionKey;
    final hasKey = key != null && key.isNotEmpty;
    String obscure(String value) {
      if (value.length <= 8) return '\u2022' * value.length;
      return '${value.substring(0, 4)}${'\u2022' * 8}${value.substring(value.length - 4)}';
    }

    return GlassSettingsCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Encryption key',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  hasKey ? 'On' : 'Off',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasKey ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Phones must use this same key. Change it here if you want a custom one.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
            ),
            if (hasKey) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        obscure(key),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: key));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Encryption key copied')),
                        );
                      },
                      icon:
                          Icon(Icons.copy_rounded, size: 16, color: cs.primary),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _editEncryptionKey(context),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit encryption key'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editEncryptionKey(BuildContext context) async {
    final controller = TextEditingController(text: _host.encryptionKey ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encryption key'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Paste a key, or leave blank to generate a new one',
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (saved == null) return;
    await _host.setEncryptionKey(saved);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Encryption key updated')),
    );
  }

  Widget _qrPanel(ColorScheme cs, String? qrJson) {
    if (!ProFeatures.included) {
      return GlassSettingsCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2_rounded,
                size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'Pairing your phone over the internet is available in the '
              'official LM Mini app. USB mode and your LAN servers work in '
              'this build.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
            ),
          ],
        ),
      );
    }
    if (!_host.isEnabled || qrJson == null) {
      return GlassSettingsCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2_rounded,
                size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'Turn on “Connect with phone” to reveal the QR code.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
            ),
          ],
        ),
      );
    }
    if (!_host.isRelayConnected) {
      return GlassSettingsCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _host.isRelayConnecting
                  ? 'Connecting to relay…'
                  : (_host.statusMessage ?? 'Connecting to relay…'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The QR appears once $_here is reachable. Scanning earlier '
              'will time out on the phone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _host.reconnectRelay(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reconnect'),
            ),
            const SizedBox(height: 6),
            _phoneNeedsProNote(cs),
          ],
        ),
      );
    }
    return GlassSettingsCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_scanner_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Scan from the phone app',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'LM Mini → Remote Access → Scan. Traffic tunnels through the relay '
              'to $_here.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 10),
          _phoneNeedsProNote(cs),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: QrImageView(
              data: qrJson,
              size: 208,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              final url = _host.pairingUrl ?? _host.phoneUrl;
              if (url == null) return;
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Copied pairing link — paste it in Remote Access if the camera is unavailable',
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _host.phoneUrl ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.copy_rounded, size: 15, color: cs.primary),
                ],
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => _host.rotateSession(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('New session'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!DesktopPlatform.supportsHostMode) {
      return GlassSettingsScaffold(
        embedded: widget.embedded,
        title: 'Share with phone',
        body: const Center(
          child: Text('Host mode is only available on the desktop app.'),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final qrJson = _host.isEnabled ? _host.buildQrPayloadJson() : null;
    final desktop = prefersWideSettingsLayout(context);

    final languageModels = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('Language models'),
        const SizedBox(height: 8),
        GlassSettingsCard(
          child: DesktopSettingsGrid(
            children: [
              _toggleRow(
                icon: Icons.computer_rounded,
                title: 'LM Mini Home',
                subtitle: _binaryReady
                    ? 'Bundled models on $_here'
                    : 'Runtime ships with the app — update LM Mini if this stays unavailable',
                value: _host.advertiseBuiltin,
                onChanged: _host.setAdvertiseBuiltin,
              ),
              _toggleRow(
                icon: Icons.science_outlined,
                title: 'LM Studio',
                subtitle: 'Proxy localhost:1234',
                value: _host.advertiseLmStudio,
                onChanged: _host.setAdvertiseLmStudio,
              ),
              _toggleRow(
                icon: Icons.terminal_rounded,
                title: 'Ollama',
                subtitle: 'Proxy localhost:11434',
                value: _host.advertiseOllama,
                onChanged: _host.setAdvertiseOllama,
              ),
              _toggleRow(
                icon: Icons.memory_rounded,
                title: 'oMLX',
                value: _host.advertiseOmlx,
                onChanged: _host.setAdvertiseOmlx,
              ),
              _toggleRow(
                icon: Icons.bolt_rounded,
                title: 'JAN AI',
                subtitle: 'Proxy localhost:1337',
                value: _host.advertiseJan,
                onChanged: _host.setAdvertiseJan,
              ),
              _toggleRow(
                icon: Icons.science_rounded,
                title: 'Unsloth',
                subtitle: 'Proxy localhost:8888',
                value: _host.advertiseUnsloth,
                onChanged: _host.setAdvertiseUnsloth,
              ),
            ],
          ),
        ),
      ],
    );

    final imageGeneration = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('Image generation'),
        const SizedBox(height: 4),
        _sectionHint(
          'Phone image requests (`/sdapi/` or ComfyUI paths) are proxied when a URL is set.',
          cs,
        ),
        const SizedBox(height: 8),
        GlassSettingsCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: DesktopSettingsGrid(
              children: [
                TextField(
                  controller: _a1111Ctrl,
                  decoration: const InputDecoration(
                    labelText: 'AUTOMATIC1111 / Forge',
                    hintText: 'http://127.0.0.1:7860',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onEditingComplete: () => _host.setA1111Url(_a1111Ctrl.text),
                  onTapOutside: (_) => _host.setA1111Url(_a1111Ctrl.text),
                ),
                TextField(
                  controller: _comfyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ComfyUI',
                    hintText: 'http://127.0.0.1:8188',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onEditingComplete: () => _host.setComfyUiUrl(_comfyCtrl.text),
                  onTapOutside: (_) => _host.setComfyUiUrl(_comfyCtrl.text),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final usbSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('USB (cable)'),
        const SizedBox(height: 4),
        _sectionHint(
          _host.isUsbAvailable == false
              ? 'This Mac App Store build is sandboxed, so USB cable mode is unavailable here. '
                  'Share with phone (QR) above still works. '
                  'For USB, download LM Mini for Mac from lmmini.com.'
              : 'When the phone enables USB Mode, this Mac dials it over the cable.',
          cs,
        ),
        const SizedBox(height: 8),
        GlassSettingsCard(
          child: Column(
            children: [
              _toggleRow(
                icon: Icons.usb_rounded,
                title: 'USB bridge',
                subtitle: _host.isUsbPeerConnected
                    ? 'iPhone connected via USB'
                    : (_host.isUsbRunning
                        ? 'Waiting for iPhone USB Mode…'
                        : (_host.usbLastError ??
                            (_host.isUsbAvailable == false
                                ? 'Blocked by App Store sandbox'
                                : 'Off'))),
                value: _host.usbEnabled,
                onChanged:
                    _host.isUsbAvailable == false ? null : _host.setUsbEnabled,
              ),
              if (_host.isUsbAvailable == false) ...[
                const SizedBox(height: 2),
                _navRow(
                  icon: Icons.download_rounded,
                  title: 'Download LM Mini from the web',
                  subtitle: 'lmmini.com — full Mac build with USB support',
                  trailing: Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  onTap: () => launchUrl(
                    Uri.parse('https://lmmini.com/download.html#mac-usb'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    final voiceSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('Voice (Kokoro TTS)'),
        const SizedBox(height: 4),
        _sectionHint(
          'Same TTS packs as Voice Settings. Download languages once, then '
          'phones use them on this Wi‑Fi or over QR.',
          cs,
        ),
        const SizedBox(height: 8),
        GlassSettingsCard(
          child: Column(
            children: [
              _toggleRow(
                icon: Icons.record_voice_over_rounded,
                title: 'Share Kokoro TTS',
                subtitle: _host.isKokoroServerRunning
                    ? 'Phones on this Wi‑Fi can use it (port ${_host.kokoroPort})'
                    : (_kokoroModelReady
                        ? 'Ready — same voices as Voice Settings'
                        : 'Download the Voice Settings model to share'),
                value: _host.kokoroEnabled,
                onChanged: _onShareKokoro,
              ),
              if (_host.kokoroEnabled) ...[
                if (_kokoroDownloading)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: _kokoroDownloadProgress > 0
                              ? _kokoroDownloadProgress
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Downloading Kokoro… ${(_kokoroDownloadProgress * 100).round()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (!_kokoroModelReady)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: _downloadKokoro,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Download Kokoro model'),
                      ),
                    ),
                  )
                else if (_host.kokoroServerError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      _host.kokoroServerError!,
                      style: TextStyle(color: cs.error, fontSize: 12),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );

    final relayConnected = _host.isRelayConnected;
    final enableCard = GlassSettingsCard(
      child: Column(
        children: [
          _toggleRow(
            icon: Icons.phonelink_rounded,
            title: 'Connect with phone',
            subtitle: _host.isEnabled
                ? (!ProFeatures.included
                    ? (_host.isUsbPeerConnected
                        ? 'Sharing over USB — iPhone connected'
                        : 'Sharing over USB — connect your iPhone with a cable')
                    : relayConnected
                        ? 'Connected — phones can use $_here'
                        : (_host.statusMessage ?? 'Connecting…'))
                : 'Off — phone cannot reach $_here yet',
            value: _host.isEnabled,
            onChanged: _host.setEnabled,
          ),
          if (_host.isEnabled && ProFeatures.included)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Icon(
                    relayConnected
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_sync_rounded,
                    size: 18,
                    color: relayConnected ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      relayConnected
                          ? (DesktopPlatform.isMacOS
                              ? 'Relay connected · menu bar icon stays while sharing'
                              : 'Relay connected · tray icon stays while sharing')
                          : (_host.isRelayConnecting
                              ? 'Connecting to relay…'
                              : (_host.statusMessage ?? 'Waiting for relay')),
                      style:
                          TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                  ),
                  if (_host.isEnabled && !relayConnected)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Reconnect',
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                      onPressed: () => _host.reconnectRelay(),
                    ),
                ],
              ),
            ),
        ],
      ),
    );

    final heroLeft = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        enableCard,
        const SizedBox(height: 16),
        _connectedServicesSection(cs),
      ],
    );

    final runtimeCard = GlassSettingsCard(
      child: DesktopPreferenceRow(
        icon: _runtime.isRunning ? Icons.memory_rounded : Icons.memory_outlined,
        title: _runtime.isRunning
            ? 'Desktop runtime running'
            : 'Desktop runtime idle',
        subtitle: _runtime.isRunning
            ? 'Port ${_runtime.port} · ${(_runtime.loadedModelPath ?? 'model').split(RegExp(r'[\\/]')).last}'
            : (_runtime.lastError ??
                'Starts on demand when $_here or a phone uses a GGUF model'),
        trailing: _runtime.isRunning
            ? TextButton(
                onPressed: () => _runtime.stop(),
                child: const Text('Stop'),
              )
            : TextButton(
                onPressed: _refreshBinary,
                child: const Text('Refresh'),
              ),
      ),
    );

    return GlassSettingsScaffold(
      embedded: widget.embedded,
      title: 'Connect with phone',
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          desktop ? 0 : 16,
          desktop ? 12 : 20,
          desktop ? 0 : 16,
          36,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: desktop ? 1040 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Let LM Mini on your phone use models, image gen, and TTS on '
                    '$_here — same role as LM Mini Connect.',
                    style: TextStyle(color: cs.onSurfaceVariant, height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  if (desktop)
                    SettingsTwoColumn(
                      leftFlex: 3,
                      rightFlex: 2,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      left: heroLeft,
                      right: Column(
                        children: [
                          _qrPanel(cs, qrJson),
                          // The key only protects relay pairing.
                          if (ProFeatures.included) ...[
                            const SizedBox(height: 16),
                            _encryptionCard(context, cs),
                          ],
                        ],
                      ),
                    )
                  else ...[
                    enableCard,
                    const SizedBox(height: 16),
                    _qrPanel(cs, qrJson),
                    if (ProFeatures.included) ...[
                      const SizedBox(height: 16),
                      _encryptionCard(context, cs),
                    ],
                    const SizedBox(height: 20),
                    _connectedServicesSection(cs),
                  ],
                  const SizedBox(height: 24),
                  if (desktop)
                    SettingsTwoColumn(
                      left: languageModels,
                      right: imageGeneration,
                    )
                  else ...[
                    languageModels,
                    const SizedBox(height: 20),
                    imageGeneration,
                  ],
                  const SizedBox(height: 20),
                  if (DesktopPlatform.isMacOS) ...[
                    if (desktop)
                      SettingsTwoColumn(
                        left: usbSection,
                        right: voiceSection,
                      )
                    else ...[
                      usbSection,
                      const SizedBox(height: 20),
                      voiceSection,
                    ],
                  ] else ...[
                    voiceSection,
                  ],
                  const SizedBox(height: 24),
                  runtimeCard,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
