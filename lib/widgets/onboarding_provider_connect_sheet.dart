import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:provider/provider.dart';

import '../models/lm_studio_model.dart';
import '../models/server_profile.dart';
import '../providers/settings_provider.dart';
import '../services/lm_studio_discovery_service.dart';
import '../services/lm_studio_service.dart';
import '../utils/unsloth_load.dart';
import 'home_glass_header.dart';
import 'package:uuid/uuid.dart';

enum OnboardingProviderKind { lmStudio, ollama, omlx, jan, unsloth }

/// Glass bottom sheet to connect LM Studio, Ollama, oMLX, or Jan during onboarding.
Future<bool?> showOnboardingProviderConnectSheet({
  required BuildContext context,
  required OnboardingProviderKind kind,
  required List<DiscoveredLmStudioServer> discovered,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _OnboardingProviderConnectSheet(
      kind: kind,
      discovered: discovered,
    ),
  );
}

class _OnboardingProviderConnectSheet extends StatefulWidget {
  final OnboardingProviderKind kind;
  final List<DiscoveredLmStudioServer> discovered;

  const _OnboardingProviderConnectSheet({
    required this.kind,
    required this.discovered,
  });

  @override
  State<_OnboardingProviderConnectSheet> createState() =>
      _OnboardingProviderConnectSheetState();
}

