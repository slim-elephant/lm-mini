import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../services/reasoning_support_service.dart';
import '../utils/layout_utils.dart';
import '../widgets/desktop_settings_controls.dart';
import '../widgets/glass_settings_scaffold.dart';

part '../pro/tools/tool_settings_pro.dart';

/// Helper class for parsing mcp.json
class _ParsedMcpServer {
  final String name;
  final String? url;
  final String? command;
  final List<String>? args;
  final Map<String, String>? headers;
  final bool isHttpServer;
  bool selected;

  _ParsedMcpServer({
    required this.name,
    this.url,
    this.command,
    this.args,
    this.headers,
    required this.isHttpServer,
    this.selected = false,
  });

  bool get hasAuth => headers != null && headers!.isNotEmpty;
}

/// Result of parsing mcp.json
class _McpJsonParseResult {
  final List<_ParsedMcpServer>? servers;
  final String? error;

  _McpJsonParseResult({this.servers, this.error});
}

class ToolSettingsScreen extends StatelessWidget {
  final bool embedded;
  const ToolSettingsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassSettingsScaffold(
      embedded: embedded,
      title: l10n.toolsCallingTitle,
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final settings = settingsProvider.settings;
          final isAdvanced = settingsProvider.isAdvancedSettings;
          final desktop = prefersWideSettingsLayout(context);
          final webSearchSubtitle = settings.enableWebSearch
              ? (_proWebSearchSubtitle(l10n, settings) ??
                  (settings.searxngUrl?.isNotEmpty == true
                      ? l10n.webSearchUsingSearxng
                      : l10n.webSearchDisabled))
              : l10n.webSearchDisabledAll;

          final builtInTools = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isAdvanced)
                _buildSectionHeaderWithInfo(
                  context,
                  l10n.builtInToolsSection,
                  l10n.builtInToolsInfo,
                )
              else
                _buildSectionHeader(context, l10n.builtInToolsSection),
              GlassSettingsCard(
                child: Column(
                  children: [
                    DesktopSettingsGrid(
                      children: [
                        _toggleRow(
                          context,
                          icon: Icons.search,
                          title: l10n.webSearch,
                          subtitle: webSearchSubtitle,
                          value: settings.enableWebSearch,
                          onChanged: (value) {
                            if (value && !settings.enableToolUse) {
                              settingsProvider.updateEnableToolUse(true);
                            }
                            settingsProvider.updateEnableWebSearch(value);
                          },
                        ),
                        ..._proExtraToggles(
                            context, settings, settingsProvider),
                      ],
                    ),
                    if (isAdvanced) ...[
                      _divider(context),
                      _buildSearxngTile(
                          context, settings, settingsProvider, l10n),
                    ],
                  ],
                ),
              ),
            ],
          );

          final advancedAndHelp = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader(context, l10n.advancedFeaturesSection),
              GlassSettingsCard(
                child: DesktopSettingsGrid(
                  children: [
                    _toggleRow(
                      context,
                      icon: Icons.code,
                      title: l10n.structuredOutput,
                      subtitle: l10n.structuredOutputSubtitle,
                      value: settings.useStructuredOutput,
                      onChanged: settingsProvider.updateUseStructuredOutput,
                    ),
                    DesktopPreferenceRow(
                      icon: Icons.psychology,
                      title: l10n.reasoningMode,
                      subtitle: () {
                        final modelId = settings.selectedModel ?? '';
                        final items = ReasoningSupportService.instance
                            .dropdownOptionsSync(modelId);
                        if (items.isEmpty) {
                          return l10n.reasoningNotExposedChatHint;
                        }
                        return _getReasoningDescription(
                            context, settings.reasoning);
                      }(),
                      trailing: Builder(
                        builder: (context) {
                          final modelId = settings.selectedModel ?? '';
                          final items = ReasoningSupportService.instance
                              .dropdownOptionsSync(modelId);
                          if (items.isEmpty) {
                            return Text(
                              l10n.off,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            );
                          }
                          final value = ReasoningSupportService.dropdownValue(
                            settings.reasoning,
                            items,
                          );
                          return DropdownButton<String>(
                            value: value,
                            underline: const SizedBox(),
                            items: [
                              for (final option in items)
                                DropdownMenuItem(
                                  value: option,
                                  child: Text(
                                    _reasoningOptionLabel(l10n, option),
                                  ),
                                ),
                            ],
                            onChanged: (next) {
                              if (next != null) {
                                settingsProvider.updateReasoning(next);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              _buildSectionHeader(context, l10n.helpSection),
              GlassSettingsCard(
                child: Column(
                  children: [
                    _navRow(
                      context,
                      icon: Icons.help_outline,
                      title: l10n.toolCallingGuide,
                      subtitle: l10n.toolCallingGuideSubtitle,
                      onTap: () => _showToolGuide(context),
                    ),
                    _divider(context),
                    _navRow(
                      context,
                      icon: Icons.search,
                      title: l10n.searxngSetupGuide,
                      subtitle: l10n.searxngSetupGuideSubtitle,
                      onTap: () => _showSearxngGuide(context),
                    ),
                  ],
                ),
              ),
            ],
          );

          return DesktopSettingsForm(
            maxWidth: desktop ? 880 : double.infinity,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                desktop ? 0 : 16,
                desktop ? 12 : 20,
                desktop ? 0 : 16,
                36,
              ),
              children: [
                // Tool Calling Section (Advanced: full MCP master switch)
                if (isAdvanced) ...[
                  _buildSectionHeader(context, l10n.toolCallingSection),
                  GlassSettingsCard(
                    child: _toggleRow(
                      context,
                      icon: Icons.build_outlined,
                      title: l10n.enableToolCallingAndMcps,
                      subtitle: l10n.enableToolCallingSubtitle,
                      value: settings.enableToolUse,
                      onChanged: settingsProvider.updateEnableToolUse,
                    ),
                  ),
                ],

                if (settings.enableToolUse || !isAdvanced) ...[
                  if (isAdvanced && desktop)
                    SettingsTwoColumn(
                      left: builtInTools,
                      right: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSectionHeader(context, 'TOOL CALL LIMIT'),
                          GlassSettingsCard(
                            child: _toggleRow(
                              context,
                              icon: Icons.all_inclusive,
                              title: l10n.unlimitedToolCalls,
                              subtitle: settings.unlimitedToolCalls
                                  ? l10n.unlimitedToolCallsOn
                                  : l10n.unlimitedToolCallsOff,
                              value: settings.unlimitedToolCalls,
                              onChanged:
                                  settingsProvider.updateUnlimitedToolCalls,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    builtInTools,

                  if (isAdvanced) ...[
                    _buildSectionHeaderWithInfo(
                      context,
                      l10n.integratedMcpsSection,
                      l10n.integratedMcpsInfo,
                    ),
                    if (!settings.hasApiToken &&
                        (settings.integratedMcps?.isNotEmpty ?? false))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassSettingsCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.lock_outline,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.integratedMcpsAuthRequired,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    GlassSettingsCard(
                      child: _buildIntegratedMcpSection(
                          context, settings, settingsProvider),
                    ),
                    _buildSectionHeaderWithInfo(
                      context,
                      l10n.ephemeralMcpsSection,
                      l10n.ephemeralMcpsInfo,
                    ),
                    GlassSettingsCard(
                      child: _buildEphemeralMcpSection(
                          context, settings, settingsProvider),
                    ),
                    if (!desktop) ...[
                      _buildSectionHeader(context, 'TOOL CALL LIMIT'),
                      GlassSettingsCard(
                        child: _toggleRow(
                          context,
                          icon: Icons.all_inclusive,
                          title: l10n.unlimitedToolCalls,
                          subtitle: settings.unlimitedToolCalls
                              ? l10n.unlimitedToolCallsOn
                              : l10n.unlimitedToolCallsOff,
                          value: settings.unlimitedToolCalls,
                          onChanged:
                              settingsProvider.updateUnlimitedToolCalls,
                        ),
                      ),
                    ],
                  ],
                ],

                if (isAdvanced) advancedAndHelp,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _toggleRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return DesktopPreferenceRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _navRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return DesktopPreferenceRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _divider(BuildContext context) {
    if (useDesktopSettingsControls(context)) {
      return const SizedBox(height: 2);
    }
    return Divider(
      height: 1,
      indent: 66,
      color: Theme.of(context)
          .colorScheme
          .outlineVariant
          .withValues(alpha: 0.45),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSectionHeaderWithInfo(BuildContext context, String title, String infoText) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(title),
                  content: Text(infoText),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context).ok),
                    ),
                  ],
                ),
              );
            },
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegratedMcpSection(BuildContext context, AppSettings settings, SettingsProvider settingsProvider) {
    final integratedMcps = settings.integratedMcps ?? [];
    final hasToken = settings.hasApiToken;
    final l10n = AppLocalizations.of(context);
    
    return Column(
      children: [
        // List of integrated MCPs
        if (integratedMcps.isNotEmpty) ...[
          ...integratedMcps.map((mcp) => DesktopPreferenceRow(
            icon: Icons.integration_instructions,
            title: mcp.name,
            subtitle: !hasToken
                ? l10n.requiresApiToken
                : (mcp.enabled ? l10n.enabled : l10n.disabled),
            onTap: () => _showAddIntegratedMcpDialog(
              context,
              settingsProvider,
              existingName: mcp.name,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!hasToken)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Tooltip(
                      message: l10n.setApiTokenTooltip,
                      child: Icon(Icons.help_outline, size: 18, color: Theme.of(context).colorScheme.error.withOpacity(0.7)),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: l10n.editMcpTooltip,
                  onPressed: () => _showAddIntegratedMcpDialog(
                    context,
                    settingsProvider,
                    existingName: mcp.name,
                  ),
                ),
                Switch(
                  value: hasToken && mcp.enabled,
                  onChanged: hasToken ? (_) => settingsProvider.toggleIntegratedMcp(mcp.name) : null,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: Theme.of(context).colorScheme.error),
                  onPressed: () => settingsProvider.removeIntegratedMcp(mcp.name),
                ),
              ],
            ),
          )),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.noIntegratedMcps,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        
        // Add buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddIntegratedMcpDialog(context, settingsProvider),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addManually),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showImportMcpJsonDialog(context, settingsProvider),
                  icon: const Icon(Icons.file_upload_outlined, size: 18),
                  label: Text(l10n.importMcpJson),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEphemeralMcpSection(BuildContext context, AppSettings settings, SettingsProvider settingsProvider) {
    final mcpServers = settings.mcpServers ?? [];
    final l10n = AppLocalizations.of(context);
    
    return Column(
      children: [
        // Show warning if ephemeral MCPs configured but setting may not be enabled
        if (mcpServers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.requiresPerRequestMcps,
                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // List of ephemeral MCPs
        if (mcpServers.isNotEmpty) ...[
          ...mcpServers.asMap().entries.map((entry) {
            final index = entry.key;
            final server = entry.value;
            return DesktopPreferenceRow(
              icon: Icons.cloud_outlined,
              title: server.label,
              subtitle: server.hasAuthentication
                  ? '${server.url} · auth'
                  : server.url,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _showAddMcpServerDialog(context, settingsProvider, existingServer: server, index: index),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: Theme.of(context).colorScheme.error),
                    onPressed: () => _removeMcpServer(settingsProvider, index),
                  ),
                ],
              ),
            );
          }),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.noEphemeralMcps,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        
        // Add button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: OutlinedButton.icon(
            onPressed: () => _showAddMcpServerDialog(context, settingsProvider),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.addHttpMcpServer),
          ),
        ),
        
        // Example MCPs link
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextButton(
            onPressed: () => _showMcpExamplesDialog(context, settingsProvider),
            child: Text(l10n.browseExampleMcps),
          ),
        ),
      ],
    );
  }

  /// Normalize a pasted mcp.json name: strip quotes / mcp/ prefix, trim.
  String _normalizeIntegratedMcpName(String raw) {
    var name = raw.trim();
    if ((name.startsWith('"') && name.endsWith('"')) ||
        (name.startsWith("'") && name.endsWith("'"))) {
      name = name.substring(1, name.length - 1).trim();
    }
    if (name.toLowerCase().startsWith('mcp/')) {
      name = name.substring(4).trim();
    }
    return name;
  }

  void _showAddIntegratedMcpDialog(
    BuildContext context,
    SettingsProvider settingsProvider, {
    String? existingName,
  }) {
    final isEditing = existingName != null;
    final nameController = TextEditingController(text: existingName ?? '');
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = screenWidth < 600 ? screenWidth * 0.92 : 420.0;

        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: (screenWidth - dialogWidth) / 2,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              minWidth: screenWidth < 600 ? dialogWidth : 320,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isEditing
                        ? l10n.editIntegratedMcpTitle
                        : l10n.addIntegratedMcpTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.addIntegratedMcpInfo,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 15),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: l10n.mcpNameLabel,
                      hintText: l10n.mcpNameHint,
                      border: const OutlineInputBorder(),
                      helperText: l10n.mcpNameHelper,
                      helperMaxLines: 2,
                    ),
                    onSubmitted: (_) => _saveIntegratedMcpName(
                      context,
                      settingsProvider,
                      nameController.text,
                      existingName: existingName,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _saveIntegratedMcpName(
                          context,
                          settingsProvider,
                          nameController.text,
                          existingName: existingName,
                        ),
                        child: Text(isEditing ? l10n.save : l10n.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _saveIntegratedMcpName(
    BuildContext context,
    SettingsProvider settingsProvider,
    String rawName, {
    String? existingName,
  }) {
    final l10n = AppLocalizations.of(context);
    final name = _normalizeIntegratedMcpName(rawName);
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.nameIsRequired)),
      );
      return;
    }
    // LM Studio artifact ids reject underscores (use hyphens).
    if (name.contains('_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mcpNameInvalidChars)),
      );
      return;
    }

    final existing = settingsProvider.settings.integratedMcps ?? [];
    final isEditing = existingName != null;
    final duplicate = existing.any(
      (m) => m.name == name && m.name != existingName,
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mcpNameAlreadyExists)),
      );
      return;
    }

    if (isEditing) {
      if (name != existingName) {
        settingsProvider.renameIntegratedMcp(existingName, name);
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.updatedMcp(name))),
      );
    } else {
      settingsProvider.addIntegratedMcp(name);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addedMcp(name))),
      );
    }
  }

  String _reasoningOptionLabel(AppLocalizations l10n, String value) {
    return switch (value) {
      'off' => l10n.reasoningOff,
      'low' => l10n.reasoningLow,
      'medium' => l10n.reasoningMedium,
      'high' => l10n.reasoningHigh,
      'on' => l10n.reasoningOn,
      _ => value,
    };
  }

  String _getReasoningDescription(BuildContext context, String mode) {
    final l10n = AppLocalizations.of(context);
    switch (mode) {
      case 'off':
        return l10n.reasoningDescOff;
      case 'low':
        return l10n.reasoningDescLow;
      case 'medium':
        return l10n.reasoningDescMedium;
      case 'high':
        return l10n.reasoningDescHigh;
      case 'on':
        return l10n.reasoningDescOn;
      default:
        return 'Unknown';
    }
  }

  Widget _buildSearxngTile(
    BuildContext context,
    AppSettings settings,
    SettingsProvider settingsProvider,
    AppLocalizations l10n,
  ) {
    final hasUrl = settings.searxngUrl?.trim().isNotEmpty == true;
    final isOn = hasUrl && settings.preferSearxng && settings.enableWebSearch;
    final cs = Theme.of(context).colorScheme;

    return DesktopPreferenceRow(
      icon: Icons.travel_explore,
      title: 'SearXNG',
      subtitle: hasUrl
          ? (isOn ? l10n.webSearchUsingSearxng : l10n.searxngConfiguredOff)
          : l10n.searxngNotConfigured,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.editSearxng,
            icon: Icon(Icons.edit_outlined, size: 20, color: cs.onSurfaceVariant),
            onPressed: () =>
                _showSearchConfigDialog(context, settingsProvider),
          ),
          Switch(
            value: isOn,
            onChanged: (value) {
              if (value && !hasUrl) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.searxngConfigureFirst)),
                );
                _showSearchConfigDialog(context, settingsProvider);
                return;
              }
              if (value) {
                settingsProvider.updateEnableWebSearch(true);
                settingsProvider.updatePreferSearxng(true);
              } else {
                settingsProvider.updatePreferSearxng(false);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSearchConfigDialog(BuildContext context, SettingsProvider settingsProvider) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: settingsProvider.settings.searxngUrl ?? '',
    );
    int searchResultsCount = settingsProvider.settings.searchResultsCount;

    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = screenWidth < 600 ? screenWidth * 0.92 : 520.0;
        
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: (screenWidth - dialogWidth) / 2,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dialogWidth,
                minWidth: screenWidth < 600 ? dialogWidth : 400,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.webSearchConfig, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // How it works
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.howWebSearchWorks,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.howWebSearchWorksSteps,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Search Results Count
                            Row(
                              children: [
                                const Icon(Icons.format_list_numbered, size: 20),
                                const SizedBox(width: 8),
                                Text(l10n.searchResultsLabel, style: const TextStyle(fontSize: 13)),
                                Text('$searchResultsCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Expanded(
                                  child: Slider(
                                    value: searchResultsCount.toDouble(),
                                    min: 2,
                                    max: 10,
                                    divisions: 8,
                                    onChanged: (value) {
                                      setState(() {
                                        searchResultsCount = value.toInt();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            const SizedBox(height: 8),
                            
                            // SearXNG URL
                            Text(
                              l10n.searxngUrlOptional,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: controller,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: l10n.searxngUrlLabel,
                                hintText: l10n.searxngUrlHint,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.url,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline, size: 14,
                                    color: Theme.of(context).colorScheme.tertiary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'SearXNG uses the V0 (stateless) API. For best results with small models, consider installing an MCP web search plugin in LM Studio instead (uses V1 stateful API).',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.quickSetupDocker,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  const SelectableText(
                                    'docker run -d -p 8888:8080 searxng/searxng',
                                    style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            settingsProvider.updateSearXngUrl('');
                            Navigator.pop(context);
                          },
                          child: Text(l10n.reset),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.cancel),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            settingsProvider.updateSearXngUrl(controller.text.trim());
                            settingsProvider.updateSearchResultsCount(searchResultsCount);
                            Navigator.pop(context);
                          },
                          child: Text(l10n.save),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showToolGuide(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.howToolCallingWorks),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStep(context, '1', l10n.stepAskQuestion, l10n.stepAskExample),
              _buildStep(context, '2', l10n.stepAiRequestsTool, l10n.stepAiRequestsExample),
              _buildStep(context, '3', l10n.stepAppExecutes, l10n.stepAppExecutesExample),
              _buildStep(context, '4', l10n.stepResultsSent, l10n.stepResultsExample),
              _buildStep(context, '5', l10n.stepAiAnswers, l10n.stepAiAnswersExample),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '💡 Tip: ${l10n.toolCallingModelNote}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSearxngGuide(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.searxngSetup),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.searxngDescription,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.dockerRecommended,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SelectableText(
                  'docker run -d \\\n'
                  '  --name searxng \\\n'
                  '  -p 8888:8080 \\\n'
                  '  searxng/searxng',
                  style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.publicInstance,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.findPublicInstances,
                style: const TextStyle(fontSize: 13),
              ),
              TextButton(
                onPressed: () => launchUrl(Uri.parse('https://searx.space/')),
                child: const Text('searx.space'),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '⚠️ ${l10n.selfHostRecommended}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showAddMcpServerDialog(
    BuildContext context,
    SettingsProvider settingsProvider, {
    McpServerConfig? existingServer,
    int? index,
  }) {
    final labelController = TextEditingController(text: existingServer?.label ?? '');
    final urlController = TextEditingController(text: existingServer?.url ?? '');
    final authorizationController = TextEditingController(
      text: existingServer?.authorization ?? '',
    );
    final headersController = TextEditingController(
      text: existingServer?.headers?.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n') ?? '',
    );
    final isEditing = existingServer != null;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = screenWidth < 600 ? screenWidth * 0.92 : 500.0;
        
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: (screenWidth - dialogWidth) / 2,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              minWidth: screenWidth < 600 ? dialogWidth : 400,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dns_outlined),
                      const SizedBox(width: 12),
                      Text(
                        isEditing ? l10n.editMcpServer : l10n.addMcpServer,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: labelController,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: l10n.serverLabelRequired,
                              hintText: l10n.serverLabelHint,
                              border: const OutlineInputBorder(),
                              helperText: l10n.serverLabelHelper,
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: urlController,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: l10n.serverUrlRequired,
                              hintText: l10n.serverUrlMcpHint,
                              border: const OutlineInputBorder(),
                              helperText: l10n.serverUrlHelper,
                              isDense: true,
                            ),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: authorizationController,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: l10n.authorizationOptional,
                              hintText: l10n.authorizationHint,
                              border: const OutlineInputBorder(),
                              helperText: l10n.authorizationHelper,
                              prefixIcon: const Icon(Icons.key, size: 20),
                              isDense: true,
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 12),
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(l10n.additionalHeaders, style: const TextStyle(fontSize: 13)),
                            children: [
                              TextField(
                                controller: headersController,
                                maxLines: 3,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: l10n.additionalHeadersHint,
                                  border: const OutlineInputBorder(),
                                  helperText: l10n.additionalHeadersHelper,
                                  helperMaxLines: 2,
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '💡 Example: HuggingFace MCP',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'URL: https://huggingface.co/mcp\n'
                                  'API Key: hf_YOUR_TOKEN',
                                  style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          final label = labelController.text.trim();
                          final url = urlController.text.trim();
                          
                          if (label.isEmpty || url.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.labelAndUrlRequired)),
                            );
                            return;
                          }
                          
                          if (!url.startsWith('http://') && !url.startsWith('https://')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.urlMustStartWithHttp)),
                            );
                            return;
                          }
                          
                          final authorizationRaw =
                              authorizationController.text.trim();
                          // Accept a bare API token or a full Authorization value.
                          final authorization = authorizationRaw.isEmpty
                              ? ''
                              : (authorizationRaw.contains(' ')
                                  ? authorizationRaw
                                  : 'Bearer $authorizationRaw');
                          
                          // Parse additional headers from text
                          final headersText = headersController.text.trim();
                          Map<String, String>? headers;
                          if (headersText.isNotEmpty) {
                            headers = {};
                            for (final line in headersText.split('\n')) {
                              final colonIndex = line.indexOf(':');
                              if (colonIndex > 0) {
                                final key = line.substring(0, colonIndex).trim();
                                final value = line.substring(colonIndex + 1).trim();
                                if (key.isNotEmpty && value.isNotEmpty) {
                                  headers[key] = value;
                                }
                              }
                            }
                            if (headers.isEmpty) headers = null;
                          }
                          
                          final newServer = McpServerConfig(
                            label: label,
                            url: url,
                            authorization:
                                authorization.isEmpty ? null : authorization,
                            headers: headers,
                          );
                          
                          final currentServers = List<McpServerConfig>.from(settingsProvider.settings.mcpServers ?? []);
                          
                          if (isEditing && index != null) {
                            currentServers[index] = newServer;
                          } else {
                            currentServers.add(newServer);
                          }
                          
                          settingsProvider.updateMcpServers(currentServers);
                          Navigator.pop(context);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isEditing ? l10n.mcpServerUpdated : l10n.mcpServerAdded)),
                          );
                        },
                        child: Text(isEditing ? l10n.save : l10n.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showImportMcpJsonDialog(BuildContext context, SettingsProvider settingsProvider) {
    final l10n = AppLocalizations.of(context);
    final jsonController = TextEditingController();
    List<_ParsedMcpServer>? parsedServers;
    String? parseError;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.file_upload_outlined),
              const SizedBox(width: 12),
              Text(l10n.importMcpJsonTitle),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              l10n.pasteMcpJsonContent,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.mcpJsonLocation,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Paste from clipboard button - outside TextField for reliable touch handling
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data?.text != null && data!.text!.isNotEmpty) {
                            jsonController.text = data.text!;
                            jsonController.selection = TextSelection.fromPosition(
                              TextPosition(offset: jsonController.text.length),
                            );
                            // Auto-parse after paste
                            final result = _parseMcpJson(jsonController.text);
                            setState(() {
                              parsedServers = result.servers;
                              parseError = result.error;
                            });
                          } else {
                            setState(() {
                              parseError = l10n.clipboardEmpty;
                            });
                          }
                        } catch (e) {
                          setState(() {
                            parseError = l10n.clipboardAccessFailed;
                          });
                        }
                      },
                      icon: const Icon(Icons.content_paste, size: 18),
                      label: Text(l10n.pasteFromClipboard),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: jsonController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: l10n.mcpJsonContentLabel,
                      hintText: '{\n  "mcpServers": {\n    "server-name": {\n      ...\n    }\n  }\n}',
                      border: const OutlineInputBorder(),
                      helperText: l10n.mcpJsonContentHelper,
                      errorText: parseError,
                    ),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    onChanged: (_) => setState(() {
                      parsedServers = null;
                      parseError = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final result = _parseMcpJson(jsonController.text);
                        setState(() {
                          parsedServers = result.servers;
                          parseError = result.error;
                        });
                      },
                      icon: const Icon(Icons.search, size: 18),
                      label: Text(l10n.parseJson),
                    ),
                  ),
                  
                  if (parsedServers != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      l10n.foundMcpServers(parsedServers!.length),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ...parsedServers!.map((server) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  server.isHttpServer ? Icons.cloud : Icons.terminal,
                                  size: 20,
                                  color: server.isHttpServer 
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    server.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (server.isHttpServer)
                                  Checkbox(
                                    value: server.selected,
                                    onChanged: (value) {
                                      setState(() {
                                        server.selected = value ?? false;
                                      });
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (server.isHttpServer) ...[
                              Text(
                                server.url ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (server.hasAuth)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.key, size: 12, color: Theme.of(context).colorScheme.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.hasAuthHeaders,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Local MCP → mcp/${server.name}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Checkbox(
                                    value: server.selected,
                                    onChanged: (value) {
                                      setState(() {
                                        server.selected = value ?? false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                '${server.command ?? "npx"} ${server.args?.join(" ") ?? ""}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    )),
                    
                    if (parsedServers!.any((s) => s.isHttpServer)) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cloud_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.httpServersImportNote,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    if (parsedServers!.any((s) => !s.isHttpServer)) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.integration_instructions, size: 16, color: Theme.of(context).colorScheme.secondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.localMcpsImportNote,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            if (parsedServers != null && parsedServers!.any((s) => s.selected))
              FilledButton(
                onPressed: () {
                  final selectedHttpServers = parsedServers!
                      .where((s) => s.isHttpServer && s.selected)
                      .toList();
                  final selectedLocalServers = parsedServers!
                      .where((s) => !s.isHttpServer && s.selected)
                      .toList();
                  
                  int addedHttpCount = 0;
                  int addedLocalCount = 0;
                  int skippedCount = 0;
                  
                  // Import HTTP servers as ephemeral MCPs
                  if (selectedHttpServers.isNotEmpty) {
                    final currentServers = List<McpServerConfig>.from(
                      settingsProvider.settings.mcpServers ?? [],
                    );
                    
                    for (final server in selectedHttpServers) {
                      if (currentServers.any((s) => s.url == server.url)) {
                        skippedCount++;
                        continue;
                      }
                      
                      currentServers.add(McpServerConfig(
                        label: server.name,
                        url: server.url!,
                        headers: server.headers,
                      ));
                      addedHttpCount++;
                    }
                    
                    if (addedHttpCount > 0) {
                      settingsProvider.updateMcpServers(currentServers);
                    }
                  }
                  
                  // Import local servers as integrated MCPs
                  if (selectedLocalServers.isNotEmpty) {
                    final currentMcps = List<IntegratedMcpConfig>.from(
                      settingsProvider.settings.integratedMcps ?? [],
                    );
                    
                    for (final server in selectedLocalServers) {
                      if (currentMcps.any((m) => m.name == server.name)) {
                        skippedCount++;
                        continue;
                      }
                      
                      currentMcps.add(IntegratedMcpConfig(
                        name: server.name,
                        enabled: true,
                      ));
                      addedLocalCount++;
                    }
                    
                    if (addedLocalCount > 0) {
                      settingsProvider.updateIntegratedMcps(currentMcps);
                    }
                  }
                  
                  Navigator.pop(context);
                  
                  final parts = <String>[];
                  if (addedLocalCount > 0) parts.add('$addedLocalCount integrated');
                  if (addedHttpCount > 0) parts.add('$addedHttpCount ephemeral');
                  String message = 'Imported ${parts.join(" + ")} MCP(s)';
                  if (skippedCount > 0) {
                    message += ' ($skippedCount already existed)';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                },
                child: Text(l10n.importSelected(parsedServers!.where((s) => s.selected).length)),
              ),
          ],
        ),
      ),
    );
  }

  /// Parse mcp.json content and extract server configurations
  _McpJsonParseResult _parseMcpJson(String jsonText) {
    if (jsonText.trim().isEmpty) {
      return _McpJsonParseResult(error: 'Please paste your mcp.json content');
    }
    
    try {
      final Map<String, dynamic> json = jsonDecode(jsonText);
      
      // mcp.json format: { "mcpServers": { "name": { ... }, ... } }
      final mcpServers = json['mcpServers'] as Map<String, dynamic>?;
      
      if (mcpServers == null || mcpServers.isEmpty) {
        return _McpJsonParseResult(error: 'No mcpServers found in JSON');
      }
      
      final List<_ParsedMcpServer> servers = [];
      
      for (final entry in mcpServers.entries) {
        final name = entry.key;
        final config = entry.value as Map<String, dynamic>;
        
        // Check if it's an HTTP server (has url field) or stdio server (has command field)
        final url = config['url'] as String?;
        final command = config['command'] as String?;
        final args = (config['args'] as List?)?.cast<String>();
        
        // Extract headers if present
        Map<String, String>? headers;
        if (config['headers'] != null) {
          headers = (config['headers'] as Map<String, dynamic>).cast<String, String>();
        }
        
        // Some HTTP MCP servers might have auth in env
        if (config['env'] != null && url != null) {
          final env = config['env'] as Map<String, dynamic>;
          // Check for common auth env vars
          for (final key in ['API_KEY', 'AUTH_TOKEN', 'AUTHORIZATION', 'BEARER_TOKEN']) {
            if (env.containsKey(key)) {
              headers ??= {};
              headers['Authorization'] = 'Bearer \${$key}'; // Placeholder
              break;
            }
          }
        }
        
        servers.add(_ParsedMcpServer(
          name: name,
          url: url,
          command: command,
          args: args,
          headers: headers,
          isHttpServer: url != null && (url.startsWith('http://') || url.startsWith('https://')),
          selected: true, // Select all servers by default
        ));
      }
      
      if (servers.isEmpty) {
        return _McpJsonParseResult(error: 'No valid MCP servers found');
      }
      
      return _McpJsonParseResult(servers: servers);
    } catch (e) {
      return _McpJsonParseResult(error: 'Invalid JSON: ${e.toString()}');
    }
  }

  void _removeMcpServer(SettingsProvider settingsProvider, int index) {
    final currentServers = List<McpServerConfig>.from(settingsProvider.settings.mcpServers ?? []);
    currentServers.removeAt(index);
    settingsProvider.updateMcpServers(currentServers);
  }

  void _showMcpExamplesDialog(BuildContext context, SettingsProvider settingsProvider) {
    final l10n = AppLocalizations.of(context);
    final examples = [
      {
        'label': 'tiktoken',
        'url': 'https://gitmcp.io/openai/tiktoken',
        'description': 'tiktoken tokenizer documentation',
        'tools': ['fetch_tiktoken_documentation'],
      },
      {
        'label': 'langchain',
        'url': 'https://gitmcp.io/langchain-ai/langchain',
        'description': 'LangChain framework documentation',
        'tools': null,
      },
      {
        'label': 'transformers',
        'url': 'https://gitmcp.io/huggingface/transformers',
        'description': 'Hugging Face Transformers docs',
        'tools': null,
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.list_alt),
            const SizedBox(width: 12),
            Text(l10n.exampleMcpServers),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.gitMcpInfo,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...examples.map((example) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(example['label'] as String),
                  subtitle: Text(
                    example['description'] as String,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      final currentServers = List<McpServerConfig>.from(
                        settingsProvider.settings.mcpServers ?? [],
                      );
                      
                      // Check if already added
                      if (currentServers.any((s) => s.url == example['url'])) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.serverAlreadyAdded)),
                        );
                        return;
                      }
                      
                      currentServers.add(McpServerConfig(
                        label: example['label'] as String,
                        url: example['url'] as String,
                        authorization: example['authorization'] as String?,
                      ));
                      
                      settingsProvider.updateMcpServers(currentServers);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added ${example['label']}')),
                      );
                    },
                  ),
                ),
              )),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => launchUrl(Uri.parse('https://gitmcp.io')),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(l10n.browseMoreGitMcp),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}
