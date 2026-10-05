import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/bundled_google_fonts.dart';

/// Defines the color palette and style overrides for a single brightness mode.
class AppThemeColors {
  final Color seedColor;
  final Color? primary;
  final Color? onPrimary;
  final Color? primaryContainer;
  final Color? onPrimaryContainer;
  final Color? secondary;
  final Color? onSecondary;
  final Color? secondaryContainer;
  final Color? onSecondaryContainer;
  final Color? tertiary;
  final Color? surface;
  final Color? onSurface;
  final Color? surfaceContainerHighest;
  final Color? surfaceContainerHigh;
  final Color? surfaceContainer;
  final Color? surfaceContainerLow;
  final Color? surfaceContainerLowest;
  final Color? outline;
  final Color? outlineVariant;
  final Color? error;

  /// Chat bubble colors
  final Color? userBubbleColor;
  final Color? userBubbleTextColor;
  final Color? assistantBubbleColor;
  final Color? assistantBubbleTextColor;

  /// Conversation list colors
  final Color? conversationListBackground;
  final Color? conversationListItemColor;
  final Color? conversationListSelectedColor;

  /// Scaffold / app bar
  final Color? scaffoldBackground;
  final Color? appBarBackground;
  final Color? appBarForeground;

  /// Navigation
  final Color? navBarBackground;
  final Color? navBarSelectedColor;
  final Color? navBarUnselectedColor;

  /// Dialog
  final Color? dialogBackground;

  /// Settings list tile tint
  final Color? settingsListTileColor;

  /// Gradient (optional, for screens that support gradients)
  final List<Color>? backgroundGradient;

  const AppThemeColors({
    required this.seedColor,
    this.primary,
    this.onPrimary,
    this.primaryContainer,
    this.onPrimaryContainer,
    this.secondary,
    this.onSecondary,
    this.secondaryContainer,
    this.onSecondaryContainer,
    this.tertiary,
    this.surface,
    this.onSurface,
    this.surfaceContainerHighest,
    this.surfaceContainerHigh,
    this.surfaceContainer,
    this.surfaceContainerLow,
    this.surfaceContainerLowest,
    this.outline,
    this.outlineVariant,
    this.error,
    this.userBubbleColor,
    this.userBubbleTextColor,
    this.assistantBubbleColor,
    this.assistantBubbleTextColor,
    this.conversationListBackground,
    this.conversationListItemColor,
    this.conversationListSelectedColor,
    this.scaffoldBackground,
    this.appBarBackground,
    this.appBarForeground,
    this.navBarBackground,
    this.navBarSelectedColor,
    this.navBarUnselectedColor,
    this.dialogBackground,
    this.settingsListTileColor,
    this.backgroundGradient,
  });

