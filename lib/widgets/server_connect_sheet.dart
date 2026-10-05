import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../models/server_profile.dart';
import '../providers/settings_provider.dart';
import '../services/lm_studio_discovery_service.dart';
import '../services/lm_studio_service.dart';
import '../services/image_generation_facade.dart';
import '../services/server_profile_service.dart';
import '../utils/layout_utils.dart';
import '../utils/unsloth_load.dart';
import 'adaptive_modal.dart';
import 'home_glass_header.dart';
import 'shared_host_update_dialog.dart';

/// What the connect sheet is configuring.
sealed class ServerConnectTarget {
  const ServerConnectTarget();
}

final class ServerConnectLmStudio extends ServerConnectTarget {
  const ServerConnectLmStudio();
}

final class ServerConnectCloud extends ServerConnectTarget {
  final CloudApiType type;
  const ServerConnectCloud(this.type);
}

/// Guided glass bottom sheet to create or edit a server profile.
///
/// Calls [SettingsProvider.saveAndActivateServerProfile] after a successful
/// connection test (and syncs [CloudApiService] for cloud targets).
Future<bool?> showServerConnectSheet(
  BuildContext context, {
  required ServerConnectTarget target,
  ServerProfile? existing,
}) {
  return showAdaptiveModal<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    dialogMaxWidth: 560,
    builder: (ctx) => _ServerConnectSheet(
      target: target,
      existing: existing,
    ),
  );
}

class _ServerConnectSheet extends StatefulWidget {
  final ServerConnectTarget target;
  final ServerProfile? existing;

  const _ServerConnectSheet({
    required this.target,
    this.existing,
  });

  @override
  State<_ServerConnectSheet> createState() => _ServerConnectSheetState();
}

