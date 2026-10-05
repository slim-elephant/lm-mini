import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/app_settings.dart';
import 'package:lm_mini/models/system_prompt.dart';
import 'package:lm_mini/services/builtin_persona_service.dart';
import 'package:lm_mini/utils/persona_appearance.dart';

void main() {
  final persona = SystemPrompt(
    id: 'sp_1',
    name: 'Wizard',
    content: 'You are a wizard.',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    avatarPath: 'images/wizard.png',
    color: 0xFFAA00FF,
  );

  AppSettings settingsWithPersona() => AppSettings(
        selectedSystemPromptId: 'sp_1',
        savedSystemPrompts: [persona],
      );

  test('uses global selected persona', () {
    final look = PersonaAppearance.resolve(settings: settingsWithPersona());
    expect(look?.avatarPath, 'images/wizard.png');
    expect(look?.color, 0xFFAA00FF);
  });

  test('uses chat systemPromptId over global', () {
    final other = SystemPrompt(
      id: 'sp_2',
      name: 'Robot',
      content: 'Beep',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      avatarPath: 'images/robot.png',
      color: 0xFF00FF00,
    );
    final settings = AppSettings(
      selectedSystemPromptId: 'sp_1',
      savedSystemPrompts: [persona, other],
    );
    final look = PersonaAppearance.resolve(
      settings: settings,
      conversationSettings: {'systemPromptId': 'sp_2'},
    );
    expect(look?.avatarPath, 'images/robot.png');
    expect(look?.color, 0xFF00FF00);
  });

  test('custom chat prompt has no persona look', () {
    final look = PersonaAppearance.resolve(
      settings: settingsWithPersona(),
      conversationSettings: {'systemPrompt': 'Custom text only'},
    );
    expect(look, isNull);
  });

  test('parseColor accepts num', () {
    expect(PersonaAppearance.parseColor(0xFF112233), 0xFF112233);
    expect(PersonaAppearance.parseColor(4279386675.0), 4279386675);
  });

  test('built-in Default is not treated as a named persona', () {
    final def = BuiltinPersonaService.buildDefault(now: DateTime(2026));
    final settings = AppSettings(
      selectedSystemPromptId: BuiltinPersonaService.defaultPersonaId,
      savedSystemPrompts: [def],
    );
    expect(PersonaAppearance.resolve(settings: settings), isNull);
    expect(PersonaAppearance.boundPersona(settings: settings), isNull);
    expect(
      PersonaAppearance.boundPersona(
        settings: settings,
        conversationSettings: {
          'systemPromptId': BuiltinPersonaService.defaultPersonaId,
        },
      ),
      isNull,
    );
  });
}
