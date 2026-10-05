import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/services/call_service.dart';

void main() {
  group('CallService.mainlandChinaFromLocales', () {
    test('hides CallKit for mainland China region', () {
      expect(
        CallService.mainlandChinaFromLocales(
          const [Locale('zh', 'CN')],
          'zh_CN',
        ),
        isTrue,
      );
      expect(
        CallService.mainlandChinaFromLocales(
          const [Locale('en', 'CN')],
          'en_CN',
        ),
        isTrue,
      );
    });

    test('keeps CallKit for Taiwan, Hong Kong, and language-only Chinese', () {
      expect(
        CallService.mainlandChinaFromLocales(
          const [Locale('zh', 'TW')],
          'zh_TW',
        ),
        isFalse,
      );
      expect(
        CallService.mainlandChinaFromLocales(
          const [Locale('zh', 'HK')],
          'zh_HK',
        ),
        isFalse,
      );
      expect(
        CallService.mainlandChinaFromLocales(const [Locale('zh')], 'zh'),
        isFalse,
      );
      expect(
        CallService.mainlandChinaFromLocales(
          const [Locale('zh', 'Hans')],
          'zh_Hans',
        ),
        isFalse,
      );
    });
  });
}
