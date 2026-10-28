import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/app_settings.dart';
import 'package:lm_mini/utils/about_user_prompt.dart';
import 'package:lm_mini/utils/chat_message_normalizer.dart';

void main() {
  test('no block when neither name nor description is set', () {
    expect(aboutUserPromptBlock(), isNull);
    expect(aboutUserPromptBlock(name: '  ', about: '\n'), isNull);
  });

  test('block carries the name and description', () {
    final block = aboutUserPromptBlock(
      name: ' Sam ',
      about: 'Nurse on night shifts. Short answers, please.',
    )!;
    expect(block, startsWith('--- About the user ---'));
    expect(block, contains('Name: Sam'));
    expect(block, contains('Short answers, please.'));
    expect(aboutUserPromptBlock(about: 'Likes chess')!, isNot(contains('Name:')));
  });

  test('overlong description is cut to the limit', () {
    final block = aboutUserPromptBlock(about: 'a' * (kAboutUserMaxLength + 50))!;
    expect(block.split('\n').last.length, kAboutUserMaxLength);
  });

  test('block lands in the leading system message', () {
    final out = ChatMessageNormalizer.injectMemoryContext([
      {'role': 'system', 'content': 'You are helpful.'},
      {'role': 'user', 'content': 'Hi'},
    ], aboutUserPromptBlock(name: 'Sam'));
    expect(out.first['content'], startsWith('You are helpful.'));
    expect(out.first['content'], contains('Name: Sam'));
    expect(out.where((m) => m['role'] == 'system'), hasLength(1));
  });

  test('about you survives save and load', () {
    final s = AppSettings.fromJson({'serverUrl': 'x'})
        .copyWith(aboutUser: 'Likes chess');
    expect(AppSettings.fromJson(s.toJson()).aboutUser, 'Likes chess');
    expect(AppSettings.fromJson({'serverUrl': 'x'}).aboutUser, isNull);
    expect(s.copyWith(aboutUser: null).aboutUser, isNull);
  });
}
