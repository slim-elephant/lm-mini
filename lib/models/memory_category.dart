import 'package:flutter/material.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

import '../l10n/app_localizations.dart';

/// Canonical memory categories.
///
/// This list is the single source of truth. It must stay in step with the
/// categories named in `MemoryService.extractionPrompt` — when they drifted
/// apart, facts the extractor produced (`lifestyle`, `emotional`) were saved
/// but had no filter chip and were silently dropped by every persona category
/// allow-list.
class MemoryCategories {
  const MemoryCategories._();

  static const String personal = 'personal';
  static const String preference = 'preference';
  static const String lifestyle = 'lifestyle';
  static const String emotional = 'emotional';
  static const String technical = 'technical';
  static const String work = 'work';
  static const String general = 'general';

  /// Sentinel used by filter UI only — never stored on an item.
  static const String allFilter = 'all';

  /// Display / storage order.
  static const List<String> all = <String>[
    personal,
    preference,
    lifestyle,
    emotional,
    technical,
    work,
    general,
  ];

  /// Category used when a model invents one we don't know.
  static const String fallback = general;

  static bool isKnown(String? raw) =>
      raw != null && all.contains(raw.toLowerCase().trim());

  /// Coerce arbitrary model output into a known category.
  ///
  /// Applied on every write path so an off-list value degrades to
  /// [fallback] instead of becoming invisible to filters and allow-lists.
  static String normalize(String? raw) {
    final value = raw?.toLowerCase().trim();
    if (value == null || value.isEmpty) return fallback;
    if (all.contains(value)) return value;
    // Tolerate the most common near-misses from smaller models.
    switch (value) {
      case 'preferences':
      case 'prefs':
        return preference;
      case 'personal_info':
      case 'identity':
        return personal;
      case 'health':
      case 'diet':
      case 'fitness':
        return lifestyle;
      case 'emotion':
      case 'feelings':
      case 'mood':
        return emotional;
      case 'tech':
      case 'development':
      case 'dev':
        return technical;
      case 'job':
      case 'career':
      case 'business':
        return work;
      default:
        return fallback;
    }
  }
}

IconData memoryCategoryIcon(String category) {
  switch (category) {
    case MemoryCategories.personal:
      return Icons.person_outline_rounded;
    case MemoryCategories.preference:
      return Icons.favorite_outline_rounded;
    case MemoryCategories.lifestyle:
      return Icons.self_improvement_rounded;
    case MemoryCategories.emotional:
      return Icons.mood_rounded;
    case MemoryCategories.technical:
      return Icons.build_outlined;
    case MemoryCategories.work:
      return Icons.work_outline_rounded;
    case MemoryCategories.general:
    default:
      return Icons.lightbulb_outline_rounded;
  }
}

Color memoryCategoryColor(String category, ColorScheme cs) {
  switch (category) {
    case MemoryCategories.personal:
      return cs.primary;
    case MemoryCategories.preference:
      return cs.tertiary;
    case MemoryCategories.lifestyle:
      return const Color(0xFF3E9AE0);
    case MemoryCategories.emotional:
      return const Color(0xFFD1618A);
    case MemoryCategories.technical:
      return const Color(0xFFE09A3E);
    case MemoryCategories.work:
      return const Color(0xFF2E9E6B);
    case MemoryCategories.general:
    default:
      return cs.secondary;
  }
}

String memoryCategoryLabel(String category, AppLocalizations l10n) {
  switch (category) {
    case MemoryCategories.allFilter:
      return l10n.categoryAll;
    case MemoryCategories.personal:
      return l10n.categoryPersonal;
    case MemoryCategories.preference:
      return l10n.categoryPreferences;
    case MemoryCategories.lifestyle:
      return l10n.categoryLifestyle;
    case MemoryCategories.emotional:
      return l10n.categoryEmotional;
    case MemoryCategories.technical:
      return l10n.categoryTechnical;
    case MemoryCategories.work:
      return l10n.categoryWork;
    case MemoryCategories.general:
      return l10n.categoryGeneral;
    default:
      return category.isEmpty
          ? l10n.categoryGeneral
          : category[0].toUpperCase() + category.substring(1);
  }
}

// ─── Scope presentation ────────────────────────────────────────────────

IconData memoryScopeIcon(MemoryScope scope) {
  switch (scope) {
    case MemoryScope.global:
      return Icons.public_rounded;
    case MemoryScope.private:
      return Icons.lock_outline_rounded;
    case MemoryScope.lore:
      return Icons.auto_stories_outlined;
  }
}

Color memoryScopeColor(MemoryScope scope, ColorScheme cs) {
  switch (scope) {
    case MemoryScope.global:
      return cs.secondary;
    case MemoryScope.private:
      return const Color(0xFF7C6BD6);
    case MemoryScope.lore:
      return const Color(0xFFC77B33);
  }
}

String memoryScopeLabel(MemoryScope scope, AppLocalizations l10n) {
  switch (scope) {
    case MemoryScope.global:
      return l10n.memoryScopeGlobal;
    case MemoryScope.private:
      return l10n.memoryScopePrivate;
    case MemoryScope.lore:
      return l10n.memoryScopeLore;
  }
}

String memoryScopeSubtitle(MemoryScope scope, AppLocalizations l10n) {
  switch (scope) {
    case MemoryScope.global:
      return l10n.memoryScopeGlobalSubtitle;
    case MemoryScope.private:
      return l10n.memoryScopePrivateSubtitle;
    case MemoryScope.lore:
      return l10n.memoryScopeLoreSubtitle;
  }
}
