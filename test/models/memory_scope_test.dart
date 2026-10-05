import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:lm_mini/models/memory_category.dart';
import 'package:lm_mini/models/system_prompt.dart';

void main() {
  group('MemoryCategories.normalize', () {
    test('passes through every canonical category', () {
      for (final cat in MemoryCategories.all) {
        expect(MemoryCategories.normalize(cat), cat);
      }
    });

    test('includes the categories the extraction prompt asks for', () {
      // These two used to be missing, so extracted facts were invisible to
      // filters and dropped by persona allow-lists.
      expect(MemoryCategories.all, contains('lifestyle'));
      expect(MemoryCategories.all, contains('emotional'));
    });

    test('is case and whitespace insensitive', () {
      expect(MemoryCategories.normalize('  Work '), 'work');
      expect(MemoryCategories.normalize('TECHNICAL'), 'technical');
    });

    test('maps common near-misses instead of discarding them', () {
      expect(MemoryCategories.normalize('preferences'), 'preference');
      expect(MemoryCategories.normalize('feelings'), 'emotional');
      expect(MemoryCategories.normalize('career'), 'work');
      expect(MemoryCategories.normalize('diet'), 'lifestyle');
    });

    test('degrades unknown and empty values to general', () {
      expect(MemoryCategories.normalize('astrology'), 'general');
      expect(MemoryCategories.normalize(''), 'general');
      expect(MemoryCategories.normalize(null), 'general');
    });
  });

  group('memoryScopeFromWire', () {
    test('parses known scopes', () {
      expect(memoryScopeFromWire('global'), MemoryScope.global);
      expect(memoryScopeFromWire('private'), MemoryScope.private);
      expect(memoryScopeFromWire('lore'), MemoryScope.lore);
    });

    test('falls back to global for v1 rows and unknown values', () {
      expect(memoryScopeFromWire(null), MemoryScope.global);
      expect(memoryScopeFromWire(''), MemoryScope.global);
      expect(memoryScopeFromWire('nonsense'), MemoryScope.global);
    });
  });

  group('SystemPrompt.memoryWriteScope', () {
    SystemPrompt makePrompt({MemoryScope? scope}) {
      final now = DateTime.utc(2026, 1, 1);
      return SystemPrompt(
        id: 'sp_1',
        name: 'Kaida',
        content: 'You are Kaida.',
        createdAt: now,
        updatedAt: now,
        memoryWriteScope: scope ?? MemoryScope.global,
      );
    }

    test('defaults to global', () {
      expect(makePrompt().memoryWriteScope, MemoryScope.global);
    });

    test('survives a JSON round trip', () {
      for (final scope in MemoryScope.values) {
        final restored =
            SystemPrompt.fromJson(makePrompt(scope: scope).toJson());
        expect(restored.memoryWriteScope, scope);
      }
    });

    test('reads personas saved before the field existed as global', () {
      final json = makePrompt().toJson()..remove('memoryWriteScope');
      expect(SystemPrompt.fromJson(json).memoryWriteScope, MemoryScope.global);
    });

    test('copyWith updates and preserves the scope', () {
      final lore = makePrompt().copyWith(memoryWriteScope: MemoryScope.lore);
      expect(lore.memoryWriteScope, MemoryScope.lore);
      expect(lore.copyWith(name: 'Renamed').memoryWriteScope, MemoryScope.lore);
    });
  });
}
