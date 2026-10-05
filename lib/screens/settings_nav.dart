import 'dart:io';

import 'package:flutter/material.dart';

import '../desktop/desktop_platform.dart';
import '../l10n/app_localizations.dart';
import '../pro/pro_features.dart';

/// Stable ids for Mac/iPad settings tree navigation.
abstract final class SettingsNavId {
  static const server = 'server';
  static const serverAdd = 'server.add';
  static const desktopHost = 'desktopHost';
  static const remoteAccess = 'remoteAccess';
  static const models = 'models';
  static const modelsSelection = 'models.selection';
  static const modelsParameters = 'models.parameters';
  static const modelsPersonas = 'models.personas';
  static const appearance = 'appearance';
  static const voice = 'voice';
  static const transcription = 'transcription';
  static const widgets = 'widgets';
  static const siri = 'siri';
  static const appleWatch = 'appleWatch';
  static const imageGeneration = 'imageGeneration';
  static const language = 'language';
  static const support = 'support';
  static const supportFeatureRequests = 'support.featureRequests';
  static const data = 'data';
  static const dataCloudBackup = 'data.cloudBackup';
  static const dataAnalytics = 'data.analytics';
  static const dataMemory = 'data.memory';
  static const dataAppLock = 'data.appLock';
  static const advanced = 'advanced';
  static const advancedTools = 'advanced.tools';
  static const legal = 'legal';
  static const legalPrivacy = 'legal.privacy';
  static const legalTerms = 'legal.terms';
  static const legalChangelog = 'legal.changelog';
  static const account = 'account';
  static const pro = 'pro';
}

enum SettingsNavKind {
  /// Show the scrolling settings hub and ensureVisible to [hubSectionId].
  hub,

  /// Embed a full settings screen in the right pane.
  screen,

  /// Fire an action (e.g. open Add Server sheet); do not change the pane.
  action,
}

class SettingsNavLeaf {
  final String id;
  final String label;
  final SettingsNavKind kind;

  /// When [kind] is [SettingsNavKind.hub], section id used for ensureVisible.
  final String? hubSectionId;

  const SettingsNavLeaf({
    required this.id,
    required this.label,
    required this.kind,
    this.hubSectionId,
  });
}

class SettingsNavGroup {
  final String id;
  final String label;
  final List<SettingsNavLeaf> leaves;

  /// Hub section id when tapping the group header (defaults to [id]).
  final String? hubSectionId;

  const SettingsNavGroup({
    required this.id,
    required this.label,
    required this.leaves,
    this.hubSectionId,
  });

  String get effectiveHubId => hubSectionId ?? id;
}