class _OnboardingProviderConnectSheetState
    extends State<_OnboardingProviderConnectSheet> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _keyController;
  bool _obscureKey = true;
  bool _testing = false;
  String? _status;
  bool _success = false;

  /// True when host/port came from Wi‑Fi discovery (show green “looks good”).
  bool _fromDiscovery = false;

  DiscoveredServerKind? get _scanKind => switch (widget.kind) {
        OnboardingProviderKind.lmStudio => DiscoveredServerKind.lmStudio,
        OnboardingProviderKind.ollama => DiscoveredServerKind.ollama,
        OnboardingProviderKind.omlx => null,
        OnboardingProviderKind.jan => null,
        OnboardingProviderKind.unsloth => DiscoveredServerKind.unsloth,
      };

  List<DiscoveredLmStudioServer> get _matches {
    final k = _scanKind;
    if (k == null) return const [];
    return widget.discovered.where((s) => s.kind == k).toList();
  }

  String get _title => switch (widget.kind) {
        OnboardingProviderKind.lmStudio => 'Connect LM Studio',
        OnboardingProviderKind.ollama => 'Connect Ollama',
        OnboardingProviderKind.omlx => 'Connect oMLX',
        OnboardingProviderKind.jan => 'Connect JAN AI',
        OnboardingProviderKind.unsloth => 'Connect Unsloth',
      };

  String get _subtitle => switch (widget.kind) {
        OnboardingProviderKind.lmStudio =>
          'Pick a server we found on Wi‑Fi, or enter the address yourself.',
        OnboardingProviderKind.ollama =>
          'Pick a server we found on Wi‑Fi, or enter the address yourself.',
        OnboardingProviderKind.omlx =>
          'Enter the address of your oMLX server. An API key is required.',
        OnboardingProviderKind.jan =>
          'Enter the address of your JAN AI server (port 1337). API key is optional.',
        OnboardingProviderKind.unsloth =>
          'Pick a server we found, or enter the Unsloth address (port 8888). The API key is optional until the server asks for one.',
      };

  int get _defaultPort => switch (widget.kind) {
        OnboardingProviderKind.lmStudio => 1234,
        OnboardingProviderKind.ollama => 11434,
        OnboardingProviderKind.omlx => 8000,
        OnboardingProviderKind.jan => 1337,
        OnboardingProviderKind.unsloth => 8888,
      };

  bool get _keyRequired => widget.kind == OnboardingProviderKind.omlx;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().settings;
    String host = (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
        ? 'http://127.0.0.1'
        : 'http://192.168.1.';
    String port = '$_defaultPort';
    String key = '';

    if (widget.kind == OnboardingProviderKind.lmStudio &&
        settings.serverUrl.isNotEmpty) {
      final parsed = _splitHostPort(settings.serverUrl);
      host = parsed.host;
      port = parsed.port ?? port;
      key = settings.apiToken ?? '';
    } else if (_matches.isNotEmpty) {
      final first = _matches.first;
      host = 'http://${first.host}';
      port = '${first.port}';
      _fromDiscovery = true;
    } else if (widget.kind == OnboardingProviderKind.omlx ||
        widget.kind == OnboardingProviderKind.jan ||
        widget.kind == OnboardingProviderKind.unsloth) {
      host = 'http://localhost';
    }

    _hostController = TextEditingController(text: host);
    _portController = TextEditingController(text: port);
    _keyController = TextEditingController(text: key);
    _hostController.addListener(_onManualEdit);
    _portController.addListener(_onManualEdit);
  }

  void _onManualEdit() {
    if (!_fromDiscovery) return;
    // Keep green while values still match a discovered server.
    final url = _buildUrl();
    final stillMatch = _matches.any((s) =>
        s.url == url ||
        (s.host ==
                _hostController.text
                    .trim()
                    .replaceFirst(RegExp(r'^https?://'), '') &&
            '${s.port}' == _portController.text.trim()));
    if (!stillMatch && mounted) {
      setState(() => _fromDiscovery = false);
    }
  }

  @override
  void dispose() {
    _hostController.removeListener(_onManualEdit);
    _portController.removeListener(_onManualEdit);
    _hostController.dispose();
    _portController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  ({String host, String? port}) _splitHostPort(String url) {
    final trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.isEmpty) return (host: '', port: null);
    final ipv6 = RegExp(r'^(.*\[[^\]]+\])(?::(\d+))?$').firstMatch(trimmed);
    if (ipv6 != null) {
      return (host: ipv6.group(1)!, port: ipv6.group(2));
    }
    final scheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+\-.]*://').firstMatch(trimmed);
    final afterScheme = scheme == null ? 0 : scheme.end;
    final portMatch =
        RegExp(r':(\d+)$').firstMatch(trimmed.substring(afterScheme));
    if (portMatch == null) return (host: trimmed, port: null);
    final hostEnd = afterScheme + portMatch.start;
    return (host: trimmed.substring(0, hostEnd), port: portMatch.group(1));
  }

  String _buildUrl() {
    final host = _hostController.text.trim().replaceAll(RegExp(r'/+$'), '');
    final port = _portController.text.trim();
    if (host.isEmpty) return '';
    if (RegExp(r':\d+$').hasMatch(host) || port.isEmpty) return host;
    return '$host:$port';
  }

  void _applyServer(DiscoveredLmStudioServer s) {
    setState(() {
      _hostController.text = 'http://${s.host}';
      _portController.text = '${s.port}';
      _fromDiscovery = true;
      _status = null;
      _success = false;
    });
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    required Color fg,
    Widget? suffixIcon,
  }) {
    const good = Color(0xFF10B981);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        color: _fromDiscovery ? good : fg.withValues(alpha: 0.6),
      ),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: _fromDiscovery ? good : fg.withValues(alpha: 0.22),
          width: _fromDiscovery ? 1.6 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: _fromDiscovery ? good : Theme.of(context).colorScheme.primary,
          width: 1.8,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Future<void> _connect() async {
    final url = _buildUrl();
    if (url.isEmpty) {
      setState(() {
        _status = 'Enter a server address.';
        _success = false;
      });
      return;
    }
    final key = _keyController.text.trim();
    if (_keyRequired && key.isEmpty) {
      setState(() {
        _status = 'An API key is required for oMLX.';
        _success = false;
      });
      return;
    }

    setState(() {
      _testing = true;
      _status = null;
      _success = false;
    });

    final settings = context.read<SettingsProvider>();
    try {
      switch (widget.kind) {
        case OnboardingProviderKind.lmStudio:
          final result = await LMStudioService().testConnection(
            url,
            apiToken: key.isEmpty ? null : key,
          );
          if (!mounted) return;
          if (result['success'] == true) {
            await settings.saveAndActivateServerProfile(ServerProfile(
              id: const Uuid().v4(),
              name: 'LM Studio',
              kind: ServerProfileKind.lmStudio,
              baseUrl: url,
              apiKey: key.isEmpty ? null : key,
              lastUsedAt: DateTime.now(),
            ));
            setState(() {
              _success = true;
              _status = 'Connected. You can keep going.';
            });
            await Future<void>.delayed(const Duration(milliseconds: 400));
            if (mounted) Navigator.pop(context, true);
          } else if (result['authError'] == true) {
            setState(() {
              _success = false;
              _status =
                  'Server found, but it needs an API key. Paste it above and try again.';
            });
          } else {
            setState(() {
              _success = false;
              _status = (result['error'] as String?) ??
                  'Couldn’t connect. Check the address and that the server is running.';
            });
          }
        case OnboardingProviderKind.ollama:
        case OnboardingProviderKind.omlx:
        case OnboardingProviderKind.jan:
        case OnboardingProviderKind.unsloth:
          final type = switch (widget.kind) {
            OnboardingProviderKind.ollama => CloudApiType.ollama,
            OnboardingProviderKind.omlx => CloudApiType.omlx,
            OnboardingProviderKind.jan => CloudApiType.jan,
            OnboardingProviderKind.unsloth => CloudApiType.unsloth,
            OnboardingProviderKind.lmStudio => CloudApiType.openaiCompatible,
          };
          final cloud = CloudApiService();
          final existing =
              cloud.providers.where((p) => p.type == type).firstOrNull;
          final provider = CloudApiProvider(
            id: existing?.id ??
                '${type.name}_${DateTime.now().millisecondsSinceEpoch}',
            name: type.displayName,
            type: type,
            apiKey: key,
            baseUrl: url,
            selectedModel: existing?.selectedModel,
            isEnabled: true,
          );
          final ok = await cloud.testConnection(provider);
          if (!mounted) return;
          if (ok) {
            await settings.saveAndActivateServerProfile(ServerProfile(
              id: provider.id,
              name: provider.name,
              kind: ServerProfileKind.cloud,
              cloudType: type,
              baseUrl: url,
              apiKey: key.isEmpty ? null : key,
              lastUsedAt: DateTime.now(),
            ));
            final models = await cloud.fetchModels(provider);
            final chatIds = LMStudioModel.chatModelIds(models);
            if (chatIds.isNotEmpty && provider.selectedModel == null) {
              await cloud.saveProvider(
                provider.copyWith(selectedModel: chatIds.first),
              );
            }
            setState(() {
              _success = true;
              _status = 'Connected. You can keep going.';
            });
            await Future<void>.delayed(const Duration(milliseconds: 400));
            if (mounted) Navigator.pop(context, true);
          } else {
            final auth = widget.kind == OnboardingProviderKind.unsloth &&
                UnslothLoad.connectionNeedsApiKey(cloud.lastConnectionError);
            setState(() {
              _success = false;
              _status = auth
                  ? UnslothLoad.authFailureMessage(hadKey: key.isNotEmpty)
                  : 'Couldn’t connect. Check the address and that the server is running.';
            });
          }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _success = false;
        _status = 'Couldn’t connect. $e';
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final canvas = isDark ? const Color(0xFF12151C) : const Color(0xFFF4F6FA);
    final fg = isDark ? Colors.white : Colors.black.withValues(alpha: 0.88);

    return GlassCanvas(
      onLightCanvas: !isDark,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          decoration: BoxDecoration(
            color: canvas.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: fg.withValues(alpha: 0.65),
                    ),
                  ),
                  if (_matches.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Found on Wi‑Fi',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: fg.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._matches.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: fg.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            leading: Icon(Icons.wifi_tethering, color: fg),
                            title:
                                Text(s.listTitle, style: TextStyle(color: fg)),
                            subtitle: Text(
                              s.listSubtitle,
                              style: TextStyle(
                                color: fg.withValues(alpha: 0.55),
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: fg.withValues(alpha: 0.45),
                            ),
                            onTap: () => _applyServer(s),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_fromDiscovery) ...[
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Text(
                          'Found on your Wi‑Fi — looks good',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: _hostController,
                    style: TextStyle(color: fg),
                    decoration: _fieldDecoration(
                      label: 'Address',
                      hint: 'http://192.168.1.10',
                      fg: fg,
                    ),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _portController,
                    style: TextStyle(color: fg),
                    decoration: _fieldDecoration(label: 'Port', fg: fg),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _keyController,
                    obscureText: _obscureKey,
                    style: TextStyle(color: fg),
                    decoration: _fieldDecoration(
                      label: _keyRequired ? 'API key' : 'API key (optional)',
                      fg: fg,
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _obscureKey = !_obscureKey),
                        icon: Icon(
                          _obscureKey
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: fg.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                    autocorrect: false,
                  ),
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
                    onPressed: _testing ? null : _connect,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _testing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Connect'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