  Map<String, dynamic> toJson() {
    return {
      'seedColor': seedColor.value,
      if (primary != null) 'primary': primary!.value,
      if (onPrimary != null) 'onPrimary': onPrimary!.value,
      if (primaryContainer != null) 'primaryContainer': primaryContainer!.value,
      if (onPrimaryContainer != null)
        'onPrimaryContainer': onPrimaryContainer!.value,
      if (secondary != null) 'secondary': secondary!.value,
      if (onSecondary != null) 'onSecondary': onSecondary!.value,
      if (secondaryContainer != null)
        'secondaryContainer': secondaryContainer!.value,
      if (onSecondaryContainer != null)
        'onSecondaryContainer': onSecondaryContainer!.value,
      if (tertiary != null) 'tertiary': tertiary!.value,
      if (surface != null) 'surface': surface!.value,
      if (onSurface != null) 'onSurface': onSurface!.value,
      if (surfaceContainerHighest != null)
        'surfaceContainerHighest': surfaceContainerHighest!.value,
      if (surfaceContainerHigh != null)
        'surfaceContainerHigh': surfaceContainerHigh!.value,
      if (surfaceContainer != null) 'surfaceContainer': surfaceContainer!.value,
      if (surfaceContainerLow != null)
        'surfaceContainerLow': surfaceContainerLow!.value,
      if (surfaceContainerLowest != null)
        'surfaceContainerLowest': surfaceContainerLowest!.value,
      if (outline != null) 'outline': outline!.value,
      if (outlineVariant != null) 'outlineVariant': outlineVariant!.value,
      if (error != null) 'error': error!.value,
      if (userBubbleColor != null) 'userBubbleColor': userBubbleColor!.value,
      if (userBubbleTextColor != null)
        'userBubbleTextColor': userBubbleTextColor!.value,
      if (assistantBubbleColor != null)
        'assistantBubbleColor': assistantBubbleColor!.value,
      if (assistantBubbleTextColor != null)
        'assistantBubbleTextColor': assistantBubbleTextColor!.value,
      if (conversationListBackground != null)
        'conversationListBackground': conversationListBackground!.value,
      if (conversationListItemColor != null)
        'conversationListItemColor': conversationListItemColor!.value,
      if (conversationListSelectedColor != null)
        'conversationListSelectedColor': conversationListSelectedColor!.value,
      if (scaffoldBackground != null)
        'scaffoldBackground': scaffoldBackground!.value,
      if (appBarBackground != null) 'appBarBackground': appBarBackground!.value,
      if (appBarForeground != null) 'appBarForeground': appBarForeground!.value,
      if (navBarBackground != null) 'navBarBackground': navBarBackground!.value,
      if (navBarSelectedColor != null)
        'navBarSelectedColor': navBarSelectedColor!.value,
      if (navBarUnselectedColor != null)
        'navBarUnselectedColor': navBarUnselectedColor!.value,
      if (dialogBackground != null) 'dialogBackground': dialogBackground!.value,
      if (settingsListTileColor != null)
        'settingsListTileColor': settingsListTileColor!.value,
      if (backgroundGradient != null)
        'backgroundGradient': backgroundGradient!.map((c) => c.value).toList(),
    };
  }

  factory AppThemeColors.fromJson(Map<String, dynamic> json) {
    return AppThemeColors(
      seedColor: Color(json['seedColor'] as int),
      primary: json['primary'] != null ? Color(json['primary'] as int) : null,
      onPrimary:
          json['onPrimary'] != null ? Color(json['onPrimary'] as int) : null,
      primaryContainer: json['primaryContainer'] != null
          ? Color(json['primaryContainer'] as int)
          : null,
      onPrimaryContainer: json['onPrimaryContainer'] != null
          ? Color(json['onPrimaryContainer'] as int)
          : null,
      secondary:
          json['secondary'] != null ? Color(json['secondary'] as int) : null,
      onSecondary: json['onSecondary'] != null
          ? Color(json['onSecondary'] as int)
          : null,
      secondaryContainer: json['secondaryContainer'] != null
          ? Color(json['secondaryContainer'] as int)
          : null,
      onSecondaryContainer: json['onSecondaryContainer'] != null
          ? Color(json['onSecondaryContainer'] as int)
          : null,
      tertiary:
          json['tertiary'] != null ? Color(json['tertiary'] as int) : null,
      surface: json['surface'] != null ? Color(json['surface'] as int) : null,
      onSurface:
          json['onSurface'] != null ? Color(json['onSurface'] as int) : null,
      surfaceContainerHighest: json['surfaceContainerHighest'] != null
          ? Color(json['surfaceContainerHighest'] as int)
          : null,
      surfaceContainerHigh: json['surfaceContainerHigh'] != null
          ? Color(json['surfaceContainerHigh'] as int)
          : null,
      surfaceContainer: json['surfaceContainer'] != null
          ? Color(json['surfaceContainer'] as int)
          : null,
      surfaceContainerLow: json['surfaceContainerLow'] != null
          ? Color(json['surfaceContainerLow'] as int)
          : null,
      surfaceContainerLowest: json['surfaceContainerLowest'] != null
          ? Color(json['surfaceContainerLowest'] as int)
          : null,
      outline: json['outline'] != null ? Color(json['outline'] as int) : null,
      outlineVariant: json['outlineVariant'] != null
          ? Color(json['outlineVariant'] as int)
          : null,
      error: json['error'] != null ? Color(json['error'] as int) : null,
      userBubbleColor: json['userBubbleColor'] != null
          ? Color(json['userBubbleColor'] as int)
          : null,
      userBubbleTextColor: json['userBubbleTextColor'] != null
          ? Color(json['userBubbleTextColor'] as int)
          : null,
      assistantBubbleColor: json['assistantBubbleColor'] != null
          ? Color(json['assistantBubbleColor'] as int)
          : null,
      assistantBubbleTextColor: json['assistantBubbleTextColor'] != null
          ? Color(json['assistantBubbleTextColor'] as int)
          : null,
      conversationListBackground: json['conversationListBackground'] != null
          ? Color(json['conversationListBackground'] as int)
          : null,
      conversationListItemColor: json['conversationListItemColor'] != null
          ? Color(json['conversationListItemColor'] as int)
          : null,
      conversationListSelectedColor:
          json['conversationListSelectedColor'] != null
              ? Color(json['conversationListSelectedColor'] as int)
              : null,
      scaffoldBackground: json['scaffoldBackground'] != null
          ? Color(json['scaffoldBackground'] as int)
          : null,
      appBarBackground: json['appBarBackground'] != null
          ? Color(json['appBarBackground'] as int)
          : null,
      appBarForeground: json['appBarForeground'] != null
          ? Color(json['appBarForeground'] as int)
          : null,
      navBarBackground: json['navBarBackground'] != null
          ? Color(json['navBarBackground'] as int)
          : null,
      navBarSelectedColor: json['navBarSelectedColor'] != null
          ? Color(json['navBarSelectedColor'] as int)
          : null,
      navBarUnselectedColor: json['navBarUnselectedColor'] != null
          ? Color(json['navBarUnselectedColor'] as int)
          : null,
      dialogBackground: json['dialogBackground'] != null
          ? Color(json['dialogBackground'] as int)
          : null,
      settingsListTileColor: json['settingsListTileColor'] != null
          ? Color(json['settingsListTileColor'] as int)
          : null,
      backgroundGradient: json['backgroundGradient'] != null
          ? (json['backgroundGradient'] as List)
              .map((c) => Color(c as int))
              .toList()
          : null,
    );
  }
}

