import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/app_settings.dart';
import 'package:lm_mini/services/builtin_persona_service.dart';

void main() {
  test('Default persona is empty with no preferences', () {
    final persona = BuiltinPersonaService.buildDefault(now: DateTime(2026));
    expect(persona.id, BuiltinPersonaService.defaultPersonaId);
    expect(persona.name, 'Default');
    expect(persona.content, isEmpty);
    expect(persona.isPersona, isFalse);
    expect(persona.avatarPath, isNull);
    expect(persona.color, isNull);
    expect(persona.defaultModelId, isNull);
    expect(persona.defaultProviderKind, isNull);
    expect(persona.kokoroSpeakerId, isNull);
    expect(persona.kokoroSpeed, isNull);
    expect(persona.boundModelIds, isNull);
    expect(persona.imageGenSeed, isNull);
  });

  test('null selection is treated as Default', () {
    expect(BuiltinPersonaService.isDefaultId(null), isTrue);
    expect(
      BuiltinPersonaService.isDefaultId(BuiltinPersonaService.defaultPersonaId),
      isTrue,
    );
    expect(
      BuiltinPersonaService.isDefaultId(BuiltinPersonaService.personaId),
      isFalse,
    );
  });

  test('new settings default to an empty system prompt', () {
    expect(AppSettings().systemPrompt, isEmpty);
    expect(
      AppSettings.fromJson({'serverUrl': 'http://localhost:1234'}).systemPrompt,
      isEmpty,
    );
  });
}