/// Builds the Mac/iPad settings tree from current platform / premium / advanced.
List<SettingsNavGroup> buildSettingsNavTree(
  BuildContext context, {
  required bool isAdvanced,
}) {
  final l10n = AppLocalizations.of(context);
  final isPremium = ProFeatures.isPro;

  return [
    SettingsNavGroup(
      id: SettingsNavId.server,
      label: _stripSectionCase(l10n.serverSection),
      leaves: [
        const SettingsNavLeaf(
          id: SettingsNavId.serverAdd,
          label: 'Add Server',
          kind: SettingsNavKind.action,
        ),
      ],
    ),
    if (DesktopPlatform.supportsHostMode)
      const SettingsNavGroup(
        id: SettingsNavId.desktopHost,
        label: 'Desktop Host',
        leaves: [
          SettingsNavLeaf(
            id: SettingsNavId.desktopHost,
            label: 'Connect with phone',
            kind: SettingsNavKind.screen,
          ),
        ],
      ),
    if (isPremium && !DesktopPlatform.supportsHostMode)
      SettingsNavGroup(
        id: SettingsNavId.remoteAccess,
        label: l10n.remoteAccess,
        leaves: [
          SettingsNavLeaf(
            id: SettingsNavId.remoteAccess,
            label: l10n.remoteAccess,
            kind: SettingsNavKind.screen,
          ),
        ],
      ),
    SettingsNavGroup(
      id: SettingsNavId.models,
      label: _stripSectionCase(l10n.modelsSection),
      leaves: [
        SettingsNavLeaf(
          id: SettingsNavId.modelsSelection,
          label: l10n.modelSelection,
          kind: SettingsNavKind.screen,
        ),
        if (isAdvanced)
          SettingsNavLeaf(
            id: SettingsNavId.modelsParameters,
            label: l10n.modelParameters,
            kind: SettingsNavKind.screen,
          ),
        SettingsNavLeaf(
          id: SettingsNavId.modelsPersonas,
          label: l10n.systemPrompts,
          kind: SettingsNavKind.screen,
        ),
      ],
    ),
    SettingsNavGroup(
      id: SettingsNavId.appearance,
      label: _stripSectionCase(l10n.appearanceSection),
      leaves: [
        SettingsNavLeaf(
          id: SettingsNavId.appearance,
          label: l10n.appearance,
          kind: SettingsNavKind.screen,
        ),
      ],
    ),
    SettingsNavGroup(
      id: SettingsNavId.imageGeneration,
      label: l10n.imageGeneration,
      leaves: [
        SettingsNavLeaf(
          id: SettingsNavId.imageGeneration,
          label: l10n.imageGeneration,
          kind: SettingsNavKind.screen,
        ),
      ],
    ),
    SettingsNavGroup(
      id: SettingsNavId.voice,
      label: _stripSectionCase(l10n.voiceSection),
      leaves: [
        SettingsNavLeaf(
          id: SettingsNavId.voice,
          label: l10n.voiceSettings,
          kind: SettingsNavKind.screen,
        ),
      ],
    ),
    SettingsNavGroup(
      id: SettingsNavId.transcription,
      label: l10n.transcription,
      leaves: [
        SettingsNavLeaf(
          id: SettingsNavId.transcription,
          label: l10n.transcription,
          kind: SettingsNavKind.screen,
        ),
      ],
    ),
    if (Platform.isIOS || Platform.isAndroid)
      SettingsNavGroup(
        id: SettingsNavId.widgets,
        label: l10n.widgetSettings,
        leaves: [
          SettingsNavLeaf(
            id: SettingsNavId.widgets,
            label: l10n.widgetSettings,
            kind: SettingsNavKind.screen,
          ),
        ],
      ),
    if (Platform.isIOS)
      const SettingsNavGroup(
        id: SettingsNavId.siri,
        label: 'Siri & Shortcuts',
        leaves: [
          SettingsNavLeaf(
            id: SettingsNavId.siri,
            label: 'Siri & Shortcuts',
            kind: SettingsNavKind.screen,
          ),
        ],
      ),
    if (Platform.isIOS)
      const SettingsNavGroup(
        id: SettingsNavId.appleWatch,
        label: 'Apple Watch',
        leaves: [
          SettingsNavLeaf(
            id: SettingsNavId.appleWatch,
            label: 'Apple Watch',
            kind: SettingsNavKind.screen,
          ),
        ],
      ),
    SettingsNavGroup(
      id: SettingsNavId.language,
      label: _stripSectionCase(l10n.languageSection),
      leaves: [
        SettingsNavLeaf(
          id: SettingsNavId.language,
          label: l10n.language,
          kind: SettingsNavKind.hub,
          hubSectionId: SettingsNavId.language,
        ),
      ],
    ),
    SettingsNavGroup(
      id: SettingsNavId.account,
      label: _stripSectionCase(l10n.accountSection),
      leaves: [
        SettingsNavLeaf(
          id: SettingsNavId.account,
          label: _stripSectionCase(l10n.accountSection),
          kind: SettingsNavKind.screen,
        ),
      ],
    ),
    SettingsNavGroup(
      id: SettingsNavId.support,
      label: _stripSectionCase(l10n.supportSection),
      leaves: [
        SettingsNavLeaf(
          id: SettingsNavId.supportFeatureRequests,
          label: l10n.featureRequests,
          kind: SettingsNavKind.screen,
        ),
      ],
    ),
    SettingsNavGroup(
      id: SettingsNavId.data,
      label: _stripSectionCase(l10n.dataSection),
      leaves: [
        if (isPremium)
          SettingsNavLeaf(
            id: SettingsNavId.dataCloudBackup,
            label: l10n.cloudBackup,
            kind: SettingsNavKind.screen,
          ),
        if (isAdvanced && isPremium)
          SettingsNavLeaf(
            id: SettingsNavId.dataAnalytics,
            label: l10n.analytics,
            kind: SettingsNavKind.screen,
          ),
        if (isPremium)
          SettingsNavLeaf(
            id: SettingsNavId.dataMemory,
            label: l10n.memory,
            kind: SettingsNavKind.screen,
          ),
        if (ProFeatures.included)
          SettingsNavLeaf(
            id: SettingsNavId.dataAppLock,
            label: l10n.appLock,
            kind: SettingsNavKind.screen,
          ),
      ],
    ),
    SettingsNavGroup(
      id: SettingsNavId.advanced,
      label: _stripSectionCase(l10n.advancedSection),
      leaves: [
        SettingsNavLeaf(
          id: SettingsNavId.advancedTools,
          label: l10n.toolCalling,
          kind: SettingsNavKind.screen,
        ),
      ],
    ),
    if (ProFeatures.showUpsell)
      SettingsNavGroup(
        id: SettingsNavId.pro,
        label: _stripSectionCase(l10n.lmMiniProSection),
        leaves: [
          SettingsNavLeaf(
            id: SettingsNavId.pro,
            label: _stripSectionCase(l10n.lmMiniProSection),
            kind: SettingsNavKind.screen,
          ),
        ],
      ),
    SettingsNavGroup(
      id: SettingsNavId.legal,
      label: _stripSectionCase(l10n.legalSection),
      leaves: [
        SettingsNavLeaf(
          id: SettingsNavId.legalPrivacy,
          label: l10n.privacyPolicy,
          kind: SettingsNavKind.screen,
        ),
        SettingsNavLeaf(
          id: SettingsNavId.legalTerms,
          label: l10n.termsOfService,
          kind: SettingsNavKind.screen,
        ),
        SettingsNavLeaf(
          id: SettingsNavId.legalChangelog,
          label: l10n.changelogTitle,
          kind: SettingsNavKind.screen,
        ),
        // Open-source build: info page about the official app's Pro features.
        if (!ProFeatures.included)
          SettingsNavLeaf(
            id: SettingsNavId.pro,
            label: _stripSectionCase(l10n.lmMiniProSection),
            kind: SettingsNavKind.screen,
          ),
      ],
    ),
  ];
}

