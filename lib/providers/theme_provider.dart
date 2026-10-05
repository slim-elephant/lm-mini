import 'package:flutter/material.dart';
import '../models/app_theme.dart';
import '../services/theme_service.dart';

class ThemeProvider with ChangeNotifier {
  final ThemeService _service = ThemeService();

  String _selectedThemeId = 'default';
  AppTheme _currentTheme = defaultTheme;
  List<AppTheme> _downloadedThemes = [];
  List<AppTheme> _communityThemes = [];
  bool _isLoadingCommunity = false;
  final Set<String> _uploadedThemeIds = {};

  String get selectedThemeId => _selectedThemeId;
  AppTheme get currentTheme => _currentTheme;
  List<AppTheme> get downloadedThemes => _downloadedThemes;
  List<AppTheme> get communityThemes => _communityThemes;
  bool get isLoadingCommunity => _isLoadingCommunity;
  bool isThemeUploaded(String themeId) => _uploadedThemeIds.contains(themeId);

  /// All themes available locally (built-in + downloaded).
  List<AppTheme> get availableThemes => [
        ...builtInThemes,
        ..._downloadedThemes,
      ];

  /// Initialize: load saved selection + cached themes.
  Future<void> load(String? savedThemeId) async {
    // Load cached themes from disk
    final cachedIds = await _service.listCachedThemeIds();
    final cached = <AppTheme>[];
    for (final id in cachedIds) {
      final theme = await _service.loadCachedTheme(id);
      if (theme != null && !builtInThemes.any((b) => b.id == theme.id)) {
        cached.add(theme);
      }
    }
    _downloadedThemes = cached;

    // Resolve selected theme
    final id = savedThemeId ?? 'default';
    _selectedThemeId = id;
    _currentTheme = _resolveTheme(id);
    notifyListeners();
  }

  /// Select a theme by ID.
  void selectTheme(String themeId) {
    _selectedThemeId = themeId;
    _currentTheme = _resolveTheme(themeId);
    notifyListeners();
  }

  /// Build ThemeData for the current theme.
  ThemeData buildThemeData(Brightness brightness) {
    return _currentTheme.toThemeData(brightness);
  }

  /// Fetch community themes from Firebase.
  Future<void> fetchCommunityThemes() async {
    _isLoadingCommunity = true;
    notifyListeners();

    _communityThemes = await _service.fetchCommunityThemes();

    _isLoadingCommunity = false;
    notifyListeners();
  }

  /// Download and install a community theme.
  Future<bool> downloadAndInstallTheme(String themeId) async {
    final theme = await _service.downloadTheme(themeId);
    if (theme == null) return false;

    // Add to downloaded list if not already there
    _downloadedThemes.removeWhere((t) => t.id == themeId);
    _downloadedThemes.add(theme);
    if (_selectedThemeId == theme.id) {
      _currentTheme = theme;
    }
    notifyListeners();
    return true;
  }

  /// Upload a theme to community.
  Future<bool> uploadTheme(AppTheme theme) async {
    final ok = await _service.uploadTheme(theme);
    if (ok) {
      _uploadedThemeIds.add(theme.id);
      notifyListeners();
    }
    return ok;
  }

  /// Remove a downloaded theme.
  Future<void> removeDownloadedTheme(String themeId) async {
    await _service.deleteCachedTheme(themeId);
    _downloadedThemes.removeWhere((t) => t.id == themeId);
    if (_selectedThemeId == themeId) {
      selectTheme('default');
    }
    notifyListeners();
  }

  /// Add a locally-created custom theme.
  Future<void> addCustomTheme(AppTheme theme) async {
    await _service.cacheTheme(theme);
    _downloadedThemes.removeWhere((t) => t.id == theme.id);
    _downloadedThemes.add(theme);
    if (_selectedThemeId == theme.id) {
      _currentTheme = theme;
    }
    // Mark as needing re-upload if it was previously uploaded
    _uploadedThemeIds.remove(theme.id);
    notifyListeners();
  }

  AppTheme _resolveTheme(String id) {
    return availableThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => defaultTheme,
    );
  }
}
