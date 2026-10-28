import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/app_settings.dart';

void main() {
  test('prompt style is per image server and survives save/load', () {
    final s = AppSettings.fromJson({
      'serverUrl': 'http://localhost:1234',
      'imageGenProvider': 'comfyui',
      'imageGenPromptStyles': {'comfyui': 'natural sentences', 'a1111': ''},
    });
    expect(s.imageGenPromptStyle, 'natural sentences');
    expect(s.copyWith(imageGenProvider: 'a1111').imageGenPromptStyle, isNull);
    expect(s.copyWith(imageGenProvider: 'onDevice').imageGenPromptStyle, isNull);
    final back = AppSettings.fromJson(s.toJson());
    expect(back.imageGenPromptStyles['comfyui'], 'natural sentences');
    expect(AppSettings.fromJson({'serverUrl': 'x'}).imageGenPromptStyles, isEmpty);
  });
}
