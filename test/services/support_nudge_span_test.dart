import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/services/support_nudge_service.dart';

void main() {
  test('usage span uses singular and plural', () {
    expect(SupportNudgeService.usageSpan(1), '1 day');
    expect(SupportNudgeService.usageSpan(5), '5 days');
    expect(SupportNudgeService.usageSpan(7), '1 week');
    expect(SupportNudgeService.usageSpan(13), '1 week');
    expect(SupportNudgeService.usageSpan(14), '2 weeks');
    expect(SupportNudgeService.usageSpan(45), '1 month');
    expect(SupportNudgeService.usageSpan(400), '1 year');
  });

  test('headline names the same time as the card', () {
    expect(SupportNudgeService.dayHeadline(14), '👋 2 weeks with LM Mini!');
    expect(SupportNudgeService.dayHeadline(31), '🎉 1 month with LM Mini!');
  });
}
