import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/utils/group_participant_backend.dart';

void main() {
  test('stored kind wins over later global Settings', () {
    expect(
      GroupParticipantBackend.resolve(
        storedKind: 'lmStudio',
        globalKind: 'onDeviceGguf',
        modelId: 'local-qwen',
        isLocalGguf: (_) => true,
      ),
      'lmStudio',
    );
  });

  test('persona default fills a missing stored kind', () {
    expect(
      GroupParticipantBackend.resolve(
        personaKind: 'lmStudio',
        globalKind: 'onDeviceGguf',
        modelId: 'qwen-27b',
      ),
      'lmStudio',
    );
  });

  test('infers on-device from model id instead of global LM Studio', () {
    expect(
      GroupParticipantBackend.resolve(
        globalKind: 'lmStudio',
        modelId: 'qwen3-4b',
        isLocalGguf: (id) => id == 'qwen3-4b',
        isLmStudioModel: (_) => true,
      ),
      'onDeviceGguf',
    );
  });

  test('infers LM Studio from model id instead of global llama.cpp', () {
    expect(
      GroupParticipantBackend.resolve(
        globalKind: 'onDeviceGguf',
        modelId: 'Qwen3.6-27B-NEO-CODE',
        isLocalGguf: (_) => false,
        isLmStudioModel: (id) => id.contains('Qwen3.6'),
      ),
      'lmStudio',
    );
  });

  test('cloud provider id is stronger than global', () {
    expect(
      GroupParticipantBackend.resolve(
        cloudProviderKind: 'ollama',
        globalKind: 'onDeviceGguf',
        modelId: 'llama3.2',
      ),
      'ollama',
    );
  });

  test('unknown stored kind is ignored in favor of persona', () {
    expect(
      GroupParticipantBackend.resolve(
        storedKind: 'legacyFoo',
        personaKind: 'lmStudio',
        globalKind: 'onDeviceGguf',
      ),
      'lmStudio',
    );
  });
}