class _ServerConnectSheetState extends State<_ServerConnectSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final TextEditingController _keyController;

  bool _obscureKey = true;
  bool _saving = false;
  String? _status;
  bool _success = false;

  bool _headersEnabled = false;
  final List<_HeaderRow> _headerRows = [];

  bool _scanning = false;
  List<DiscoveredLmStudioServer> _discovered = const [];
  bool _fromDiscovery = false;

  static const _uuid = Uuid();

  bool get _isLmStudio => widget.target is ServerConnectLmStudio;

  CloudApiType? get _cloudType => switch (widget.target) {
        ServerConnectCloud(:final type) => type,
        ServerConnectLmStudio() => null,
      };

  bool get _needsUrl {
    if (_isLmStudio) return true;
    final t = _cloudType!;
    return t == CloudApiType.ollama ||
        t == CloudApiType.omlx ||
        t == CloudApiType.jan ||
        t == CloudApiType.unsloth ||
        t == CloudApiType.openaiCompatible;
  }

  DiscoveredServerKind? get _discoveryKind {
    if (_isLmStudio) return DiscoveredServerKind.lmStudio;
    return switch (_cloudType) {
      CloudApiType.ollama => DiscoveredServerKind.ollama,
      CloudApiType.unsloth => DiscoveredServerKind.unsloth,
      _ => null,
    };
  }

  bool get _showDiscovery => _discoveryKind != null;

  bool get _keyRequired {
    if (_isLmStudio) return false;
    final t = _cloudType!;
    if (t == CloudApiType.ollama) return false;
    if (t == CloudApiType.jan) return false;
    if (t == CloudApiType.unsloth) return false;
    if (t == CloudApiType.omlx) return true;
    return true;
  }

  bool get _supportsHeaders => true; // never on-device in this sheet

  String get _title {
    final editing = widget.existing != null;
    if (_isLmStudio) {
      return editing ? 'Edit LM Studio' : 'Connect LM Studio';
    }
    final name = _cloudType!.displayName;
    return editing ? 'Edit $name' : 'Connect $name';
  }

  String get _subtitle {
    if (_isLmStudio) {
      return 'Start the server on your computer, then connect from here.';
    }
    switch (_cloudType!) {
      case CloudApiType.ollama:
        return 'Run Ollama on your computer, then connect from here.';
      case CloudApiType.omlx:
        return 'Point LM Mini at your oMLX server.';
      case CloudApiType.jan:
        return 'Point LM Mini at the JAN AI app on your computer.';
      case CloudApiType.unsloth:
        return 'Pick a server we found, or enter the Unsloth address. The API key is optional until the server asks for one.';
      case CloudApiType.openaiCompatible:
        return 'Any server that speaks an A.I-compatible API.';
      default:
        return 'Add your API key to start chatting.';
    }
  }

  /// Short setup steps — no overlap with the subtitle or scan status.
  List<String> get _setupSteps {
    if (_isLmStudio) {
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        return const [
          'Open LM Studio → Developer → start the local server',
          'We’ll find it on this Mac (localhost), even on the same IP',
          'Or type http://127.0.0.1:1234 below — llama.cpp uses 8080',
        ];
      }
      return const [
        'Open LM Studio → Developer → start the local server',
        'Enable “Serve on Local Network”',
        'Stay on the same Wi‑Fi — we’ll find the IP, or type it below',
      ];
    }
    switch (_cloudType!) {
      case CloudApiType.ollama:
        return const [
          'Install and run Ollama on your computer',
          'Allow LAN access: set OLLAMA_HOST=0.0.0.0:11434 and restart',
          'Same Wi‑Fi — use your PC’s IP with port 11434',
        ];
      case CloudApiType.omlx:
        return const [
          'Start oMLX on your Mac',
          'Copy the API key from oMLX',
          'Enter the address below (default port 8000)',
        ];
      case CloudApiType.jan:
        return const [
          'Open JAN AI → Settings → Local API Server and start it',
          'Bind to 0.0.0.0 so phones on Wi‑Fi can connect (port 1337)',
          'Leave Execute Tools on Server off — LM Mini runs tools',
          'API key is optional; use your computer’s LAN IP from a phone',
        ];
      case CloudApiType.unsloth:
        return const [
          'Start Unsloth Studio on your computer (port 8888)',
          'We’ll look for it on this Wi‑Fi, or you can type the address',
          'API key is optional. If Unsloth asks for one, paste the sk-unsloth-… key',
          'LM Mini runs tools — leave Unsloth’s bash and python tools off',
        ];
      case CloudApiType.openaiCompatible:
        return const [
          'Enter the server base URL',
          'Paste the API key if the server requires one',
        ];
      case CloudApiType.openai:
        return const [
          'Create a key at platform.openai.com',
          'Paste it below',
        ];
      case CloudApiType.openRouter:
        return const [
          'Create a key at openrouter.ai',
          'Paste it below',
        ];
      case CloudApiType.vercelAiGateway:
        return const [
          'Create an AI Gateway key in your Vercel project',
          'Paste it below (base URL is set for you)',
        ];
      case CloudApiType.gemini:
        return const [
          'Create a key in Google AI Studio',
          'Paste it below',
        ];
      case CloudApiType.zAi:
        return const [
          'Create a key at z.ai',
          'Paste it below',
        ];
      case CloudApiType.mistral:
        return const [
          'Create a key at console.mistral.ai',
          'Paste it below',
        ];
      case CloudApiType.deepSeek:
        return const [
          'Create a key at platform.deepseek.com',
          'Paste it below',
        ];
      default:
        return const [
          'Enter the server base URL',
          'Paste the API key if the server requires one',
        ];
    }
  }

  String get _defaultUrl {
    if (_isLmStudio) {
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        return 'http://127.0.0.1:1234';
      }
      return 'http://192.168.1.';
    }
    switch (_cloudType!) {
      case CloudApiType.ollama:
        return 'http://localhost:11434';
      case CloudApiType.omlx:
        return 'http://localhost:8000';
      case CloudApiType.jan:
        return 'http://localhost:1337';
      case CloudApiType.unsloth:
        return 'http://localhost:8888';
      case CloudApiType.openaiCompatible:
        return '';
      default:
        return _cloudType!.defaultBaseUrl;
    }
  }

  String get _defaultName {
    if (_isLmStudio) return 'LM Studio';
    return _cloudType!.displayName;
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _urlController = TextEditingController(
      text: existing?.baseUrl?.trim().isNotEmpty == true
          ? existing!.baseUrl!
          : (_needsUrl ? _defaultUrl : ''),
    );
    _keyController = TextEditingController(text: existing?.apiKey ?? '');
    _headersEnabled = existing?.customHeadersEnabled ?? false;
    final headers = existing?.customHeaders;
    if (headers != null && headers.isNotEmpty) {
      for (final e in headers.entries) {
        _headerRows.add(_HeaderRow(e.key, e.value));
      }
    }

    if (_showDiscovery) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _keyController.dispose();
    for (final row in _headerRows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_scanning) return;
    setState(() {
      _scanning = true;
      _discovered = const [];
    });
    try {
      final results = await LmStudioDiscoveryService.instance.scanLocalNetwork(
        onFound: (soFar) {
          if (!mounted) return;
          _applyScanResults(soFar, scanning: true);
        },
      );
      if (!mounted) return;
      _applyScanResults(results, scanning: false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _scanning = false);
    }
  }

  void _applyScanResults(
    List<DiscoveredLmStudioServer> results, {
    required bool scanning,
  }) {
    final kind = _discoveryKind;
    if (kind == null) return;
    final matches = results.where((s) => s.kind == kind).toList();
    setState(() {
      _discovered = matches;
      _scanning = scanning;
      if (matches.isNotEmpty &&
          (widget.existing == null ||
              _urlController.text.trim().isEmpty ||
              _urlController.text == _defaultUrl)) {
        _urlController.text = matches.first.url;
        _fromDiscovery = true;
      }
    });
  }

  void _applyDiscovered(DiscoveredLmStudioServer s) {
    setState(() {
      _urlController.text = s.url;
      _fromDiscovery = true;
      _status = null;
      _success = false;
    });
  }

  Map<String, String>? _collectHeaders() {
    if (!_headersEnabled) return null;
    final map = <String, String>{};
    for (final row in _headerRows) {
      final k = row.keyController.text.trim();
      if (k.isEmpty) continue;
      map[k] = row.valueController.text;
    }
    return map.isEmpty ? null : map;
  }

  String _normalizeUrl(String raw) {
    var trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  Future<void> _connect() async {
    final urlRaw = _urlController.text.trim();
    final url = _needsUrl ? _normalizeUrl(urlRaw) : urlRaw;
    final key = _keyController.text.trim();

    if (_needsUrl && url.isEmpty) {
      setState(() {
        _status = 'Enter a server address.';
        _success = false;
      });
      return;
    }
    if (_keyRequired && key.isEmpty) {
      setState(() {
        _status = 'An API key is required.';
        _success = false;
      });
      return;
    }

    setState(() {
      _saving = true;
      _status = null;
      _success = false;
    });

    final settings = context.read<SettingsProvider>();
    final previousChatUrl = widget.existing?.baseUrl ??
        settings.lanChatBaseUrl() ??
        settings.settings.serverUrl;
    final previousImageUrl = settings.settings.imageGenServerUrl;
    try {
      final ok = await _testConnection(url: url, key: key);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _success = false;
          _status ??=
              'Couldn’t connect. Check the details and that the server is running.';
        });
        return;
      }

      final profile = _buildProfile(url: url, key: key);
      if (!_isLmStudio) {
        await _syncCloudProvider(profile);
      }

      final activated = await settings.saveAndActivateServerProfile(profile);
      if (!mounted) return;

      if (activated) {
        setState(() {
          _success = true;
          _status = widget.existing != null ? 'Saved.' : 'Connected.';
        });
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (mounted) {
          final changedName =
              _isLmStudio ? 'LM Studio' : (_cloudType?.displayName ?? 'chat');
          await maybeOfferSharedHostUpdate(
            context,
            previousChangedUrl: previousChatUrl,
            newChangedUrl: url,
            peerUrl: previousImageUrl,
            peer: SharedHostPeer.imageGen,
            changedName: changedName,
            peerName: imageGenBackendLabel(settings.settings),
          );
        }
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() {
          _success = false;
          _status = 'Saved, but couldn’t switch to this server.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _success = false;
        _status = 'Couldn’t connect. $e';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _testConnection({
    required String url,
    required String key,
  }) async {
    if (_isLmStudio) {
      final result = await LMStudioService().testConnection(
        url,
        apiToken: key.isEmpty ? null : key,
      );
      if (result['success'] == true) return true;
      if (result['authError'] == true) {
        _status =
            'Server found, but it needs an API key. Paste it above and try again.';
        return false;
      }
      _status = (result['error'] as String?) ??
          'Couldn’t connect. Check the address and that LM Studio is running.';
      return false;
    }

    final type = _cloudType!;
    final cloud = CloudApiService();
    final id = widget.existing?.id ??
        '${type.name}_${DateTime.now().millisecondsSinceEpoch}';
    final provider = CloudApiProvider(
      id: id,
      name: _nameController.text.trim().isEmpty
          ? type.displayName
          : _nameController.text.trim(),
      type: type,
      apiKey: key,
      baseUrl: url.isNotEmpty
          ? url
          : (type.defaultBaseUrl.isEmpty ? null : type.defaultBaseUrl),
      selectedModel: cloud.providers
          .where((p) => p.id == id)
          .map((p) => p.selectedModel)
          .firstOrNull,
      isEnabled: true,
    );

    final ok = await cloud.testConnection(provider);
    if (!ok) {
      if (type == CloudApiType.unsloth &&
          UnslothLoad.connectionNeedsApiKey(cloud.lastConnectionError)) {
        _status = UnslothLoad.authFailureMessage(hadKey: key.isNotEmpty);
      } else {
        _status = cloud.lastConnectionError ??
            'Couldn’t connect. Check your key and that the service is available.';
      }
    }
    return ok;
  }

  ServerProfile _buildProfile({
    required String url,
    required String key,
  }) {
    final existing = widget.existing;
    final name = _nameController.text.trim().isEmpty
        ? _defaultName
        : _nameController.text.trim();
    final headers = _collectHeaders();

    if (_isLmStudio) {
      return ServerProfile(
        id: existing?.id ?? _uuid.v4(),
        name: name,
        kind: ServerProfileKind.lmStudio,
        baseUrl: url,
        apiKey: key.isEmpty ? null : key,
        customHeaders: headers,
        customHeadersEnabled: _headersEnabled,
        lastUsedAt: DateTime.now(),
      );
    }

    final type = _cloudType!;
    final id =
        existing?.id ?? '${type.name}_${DateTime.now().millisecondsSinceEpoch}';
    return ServerProfile(
      id: id,
      name: name,
      kind: ServerProfileKind.cloud,
      cloudType: type,
      baseUrl: url.isNotEmpty
          ? url
          : (type.defaultBaseUrl.isEmpty ? null : type.defaultBaseUrl),
      apiKey: key.isEmpty ? null : key,
      customHeaders: headers,
      customHeadersEnabled: _headersEnabled,
      lastUsedAt: DateTime.now(),
    );
  }

  Future<void> _syncCloudProvider(ServerProfile profile) async {
    final type = profile.cloudType!;
    final cloud = CloudApiService();
    final existing =
        cloud.providers.where((p) => p.id == profile.id).firstOrNull;
    final provider = CloudApiProvider(
      id: profile.id,
      name: profile.name,
      type: type,
      apiKey: profile.apiKey ?? '',
      baseUrl: profile.baseUrl,
      selectedModel: existing?.selectedModel,
      isEnabled: true,
      customHeaders: profile.customHeaders,
      customHeadersEnabled: profile.customHeadersEnabled,
    );
    await cloud.saveProvider(provider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final wide = prefersWideSettingsLayout(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final canvas = isDark ? const Color(0xFF12151C) : const Color(0xFFF4F6FA);
    final fg = isDark ? Colors.white : Colors.black.withValues(alpha: 0.88);
    final muted = fg.withValues(alpha: 0.62);

    return GlassCanvas(
      onLightCanvas: !isDark,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * (wide ? 0.85 : 0.9),
          ),
          decoration: BoxDecoration(
            color: canvas.withValues(alpha: 0.96),
            borderRadius: wide
                ? BorderRadius.circular(24)
                : const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!wide)
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: fg.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  Text(
                    _title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 14),
                  _SetupGuideCard(steps: _setupSteps, fg: fg),
                  if (_showDiscovery) ...[
                    const SizedBox(height: 14),
                    _DiscoverySection(
                      scanning: _scanning,
                      discovered: _discovered,
                      fg: fg,
                      onRefresh: _startScan,
                      onSelect: _applyDiscovered,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: fg),
                    decoration: _fieldDecoration(
                      label: 'Name (optional)',
                      hint: _defaultName,
                      fg: fg,
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  if (_needsUrl ||
                      (_cloudType != null &&
                          !_cloudType!.isLocalOpenAiCompatible &&
                          _cloudType != CloudApiType.openaiCompatible)) ...[
                    const SizedBox(height: 12),
                    if (_needsUrl)
                      TextField(
                        controller: _urlController,
                        style: TextStyle(color: fg),
                        decoration: _fieldDecoration(
                          label: _fromDiscovery
                              ? 'Server address (found nearby)'
                              : 'Server address',
                          hint: _defaultUrl.isEmpty
                              ? 'https://your-server.com'
                              : _defaultUrl,
                          fg: fg,
                          prefix: Icons.link_rounded,
                          emphasizeGood: _fromDiscovery,
                        ),
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        onChanged: (_) {
                          if (_fromDiscovery) {
                            setState(() => _fromDiscovery = false);
                          }
                        },
                      )
                    else
                      Theme(
                        data: theme.copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: EdgeInsets.zero,
                          leading:
                              Icon(Icons.link_rounded, size: 20, color: muted),
                          title: Text(
                            'Custom URL (optional)',
                            style: TextStyle(
                              color: muted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          children: [
                            TextField(
                              controller: _urlController,
                              style: TextStyle(color: fg, fontSize: 13),
                              decoration: _fieldDecoration(
                                label: 'Base URL',
                                hint: _cloudType!.defaultBaseUrl,
                                fg: fg,
                              ),
                              keyboardType: TextInputType.url,
                              autocorrect: false,
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _keyController,
                    obscureText: _obscureKey,
                    style: TextStyle(color: fg),
                    decoration: _fieldDecoration(
                      label: _keyRequired ? 'API key' : 'API key (optional)',
                      fg: fg,
                      prefix: Icons.key_rounded,
                      suffix: IconButton(
                        onPressed: () =>
                            setState(() => _obscureKey = !_obscureKey),
                        icon: Icon(
                          _obscureKey
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: muted,
                        ),
                      ),
                    ),
                    autocorrect: false,
                  ),
                  if (_supportsHeaders) ...[
                    const SizedBox(height: 8),
                    Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 4),
                        leading:
                            Icon(Icons.http_rounded, size: 20, color: muted),
                        title: Text(
                          'Headers (optional)',
                          style: TextStyle(
                            color: muted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Send custom headers',
                              style: TextStyle(color: fg, fontSize: 14),
                            ),
                            subtitle: Text(
                              'For reverse proxies or special auth.',
                              style: TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                            value: _headersEnabled,
                            onChanged: (v) =>
                                setState(() => _headersEnabled = v),
                          ),
                          if (_headersEnabled) ...[
                            const SizedBox(height: 4),
                            for (var i = 0; i < _headerRows.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller:
                                            _headerRows[i].keyController,
                                        style:
                                            TextStyle(color: fg, fontSize: 13),
                                        decoration: _fieldDecoration(
                                          label: 'Name',
                                          hint: 'X-Custom',
                                          fg: fg,
                                          dense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 3,
                                      child: TextField(
                                        controller:
                                            _headerRows[i].valueController,
                                        style:
                                            TextStyle(color: fg, fontSize: 13),
                                        decoration: _fieldDecoration(
                                          label: 'Value',
                                          fg: fg,
                                          dense: true,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _headerRows[i].dispose();
                                          _headerRows.removeAt(i);
                                        });
                                      },
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: muted,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() => _headerRows.add(_HeaderRow()));
                              },
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add header'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (_status != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _status!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _success
                            ? const Color(0xFF00B894)
                            : theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _connect,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.existing != null ? 'Save' : 'Connect',
                          ),
                  ),
                  if (widget.existing != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _saving ? null : _deleteExisting,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: const Text('Delete server'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteExisting() async {
    final existing = widget.existing;
    if (existing == null || !existing.isDeletable) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete server?'),
        content: Text(
          CloudApiType.warnBeforeRemoving(existing.cloudType)
              ? AppLocalizations.of(context)
                  .deleteFirstPartyOpenAiServerMessage(existing.name)
              : 'Remove “${existing.name}” from this device? '
                  'You can add it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      final wasActive = ServerProfileService.instance.activeId == existing.id;
      await ServerProfileService.instance.delete(existing.id);
      if (existing.kind == ServerProfileKind.cloud) {
        await CloudApiService().removeProvider(existing.id);
      }
      if (wasActive && mounted) {
        await context
            .read<SettingsProvider>()
            .activateServerProfile(ServerProfile.onDeviceId);
      }
      if (mounted) Navigator.pop(context, false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required Color fg,
    String? hint,
    IconData? prefix,
    Widget? suffix,
    bool dense = false,
    bool emphasizeGood = false,
  }) {
    final muted = fg.withValues(alpha: 0.6);
    const good = Color(0xFF10B981);
    final accent = emphasizeGood ? good : muted;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        color: accent,
        fontWeight: emphasizeGood ? FontWeight.w600 : null,
      ),
      hintStyle: TextStyle(color: fg.withValues(alpha: 0.35)),
      isDense: dense,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: emphasizeGood ? good : fg.withValues(alpha: 0.22),
          width: emphasizeGood ? 1.6 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: emphasizeGood ? good : Theme.of(context).colorScheme.primary,
          width: 1.8,
        ),
      ),
      prefixIcon: prefix == null ? null : Icon(prefix, size: 20, color: accent),
      suffixIcon: suffix ??
          (emphasizeGood
              ? const Icon(Icons.check_circle_rounded, color: good, size: 20)
              : null),
    );
  }
}

class _HeaderRow {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _HeaderRow([String key = '', String value = ''])
      : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value);

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class _SetupGuideCard extends StatelessWidget {
  final List<String> steps;
  final Color fg;

  const _SetupGuideCard({required this.steps, required this.fg});

  @override
  Widget build(BuildContext context) {
    final muted = fg.withValues(alpha: 0.58);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick setup',
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: fg.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: fg,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    steps[i],
                    style: TextStyle(
                      color: muted,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DiscoverySection extends StatelessWidget {
  final bool scanning;
  final List<DiscoveredLmStudioServer> discovered;
  final Color fg;
  final VoidCallback onRefresh;
  final ValueChanged<DiscoveredLmStudioServer> onSelect;

  const _DiscoverySection({
    required this.scanning,
    required this.discovered,
    required this.fg,
    required this.onRefresh,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final muted = fg.withValues(alpha: 0.62);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (scanning)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.wifi_tethering_rounded, size: 18, color: muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  scanning
                      ? (discovered.isEmpty
                          ? 'Looking on this Mac and Wi‑Fi…'
                          : 'Found a server — still checking Wi‑Fi…')
                      : discovered.isEmpty
                          ? 'No servers found nearby'
                          : 'Found nearby',
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (!scanning)
                IconButton(
                  tooltip: 'Scan again',
                  onPressed: onRefresh,
                  icon: Icon(Icons.refresh_rounded, color: muted, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (scanning && discovered.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Checking localhost first, then your Wi‑Fi.',
              style: TextStyle(color: muted, fontSize: 12.5),
            ),
          ],
          if (discovered.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...discovered.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: fg.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Icon(
                      s.thisMachine
                          ? Icons.computer_rounded
                          : Icons.lan_rounded,
                      color: fg,
                      size: 20,
                    ),
                    title: Text(s.listTitle,
                        style: TextStyle(color: fg, fontSize: 13.5)),
                    subtitle: Text(
                      s.listSubtitle,
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: fg.withValues(alpha: 0.4),
                    ),
                    onTap: () => onSelect(s),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