/// Maps a tree group/leaf id to the hub section registration id used by
/// `_buildSection` (stable ids or uppercased titles).
String? hubSectionIdForNav(String navId, AppLocalizations l10n) {
  switch (navId) {
    case SettingsNavId.server:
      return l10n.serverSection.toUpperCase();
    case SettingsNavId.desktopHost:
      return 'DESKTOP HOST';
    case SettingsNavId.remoteAccess:
      return l10n.remoteAccess.toUpperCase();
    case SettingsNavId.models:
      return l10n.modelsSection.toUpperCase();
    case SettingsNavId.appearance:
      return l10n.appearanceSection.toUpperCase();
    case SettingsNavId.voice:
      return SettingsSectionIdCompat.voice;
    case SettingsNavId.transcription:
      return SettingsSectionIdCompat.transcription;
    case SettingsNavId.widgets:
      return l10n.widgetSettings.toUpperCase();
    case SettingsNavId.siri:
      return 'SIRI & SHORTCUTS';
    case SettingsNavId.appleWatch:
      return 'APPLE WATCH';
    case SettingsNavId.imageGeneration:
      return l10n.imageGeneration.toUpperCase();
    case SettingsNavId.language:
      return SettingsSectionIdCompat.language;
    case SettingsNavId.support:
      return l10n.supportSection.toUpperCase();
    case SettingsNavId.data:
      return l10n.dataSection.toUpperCase();
    case SettingsNavId.advanced:
      return l10n.advancedSection.toUpperCase();
    case SettingsNavId.legal:
      return l10n.legalSection.toUpperCase();
    case SettingsNavId.account:
      return l10n.accountSection.toUpperCase();
    case SettingsNavId.pro:
      return l10n.lmMiniProSection.toUpperCase();
    default:
      return null;
  }
}

/// Mirrors [SettingsSectionId] without importing settings_screen (cycle).
abstract final class SettingsSectionIdCompat {
  static const voice = 'voice';
  static const transcription = 'transcription';
  static const language = 'language';
}

String _stripSectionCase(String title) {
  if (title == title.toUpperCase() && title.length > 1) {
    return title
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
  return title;
}

/// Parent group id for a leaf/group nav id (for expand state).
String? groupIdForNavId(String navId, List<SettingsNavGroup> tree) {
  for (final g in tree) {
    if (g.id == navId) return g.id;
    for (final leaf in g.leaves) {
      if (leaf.id == navId) return g.id;
    }
  }
  return null;
}
