import 'package:flutter/material.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/server_profile.dart';
import '../providers/settings_provider.dart';
import '../services/server_profile_service.dart';
import '../utils/on_device_engine_labels.dart';
import '../widgets/add_server_sheet.dart';
import '../widgets/glass_settings_scaffold.dart';
import '../widgets/on_device_engine_sheet.dart';
import '../widgets/server_connect_sheet.dart';

/// Settings → Servers: list, activate, edit, and add server profiles.
class ProvidersScreen extends StatelessWidget {
  const ProvidersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profiles = ServerProfileService.instance;

    return GlassSettingsScaffold(
      title: 'Servers',
      body: Column(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: profiles,
              builder: (context, _) {
                final items = profiles.profiles;
                final activeId = profiles.activeId;

                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No servers yet. Tap Add Server to connect one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                return Consumer<SettingsProvider>(
                  builder: (context, settings, _) {
                    final remote = settings.settings.isRemoteActive;
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final profile = items[index];
                        return _ServerTile(
                          profile: profile,
                          isActive: profile.isOnDevice
                              ? (settings.settings.activeProviderKind ==
                                      'onDeviceGguf' ||
                                  settings.settings.activeProviderKind ==
                                      'onDeviceMlx')
                              : (!remote && profile.id == activeId),
                          onActivate: () => _activate(context, profile),
                          onRename: () => _rename(context, profile),
                          onEdit: () => _edit(context, profile),
                          onDelete: profile.isDeletable
                              ? () => _delete(context, profile)
                              : null,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _addServer(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Server'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _activate(BuildContext context, ServerProfile profile) async {
    final settings = context.read<SettingsProvider>();
    final ok = await settings.activateServerProfile(profile.id);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t switch to that server.')),
      );
    }
  }

  Future<void> _rename(BuildContext context, ServerProfile profile) async {
    final controller = TextEditingController(text: profile.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename server'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await ServerProfileService.instance.rename(profile.id, name);
    if (profile.kind == ServerProfileKind.cloud) {
      final cloud = CloudApiService();
      final existing =
          cloud.providers.where((p) => p.id == profile.id).firstOrNull;
      if (existing != null) {
        await cloud.saveProvider(existing.copyWith(name: name));
      }
    }
  }

  Future<void> _edit(BuildContext context, ServerProfile profile) async {
    if (profile.isUsb) {
      await context.read<SettingsProvider>().activateServerProfile(profile.id);
      return;
    }
    if (profile.isOnDevice) {
      await context.read<SettingsProvider>().activateServerProfile(profile.id);
      if (!context.mounted) return;
      await showOnDeviceEngineSheet(context);
      return;
    }

    final ServerConnectTarget target =
        profile.kind == ServerProfileKind.lmStudio
            ? const ServerConnectLmStudio()
            : ServerConnectCloud(
                profile.cloudType ?? CloudApiType.openaiCompatible);

    await showServerConnectSheet(
      context,
      target: target,
      existing: profile,
    );
  }

  Future<void> _delete(BuildContext context, ServerProfile profile) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete server?'),
        content: Text(
          CloudApiType.warnBeforeRemoving(profile.cloudType)
              ? l10n.deleteFirstPartyOpenAiServerMessage(profile.displayTitle)
              : 'Remove “${profile.displayTitle}” from this device? '
                  'You can add it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final wasActive = ServerProfileService.instance.activeId == profile.id;
    if (!context.mounted) return;
    final settings = context.read<SettingsProvider>();
    if (profile.isUsb) {
      await settings.removeUsbServerProfile();
    } else {
      await ServerProfileService.instance.delete(profile.id);
      if (profile.kind == ServerProfileKind.cloud) {
        await CloudApiService().removeProvider(profile.id);
      }
    }
    if (wasActive && context.mounted) {
      await settings.activateServerProfile(ServerProfile.onDeviceId);
    }
  }

  Future<void> _addServer(BuildContext context) async {
    final selection = await showAddServerSheet(context);
    if (selection == null || !context.mounted) return;

    switch (selection) {
      case AddServerUsb():
        try {
          await context.read<SettingsProvider>().enableUsbServerProfile();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'LM Studio via USB on — open LM Mini Connect on your Mac'),
            ),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Couldn’t start LM Studio via USB: $e')),
          );
        }
      case AddServerLmStudio():
        await showServerConnectSheet(
          context,
          target: const ServerConnectLmStudio(),
        );
      case AddServerCloud(:final type):
        await showServerConnectSheet(
          context,
          target: ServerConnectCloud(type),
        );
    }
  }
}

class _ServerTile extends StatelessWidget {
  final ServerProfile profile;
  final bool isActive;
  final VoidCallback onActivate;
  final VoidCallback onRename;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _ServerTile({
    required this.profile,
    required this.isActive,
    required this.onActivate,
    required this.onRename,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GlassSettingsCard(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        leading: GlassSettingsIcon(
          _iconFor(profile),
          color: isActive ? cs.primary : null,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                profile.displayTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
            if (profile.isPremium) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber[700],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: profile.isUsb
            ? Consumer<SettingsProvider>(
                builder: (context, settings, _) {
                  return StreamBuilder<bool>(
                    stream: settings.usbConnectionStream,
                    initialData: settings.isUsbPeerConnected,
                    builder: (context, snap) {
                      final connected = snap.data == true;
                      final text = connected
                          ? 'Connected via USB'
                          : (isActive
                              ? 'Waiting for LM Mini Connect on Mac…'
                              : profile.subtitle);
                      return Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: connected ? Colors.green : cs.onSurfaceVariant,
                          fontSize: 12.5,
                        ),
                      );
                    },
                  );
                },
              )
            : Text(
                profile.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
              ),
        onTap: isActive ? null : onActivate,
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant),
          onSelected: (value) {
            switch (value) {
              case 'rename':
                onRename();
              case 'edit':
                onEdit();
              case 'delete':
                onDelete?.call();
            }
          },
          itemBuilder: (_) => [
            if (!profile.isUsb && !profile.isOnDevice)
              const PopupMenuItem(value: 'rename', child: Text('Rename')),
            if (!profile.isUsb)
              PopupMenuItem(
                value: 'edit',
                child: Text(profile.isOnDevice ? 'Engine' : 'Edit'),
              ),
            if (onDelete != null)
              const PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(ServerProfile profile) {
    switch (profile.kind) {
      case ServerProfileKind.onDevice:
        return OnDeviceEngineLabels.serverListIcon;
      case ServerProfileKind.lmStudio:
        return Icons.desktop_windows_rounded;
      case ServerProfileKind.usb:
        return Icons.usb;
      case ServerProfileKind.cloud:
        switch (profile.cloudType) {
          case CloudApiType.ollama:
            return Icons.pets_rounded;
          case CloudApiType.omlx:
            return Icons.memory_rounded;
          case CloudApiType.jan:
            return Icons.bolt_rounded;
          case CloudApiType.unsloth:
            return Icons.science_rounded;
          case CloudApiType.openRouter:
            return Icons.alt_route_rounded;
          case CloudApiType.vercelAiGateway:
            return Icons.hub_rounded;
          case CloudApiType.gemini:
            return Icons.diamond_outlined;
          case CloudApiType.zAi:
            return Icons.psychology_alt_rounded;
          case CloudApiType.mistral:
            return Icons.air_rounded;
          case CloudApiType.deepSeek:
            return Icons.search_rounded;
          case CloudApiType.openaiCompatible:
            return Icons.hub_outlined;
          case CloudApiType.openai:
          case null:
            return Icons.cloud_outlined;
          default:
            return Icons.science_rounded;
        }
    }
  }
}
