import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/image_picker_helper.dart';
import '../utils/layout_utils.dart';
import '../widgets/desktop_settings_controls.dart';
import '../widgets/glass_blur.dart';
import '../widgets/glass_settings_scaffold.dart';
import 'theme_settings_screen.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  final bool embedded;
  final bool highlightFullWidth;
  const AppearanceSettingsScreen({
    super.key,
    this.embedded = false,
    this.highlightFullWidth = false,
  });

  String _enterKeyLabel(AppLocalizations l10n, String mode) {
    switch (mode) {
      case 'send':
        return l10n.enterKeySendDescription;
      case 'newline':
        return l10n.enterKeyNewlineDescription;
      case 'auto':
      default:
        return l10n.enterKeyAutoDescription;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GlassSettingsScaffold(
      embedded: embedded,
      title: l10n.appearance,
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          final lookAndFeel = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionLabel(context, 'Look & feel'),
              const SizedBox(height: 10),
              _card(
                context,
                child: Column(
                  children: [
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                        return _navRow(
                          context,
                          icon: Icons.palette_outlined,
                          title: themeProvider.currentTheme.name,
                          subtitle: themeProvider.currentTheme.description,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ThemeSettingsScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.themeSection,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          _buildSegmentedControl(
                            context,
                            value: settingsProvider.settings.themeMode,
                            onChanged: settingsProvider.updateThemeMode,
                          ),
                          ..._themeWarnings(context, settingsProvider),
                        ],
                      ),
                    ),
                    _divider(context),
                    _toggleRow(
                      context,
                      icon: Icons.battery_saver_outlined,
                      title: l10n.lowBatteryModeLabel,
                      subtitle: l10n.lowBatteryModeSubtitle,
                      value: settingsProvider.settings.lowBatteryMode,
                      onChanged: settingsProvider.updateLowBatteryMode,
                    ),
                    _divider(context),
                    _toggleRow(
                      context,
                      icon: Icons.blur_on_rounded,
                      title: l10n.glassEffectsLabel,
                      subtitle: l10n.glassEffectsSubtitle,
                      value: settingsProvider.settings.glassEffectsActive,
                      enabled: !settingsProvider.settings.lowBatteryMode,
                      onChanged: settingsProvider.updateGlassEffectsEnabled,
                    ),
                  ],
                ),
              ),
            ],
          );

          final wallpaper = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionLabel(context, 'Chat wallpaper'),
              const SizedBox(height: 10),
              _WallpaperCard(
                imagePath: settingsProvider.settings.chatBackgroundPath,
                overlayOpacity:
                    settingsProvider.settings.chatBackgroundOverlayOpacity,
                title: l10n.chatBackground,
                subtitle: l10n.chatBackgroundSubtitle,
                overlayLabel: l10n.darkOverlay,
                overlayHint: l10n.darkOverlayDescription,
                onPick: () => _pickChatBackground(context, settingsProvider),
                onClear: () => settingsProvider.updateChatBackground(null),
                onOverlayChanged:
                    settingsProvider.updateChatBackgroundOverlayOpacity,
              ),
            ],
          );

          final desktop = prefersWideSettingsLayout(context);
          return DesktopSettingsForm(
            maxWidth: desktop ? 880 : double.infinity,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                desktop ? 0 : 16,
                desktop ? 12 : 20,
                desktop ? 0 : 16,
                32,
              ),
              children: [
                SettingsTwoColumn(
                  left: lookAndFeel,
                  right: wallpaper,
                ),
                const SizedBox(height: 22),
                _sectionLabel(context, 'Pictures'),
                const SizedBox(height: 10),
                _card(
                  context,
                  child: Column(
                    children: [
                      _toggleRow(
                        context,
                        icon: Icons.hide_image_outlined,
                        title: l10n.hideAvatarsLabel,
                        subtitle: l10n.hideAvatarsSubtitle,
                        value: settingsProvider.settings.hideAvatars,
                        onChanged: settingsProvider.updateHideAvatars,
                      ),
                      _divider(context),
                      IgnorePointer(
                        ignoring: settingsProvider.settings.hideAvatars,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity:
                              settingsProvider.settings.hideAvatars ? 0.4 : 1,
                          child: Column(
                            children: [
                              _toggleRow(
                                context,
                                icon: Icons.person_pin_circle_outlined,
                                title: l10n.chatHeaderAvatarLabel,
                                subtitle: l10n.chatHeaderAvatarSubtitle,
                                value: settingsProvider
                                    .settings.showChatHeaderAvatar,
                                enabled: !settingsProvider.settings.hideAvatars,
                                onChanged:
                                    settingsProvider.updateShowChatHeaderAvatar,
                              ),
                              _divider(context),
                              _toggleRow(
                                context,
                                icon: Icons.vertical_align_top_rounded,
                                title: l10n.avatarAboveMessageLabel,
                                subtitle: l10n.avatarAboveMessageSubtitle,
                                value: settingsProvider
                                    .settings.avatarAboveMessage,
                                enabled: !settingsProvider.settings.hideAvatars,
                                onChanged:
                                    settingsProvider.updateAvatarAboveMessage,
                              ),
                              if (settingsProvider.isAdvancedSettings) ...[
                                _divider(context),
                                _sliderRow(
                                  context,
                                  icon: Icons.photo_size_select_large_rounded,
                                  title: l10n.bubbleAvatarSizeLabel,
                                  valueLabel: l10n.bubbleAvatarRadiusValue(
                                    settingsProvider
                                        .settings.chatBubbleAvatarRadius
                                        .round(),
                                  ),
                                  value: settingsProvider
                                      .settings.chatBubbleAvatarRadius,
                                  min: 14,
                                  max: 32,
                                  divisions: 18,
                                  onChanged: settingsProvider
                                      .updateChatBubbleAvatarRadius,
                                ),
                              ],
                              _divider(context),
                              _avatarPickRow(
                                context,
                                title: l10n.userAvatarLabel,
                                subtitle: l10n.yourProfilePicture,
                                imagePath:
                                    settingsProvider.settings.userAvatarPath,
                                placeholder: Icons.person_outline_rounded,
                                onTap: () =>
                                    _pickUserAvatar(context, settingsProvider),
                                onClear: () =>
                                    settingsProvider.updateUserAvatar(null),
                              ),
                              _divider(context),
                              _avatarPickRow(
                                context,
                                title: l10n.assistantAvatarLabel,
                                subtitle: l10n.aiAssistantPicture,
                                imagePath: settingsProvider
                                    .settings.assistantAvatarPath,
                                placeholder: Icons.smart_toy_outlined,
                                onTap: () => _pickAssistantAvatar(
                                    context, settingsProvider),
                                onClear: () => settingsProvider
                                    .updateAssistantAvatar(null),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _sectionLabel(context, 'Chat text'),
                const SizedBox(height: 10),
                _card(
                  context,
                  child: Column(
                    children: [
                      _ScrollIntoView(
                        enabled: highlightFullWidth,
                        child: _toggleRow(
                          context,
                          icon: Icons.format_align_left_rounded,
                          title: l10n.fullWidthAssistantLabel,
                          subtitle: l10n.fullWidthAssistantSubtitle,
                          value: settingsProvider.settings.fullWidthAssistant,
                          onChanged: settingsProvider.updateFullWidthAssistant,
                        ),
                      ),
                      _divider(context),
                      _sliderRow(
                        context,
                        icon: Icons.text_fields_rounded,
                        title: l10n.fontSizeLabel,
                        valueLabel: l10n.pointsValue(
                          settingsProvider.settings.chatFontSize.round(),
                        ),
                        value: settingsProvider.settings.chatFontSize,
                        min: 10,
                        max: 24,
                        divisions: 14,
                        onChanged: settingsProvider.updateChatFontSize,
                      ),
                      _divider(context),
                      _buildSampleBubble(context, settingsProvider),
                      if (settingsProvider.isAdvancedSettings) ...[
                        _divider(context),
                        _sliderRow(
                          context,
                          icon: Icons.touch_app_outlined,
                          title: l10n.iconSizeLabel,
                          valueLabel: l10n.pointsValue(
                            settingsProvider.settings.chatIconSize.round(),
                          ),
                          value: settingsProvider.settings.chatIconSize,
                          min: 10,
                          max: 24,
                          divisions: 14,
                          onChanged: settingsProvider.updateChatIconSize,
                        ),
                        _divider(context),
                        _toggleRow(
                          context,
                          icon: Icons.vertical_align_bottom_rounded,
                          title: l10n.autoScrollStreaming,
                          subtitle: l10n.autoScrollStreamingSubtitle,
                          value: settingsProvider.settings.autoScrollEnabled,
                          onChanged: settingsProvider.updateAutoScrollEnabled,
                        ),
                        _divider(context),
                        _toggleRow(
                          context,
                          icon: Icons.dashboard_customize_outlined,
                          title: l10n.showChatStarters,
                          subtitle: l10n.showChatStartersSubtitle,
                          value: settingsProvider.settings.showChatStarters,
                          onChanged: settingsProvider.updateShowChatStarters,
                        ),
                        _divider(context),
                        _toggleRow(
                          context,
                          icon: Icons.chat_bubble_outline_rounded,
                          title: l10n.useLegacyComposer,
                          subtitle: l10n.useLegacyComposerSubtitle,
                          value: settingsProvider.settings.useLegacyComposer,
                          onChanged: settingsProvider.updateUseLegacyComposer,
                        ),
                      ],
                      _divider(context),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _softIcon(
                                    context, Icons.keyboard_return_rounded),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.enterKeyBehaviorLabel,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _enterKeyLabel(
                                          l10n,
                                          settingsProvider
                                              .settings.enterKeyBehavior,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _enterKeySegments(
                              context,
                              value: settingsProvider.settings.enterKeyBehavior,
                              onChanged: (v) {
                                settingsProvider.updateSettings(
                                  settingsProvider.settings
                                      .copyWith(enterKeyBehavior: v),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _themeWarnings(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    final themeProvider = context.watch<ThemeProvider>();
    final isCustomTheme = !themeProvider.currentTheme.isBuiltIn;
    final isThemeDark = themeProvider.currentTheme.isDarkTheme;
    final activeMode = settingsProvider.settings.themeMode;
    final platformBrightness = MediaQuery.of(context).platformBrightness;
    final isSystemDark = platformBrightness == Brightness.dark;
    final isEffectivelyDark = activeMode == ThemeMode.dark ||
        (activeMode == ThemeMode.system && isSystemDark);
    final showDarkModeWarning =
        isCustomTheme && !isThemeDark && isEffectivelyDark;
    final showLightModeWarning =
        isCustomTheme && isThemeDark && !isEffectivelyDark;
    if (!showDarkModeWarning && !showLightModeWarning) return const [];
    return [
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              showDarkModeWarning
                  ? 'This custom theme does not support dark mode. Change your theme to enable it.'
                  : 'This custom theme does not support light mode. Change your theme to enable it.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _sectionLabel(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest.withValues(alpha: 0.45)
            : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
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

  Widget _softIcon(BuildContext context, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: cs.primary, size: 22),
    );
  }

  Widget _divider(BuildContext context) {
    if (useDesktopSettingsControls(context)) {
      return const SizedBox(height: 2);
    }
    return Divider(
      height: 1,
      indent: 66,
      color:
          Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.45),
    );
  }

  Widget _toggleRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return DesktopPreferenceRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _sliderRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return DesktopSliderField(
      icon: icon,
      title: title,
      valueLabel: valueLabel,
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      onChanged: onChanged,
    );
  }

  Widget _avatarPickRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String? imagePath,
    required IconData placeholder,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final cs = Theme.of(context).colorScheme;
    final resolved = ImagePickerHelper.resolveImagePathSync(imagePath);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 52,
                height: 52,
                color: cs.primary.withValues(alpha: 0.10),
                child: resolved != null
                    ? Image.file(File(resolved), fit: BoxFit.cover)
                    : Icon(placeholder, color: cs.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (imagePath != null)
              IconButton(
                onPressed: onClear,
                icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
              )
            else
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _enterKeySegments(
    BuildContext context, {
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    final l10n = AppLocalizations.of(context);
    final items = <(String, String)>[
      ('auto', l10n.auto),
      ('send', l10n.sendLabel),
      ('newline', l10n.newLineLabel),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(item.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: value == item.$1
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: value == item.$1
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: value == item.$1
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _previewIcon(BuildContext context, IconData icon, String label,
      double size, Color textColor) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.appearanceActionTapped(label)),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Icon(icon, size: size, color: textColor.withValues(alpha: 0.7)),
    );
  }

  Widget _buildSampleBubble(
      BuildContext context, SettingsProvider settingsProvider) {
    final settings = settingsProvider.settings;
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final bubbleColor = colorScheme.surfaceContainerHighest;
    final textColor = colorScheme.onSurface;
    final iconSize = settings.chatIconSize;
    final userBubbleColor = colorScheme.primary;
    final userTextColor = colorScheme.onPrimary;
    final fullWidth = settings.fullWidthAssistant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.previewLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          if (fullWidth) ...[
            Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: userBubbleColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    l10n.previewUserMessage,
                    style: TextStyle(
                      fontSize: settings.chatFontSize,
                      color: userTextColor,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.welcomeWizardAppearancePreviewMessage,
              style: TextStyle(
                fontSize: settings.chatFontSize,
                color: textColor,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _previewIcon(
                    context, Icons.copy, l10n.copy, iconSize, textColor),
                const SizedBox(width: 4),
                _previewIcon(
                    context,
                    Icons.more_horiz_rounded,
                    MaterialLocalizations.of(context).moreButtonTooltip,
                    iconSize,
                    textColor),
              ],
            ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.welcomeWizardAppearancePreviewMessage,
                    style: TextStyle(
                      fontSize: settings.chatFontSize,
                      color: textColor,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _previewIcon(
                          context, Icons.copy, l10n.copy, iconSize, textColor),
                      const SizedBox(width: 14),
                      _previewIcon(context, Icons.volume_up_outlined,
                          l10n.readAloud, iconSize, textColor),
                      const SizedBox(width: 14),
                      _previewIcon(context, Icons.refresh, l10n.regenerate,
                          iconSize, textColor),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(
    BuildContext context, {
    required ThemeMode value,
    required ValueChanged<ThemeMode> onChanged,
  }) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton(
                context, l10n.themeSystem, ThemeMode.system, value, onChanged),
          ),
          Expanded(
            child: _buildSegmentButton(
                context, l10n.themeLight, ThemeMode.light, value, onChanged),
          ),
          Expanded(
            child: _buildSegmentButton(
                context, l10n.themeDark, ThemeMode.dark, value, onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(
    BuildContext context,
    String label,
    ThemeMode mode,
    ThemeMode currentMode,
    ValueChanged<ThemeMode> onChanged,
  ) {
    final isSelected = mode == currentMode;
    return GestureDetector(
      onTap: () => onChanged(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _pickChatBackground(
      BuildContext context, SettingsProvider settingsProvider) async {
    final imageFile = await ImagePickerHelper.pickFromGallery(context);
    if (imageFile != null) {
      final relativePath = ImagePickerHelper.toRelativePath(imageFile.path);
      settingsProvider.updateChatBackground(relativePath);
    }
  }

  Future<void> _pickUserAvatar(
      BuildContext context, SettingsProvider settingsProvider) async {
    final imageFile = await ImagePickerHelper.pickFromGallery(context);
    if (imageFile != null) {
      final relativePath = ImagePickerHelper.toRelativePath(imageFile.path);
      settingsProvider.updateUserAvatar(relativePath);
    }
  }

  Future<void> _pickAssistantAvatar(
      BuildContext context, SettingsProvider settingsProvider) async {
    final imageFile = await ImagePickerHelper.pickFromGallery(context);
    if (imageFile != null) {
      final relativePath = ImagePickerHelper.toRelativePath(imageFile.path);
      settingsProvider.updateAssistantAvatar(relativePath);
    }
  }
}

class _WallpaperCard extends StatelessWidget {
  final String? imagePath;
  final double overlayOpacity;
  final String title;
  final String subtitle;
  final String overlayLabel;
  final String overlayHint;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final ValueChanged<double> onOverlayChanged;

  const _WallpaperCard({
    required this.imagePath,
    required this.overlayOpacity,
    required this.title,
    required this.subtitle,
    required this.overlayLabel,
    required this.overlayHint,
    required this.onPick,
    required this.onClear,
    required this.onOverlayChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolved = ImagePickerHelper.resolveImagePathSync(imagePath);
    final hasImage = resolved != null;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest.withValues(alpha: 0.45)
            : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  Image.file(File(resolved), fit: BoxFit.cover)
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.primary.withValues(alpha: 0.35),
                          cs.tertiary.withValues(alpha: 0.25),
                          cs.surfaceContainerHighest,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.wallpaper_rounded,
                        size: 42,
                        color: cs.onSurface.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                if (hasImage)
                  ColoredBox(
                    color: Colors.black.withValues(
                      alpha: (overlayOpacity / 100.0).clamp(0.0, 1.0),
                    ),
                  ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: GlassBlur(
                      sigmaX: 16,
                      sigmaY: 16,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                        color: Colors.black.withValues(alpha: 0.28),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    hasImage ? 'Tap to change photo' : subtitle,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.78),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: onPick,
                              tooltip: title,
                              icon: const Icon(Icons.photo_library_outlined,
                                  color: Colors.white),
                            ),
                            if (hasImage)
                              IconButton(
                                onPressed: onClear,
                                tooltip: 'Remove',
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.opacity_rounded,
                        size: 18, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        overlayLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${overlayOpacity.round()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: overlayOpacity.clamp(0.0, 100.0),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    onChanged: hasImage ? onOverlayChanged : null,
                  ),
                ),
                Text(
                  overlayHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollIntoView extends StatefulWidget {
  final bool enabled;
  final Widget child;

  const _ScrollIntoView({required this.enabled, required this.child});

  @override
  State<_ScrollIntoView> createState() => _ScrollIntoViewState();
}

class _ScrollIntoViewState extends State<_ScrollIntoView> {
  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.2,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