/// Chat bubble visual style.
enum BubbleStyle {
  /// Default rounded rectangle (current).
  rounded,

  /// iOS-style with a small tail pointing to the sender.
  tail,

  /// Flat rectangles with minimal rounding (like SMS).
  flat,

  /// Rounded pill-like capsules.
  pill,
}

/// A complete app theme with light and dark color palettes.
class AppTheme {
  final String id;
  final String name;
  final String description;
  final String author;
  final String version;
  final AppThemeColors lightColors;
  final AppThemeColors darkColors;
  final bool isBuiltIn;
  final String? previewImageUrl;
  final DateTime? createdAt;
  final int downloadCount;

  // Bubble style
  final BubbleStyle bubbleStyle;

  // Typography
  final String? fontFamily; // Google Fonts family name (null = system default)

  // Icon pack (Firebase Storage path to a zip of replacement icons)
  final String? iconPackUrl;

  // Custom icon images (local file paths, keyed by slot name)
  // Slots: 'home_settings', 'home_search', 'home_folder', 'home_filter',
  //        'chat_voice', 'chat_settings', 'chat_menu',
  //        'input_attach', 'input_mic', 'input_send'
  final Map<String, String>? customIcons;

  // Show profile images in conversation list & chat app bar
  final bool showProfileImages;

  // Profile image avatar radius (default 22, range 17-27)
  final double profileImageRadius;

  // Whether this is a dark-only theme
  final bool isDarkTheme;

