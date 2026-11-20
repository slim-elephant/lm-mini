import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/app_settings.dart';
import 'package:lm_mini/models/param_preset.dart';
import 'package:lm_mini/utils/lm_studio_session.dart';
import 'package:lm_mini/utils/response_parser.dart';
import 'package:lm_mini/widgets/model_parameters_form.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

void main() {
  group('LmStudioSession.continuableResponseId', () {
    test('LM Studio keeps its stored session by default', () {
      expect(
        LmStudioSession.continuableResponseId(
          'resp_1',
          providerKind: 'lmStudio',
          keepThinkingInContext: true,
        ),
        'resp_1',
      );
    });

    test('LM Studio with the switch off sends history instead', () {
      expect(
        LmStudioSession.continuableResponseId(
          'resp_1',
          providerKind: 'lmStudio',
          keepThinkingInContext: false,
        ),
        isNull,
      );
    });

    test('other backends ignore the switch', () {
      for (final kind in ['lmMiniDesktop', 'cloud', 'onDeviceGguf', '']) {
        expect(
          LmStudioSession.continuableResponseId(
            'resp_1',
            providerKind: kind,
            keepThinkingInContext: false,
          ),
          'resp_1',
          reason: kind,
        );
      }
    });

    test('no stored session stays null', () {
      expect(
        LmStudioSession.continuableResponseId(
          null,
          providerKind: 'lmStudio',
          keepThinkingInContext: true,
        ),
        isNull,
      );
    });
  });

  group('keepThinkingInContext setting', () {
    test('defaults on, including settings saved before it existed', () {
      expect(AppSettings().keepThinkingInContext, isTrue);
      expect(
        AppSettings.fromJson({'serverUrl': 'x'}).keepThinkingInContext,
        isTrue,
      );
      expect(ParamPreset.fromJson({}).keepThinkingInContext, isTrue);
    });

    test('survives save and load', () {
      final off = AppSettings().copyWith(keepThinkingInContext: false);
      expect(AppSettings.fromJson(off.toJson()).keepThinkingInContext, isFalse);

      final preset = ParamPreset.fromSettings(off);
      expect(preset.keepThinkingInContext, isFalse);
      expect(
        ParamPreset.fromJson(preset.toJson()).keepThinkingInContext,
        isFalse,
      );
    });

    test('presets apply it and compare by it', () {
      final preset = ParamPreset.fromSettings(AppSettings())
          .copyWith(keepThinkingInContext: false);
      expect(preset.applyTo(AppSettings()).keepThinkingInContext, isFalse);
      expect(preset == ParamPreset.fromSettings(AppSettings()), isFalse);
      expect(
        preset.copyWith(keepThinkingInContext: true),
        ParamPreset.fromSettings(AppSettings()),
      );
    });

    test('copyWith leaves it alone when not given', () {
      final off = AppSettings().copyWith(keepThinkingInContext: false);
      expect(off.copyWith(temperature: 0.1).keepThinkingInContext, isFalse);
    });
  });

  group('switch visibility', () {
    test('shown for LM Studio only', () {
      expect(
        ModelParametersVisibility.resolve(
          providerKind: 'lmStudio',
          isCloudRouted: false,
        ).showKeepThinking,
        isTrue,
      );
      expect(
        ModelParametersVisibility.resolve(
          providerKind: 'lmMiniDesktop',
          isCloudRouted: false,
        ).showKeepThinking,
        isFalse,
      );
      expect(
        ModelParametersVisibility.resolve(
          providerKind: 'onDeviceGguf',
          isCloudRouted: false,
        ).showKeepThinking,
        isFalse,
      );
      expect(
        ModelParametersVisibility.resolve(
          providerKind: 'cloud',
          providerType: CloudApiType.ollama,
          isCloudRouted: true,
        ).showKeepThinking,
        isFalse,
      );
    });
  });

  group('history the app sends instead', () {
    test('answer-only strips thinking in the formats LM Mini stores', () {
      expect(
        ResponseParser.answerOnly('<think>long thoughts</think>\n\n391').trim(),
        '391',
      );
      expect(ResponseParser.answerOnly('391').trim(), '391');
    });
  });
}