  const AppTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    required this.version,
    required this.lightColors,
    required this.darkColors,
    this.isBuiltIn = false,
    this.previewImageUrl,
    this.createdAt,
    this.downloadCount = 0,
    this.bubbleStyle = BubbleStyle.rounded,
    this.fontFamily,
    this.iconPackUrl,
    this.customIcons,
    this.showProfileImages = false,
    this.profileImageRadius = 22,
    this.isDarkTheme = false,
  });

  /// Create a mutable copy with overrides.
  AppTheme copyWith({
    String? id,
    String? name,
    String? description,
    String? author,
    String? version,
    AppThemeColors? lightColors,
    AppThemeColors? darkColors,
    bool? isBuiltIn,
    String? previewImageUrl,
    DateTime? createdAt,
    int? downloadCount,
    BubbleStyle? bubbleStyle,
    String? fontFamily,
    String? iconPackUrl,
    Map<String, String>? customIcons,
    bool? showProfileImages,
    double? profileImageRadius,
    bool? isDarkTheme,
  }) {
    return AppTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      author: author ?? this.author,
      version: version ?? this.version,
      lightColors: lightColors ?? this.lightColors,
      darkColors: darkColors ?? this.darkColors,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      previewImageUrl: previewImageUrl ?? this.previewImageUrl,
      createdAt: createdAt ?? this.createdAt,
      downloadCount: downloadCount ?? this.downloadCount,
      bubbleStyle: bubbleStyle ?? this.bubbleStyle,
      fontFamily: fontFamily ?? this.fontFamily,
      iconPackUrl: iconPackUrl ?? this.iconPackUrl,
      customIcons: customIcons ?? this.customIcons,
      showProfileImages: showProfileImages ?? this.showProfileImages,
      profileImageRadius: profileImageRadius ?? this.profileImageRadius,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'author': author,
      'version': version,
      'lightColors': lightColors.toJson(),
      'darkColors': darkColors.toJson(),
      'isBuiltIn': isBuiltIn,
      if (previewImageUrl != null) 'previewImageUrl': previewImageUrl,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      'downloadCount': downloadCount,
      'bubbleStyle': bubbleStyle.name,
      if (fontFamily != null) 'fontFamily': fontFamily,
      if (iconPackUrl != null) 'iconPackUrl': iconPackUrl,
      if (customIcons != null && customIcons!.isNotEmpty)
        'customIcons': customIcons,
      'showProfileImages': showProfileImages,
      'profileImageRadius': profileImageRadius,
      'isDarkTheme': isDarkTheme,
    };
  }

  factory AppTheme.fromJson(Map<String, dynamic> json) {
    return AppTheme(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      author: json['author'] as String? ?? 'Unknown',
      version: json['version'] as String? ?? '1.0.0',
      lightColors:
          AppThemeColors.fromJson(json['lightColors'] as Map<String, dynamic>),
      darkColors:
          AppThemeColors.fromJson(json['darkColors'] as Map<String, dynamic>),
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      previewImageUrl: json['previewImageUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      downloadCount: json['downloadCount'] as int? ?? 0,
      bubbleStyle: json['bubbleStyle'] != null
          ? BubbleStyle.values.firstWhere(
              (e) => e.name == json['bubbleStyle'],
              orElse: () => BubbleStyle.rounded,
            )
          : BubbleStyle.rounded,
      fontFamily: json['fontFamily'] as String?,
      iconPackUrl: json['iconPackUrl'] as String?,
      customIcons: json['customIcons'] != null
          ? Map<String, String>.from(json['customIcons'] as Map)
          : null,
      showProfileImages: json['showProfileImages'] as bool? ?? false,
      profileImageRadius:
          (json['profileImageRadius'] as num?)?.toDouble() ?? 22,
      isDarkTheme: json['isDarkTheme'] as bool? ?? false,
    );
  }

  /// Build a Flutter [ThemeData] from this theme's colors for the given brightness.
  ThemeData toThemeData(Brightness requestedBrightness) {
    // Custom themes only provide one manually designed palette and auto-derive the other.
    // To ensure the applied theme matches the author's preview exactly, we force the
    // brightness to match what it was designed for, ignoring the system theme mode.
    final brightness = isBuiltIn
        ? requestedBrightness
        : (isDarkTheme ? Brightness.dark : Brightness.light);

    final colors = brightness == Brightness.light ? lightColors : darkColors;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: colors.seedColor,
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.primaryContainer,
      onPrimaryContainer: colors.onPrimaryContainer,
      secondary: colors.secondary,
      onSecondary: colors.onSecondary,
      secondaryContainer: colors.secondaryContainer,
      onSecondaryContainer: colors.onSecondaryContainer,
      tertiary: colors.tertiary,
      surface: colors.surface,
      onSurface: colors.onSurface,
      surfaceContainerHighest: colors.surfaceContainerHighest,
      surfaceContainerHigh: colors.surfaceContainerHigh,
      surfaceContainer: colors.surfaceContainer,
      surfaceContainerLow: colors.surfaceContainerLow,
      surfaceContainerLowest: colors.surfaceContainerLowest,
      outline: colors.outline,
      outlineVariant: colors.outlineVariant,
      error: colors.error,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colors.scaffoldBackground,
      textTheme: BundledGoogleFonts.textThemeOrNull(fontFamily),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.appBarBackground,
        foregroundColor: colors.appBarForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
              ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.dialogBackground ?? colorScheme.surface,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.dialogBackground ?? colorScheme.surface,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.dialogBackground ?? colorScheme.surface,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
      ),
      listTileTheme: colors.settingsListTileColor != null
          ? ListTileThemeData(
              tileColor: colors.settingsListTileColor,
            )
          : null,
      inputDecorationTheme: const InputDecorationTheme(
        helperMaxLines: 2,
        labelStyle: TextStyle(fontSize: 13),
        helperStyle: TextStyle(fontSize: 11),
        hintStyle: TextStyle(fontSize: 13),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

// ── Built-in themes ────────────────────────────────────────────

/// The default deep purple theme (current app appearance).
const defaultTheme = AppTheme(
  id: 'default',
  name: 'Default',
  description: 'Clean deep purple Material 3 theme',
  author: 'LM Mini',
  version: '1.0.0',
  isBuiltIn: true,
  lightColors: AppThemeColors(
    seedColor: Color(0xFF673AB7), // Colors.deepPurple
  ),
  darkColors: AppThemeColors(
    seedColor: Color(0xFF673AB7),
  ),
);

/// Messenger-inspired pink gradient theme.
const messengerTheme = AppTheme(
  id: 'messenger',
  name: 'Messenger',
  description: 'Soft pink gradient inspired by modern messengers',
  author: 'LM Mini',
  version: '1.0.0',
  isBuiltIn: true,
  bubbleStyle: BubbleStyle.pill,
  showProfileImages: true,
  lightColors: AppThemeColors(
    seedColor: Color(0xFFE091C8), // soft pink
    primary: Color(0xFFD16BA5),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF8D7EC),
    onPrimaryContainer: Color(0xFF4A1942),
    secondary: Color(0xFF9B6CB0),
    secondaryContainer: Color(0xFFF0E0F5),
    surface: Color(0xFFFFF8FB),
    onSurface: Color(0xFF1E1A20),
    scaffoldBackground: Color(0xFFFFF0F7),
    appBarBackground: Color(0x00000000), // transparent for gradient
    appBarForeground: Color(0xFF2D1B3D),
    userBubbleColor: Color(0xFFE8E0EC),
    userBubbleTextColor: Color(0xFF2D1B3D),
    assistantBubbleColor: Color(0xFFFFFFFF),
    assistantBubbleTextColor: Color(0xFF2D1B3D),
    conversationListBackground: Color(0xFFFFF0F7),
    dialogBackground: Color(0xFFFFF8FB),
    backgroundGradient: [
      Color(0xFFFCE4F3), // light pink
      Color(0xFFE8D5F5), // light lavender
      Color(0xFFD5E8FC), // light blue
    ],
  ),
  darkColors: AppThemeColors(
    seedColor: Color(0xFFE091C8),
    primary: Color(0xFFE8A0D0),
    onPrimary: Color(0xFF3B1030),
    primaryContainer: Color(0xFF5C2050),
    onPrimaryContainer: Color(0xFFF8D7EC),
    secondary: Color(0xFFB890CE),
    secondaryContainer: Color(0xFF3D2848),
    surface: Color(0xFF1C1420),
    onSurface: Color(0xFFEDE0E8),
    scaffoldBackground: Color(0xFF160E1C),
    appBarBackground: Color(0x00000000),
    appBarForeground: Color(0xFFEDE0E8),
    userBubbleColor: Color(0xFF3A2840),
    userBubbleTextColor: Color(0xFFEDE0E8),
    assistantBubbleColor: Color(0xFF261C2E),
    assistantBubbleTextColor: Color(0xFFEDE0E8),
    conversationListBackground: Color(0xFF160E1C),
    dialogBackground: Color(0xFF1C1420),
    backgroundGradient: [
      Color(0xFF2A162A),
      Color(0xFF1E1430),
      Color(0xFF141828),
    ],
  ),
);

/// All built-in themes.
const builtInThemes = [defaultTheme, messengerTheme];
