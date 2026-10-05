import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import 'package:lm_mini/utils/openai_compatible_params.dart';

void main() {
  group('openAiUsesMaxCompletionTokens', () {
    test('OpenAI provider always uses max_completion_tokens', () {
      expect(
        openAiUsesMaxCompletionTokens(
          modelId: 'gpt-4o',
          providerType: CloudApiType.openai,
        ),
        isTrue,
      );
    });

    test('GPT-5 family requires max_completion_tokens', () {
      expect(openAiUsesMaxCompletionTokens(modelId: 'gpt-5.6'), isTrue);
      expect(openAiUsesMaxCompletionTokens(modelId: 'gpt-5-mini'), isTrue);
      expect(
        openAiUsesMaxCompletionTokens(modelId: 'openai/gpt-5.6'),
        isTrue,
      );
    });

    test('o-series requires max_completion_tokens', () {
      expect(openAiUsesMaxCompletionTokens(modelId: 'o3-mini'), isTrue);
      expect(openAiUsesMaxCompletionTokens(modelId: 'o4-mini'), isTrue);
    });

    test('classic models keep max_tokens on non-OpenAI providers', () {
      expect(
        openAiUsesMaxCompletionTokens(
          modelId: 'gpt-4o',
          providerType: CloudApiType.openRouter,
        ),
        isFalse,
      );
      expect(
        openAiUsesMaxCompletionTokens(
          modelId: 'mistral-large-latest',
          providerType: CloudApiType.mistral,
        ),
        isFalse,
      );
    });
  });

  group('openAiOmitsSamplingParams', () {
    test('omits for GPT-5 reasoning models and o-series', () {
      expect(openAiOmitsSamplingParams('gpt-5.6'), isTrue);
      expect(openAiOmitsSamplingParams('gpt-5-mini'), isTrue);
      expect(openAiOmitsSamplingParams('o3-mini'), isTrue);
    });

    test('keeps sampling for gpt-5-chat and classic models', () {
      expect(openAiOmitsSamplingParams('gpt-5-chat-latest'), isFalse);
      expect(openAiOmitsSamplingParams('gpt-4o'), isFalse);
      expect(openAiOmitsSamplingParams('gpt-4.1'), isFalse);
    });
  });

  group('openAiMaxTokensFields', () {
    test('emits max_completion_tokens for GPT-5', () {
      expect(
        openAiMaxTokensFields(maxTokens: 2048, modelId: 'gpt-5.6'),
        {'max_completion_tokens': 2048},
      );
    });

    test('emits max_tokens for classic models', () {
      expect(
        openAiMaxTokensFields(
          maxTokens: 1024,
          modelId: 'gpt-4o',
          providerType: CloudApiType.openRouter,
        ),
        {'max_tokens': 1024},
      );
    });
  });

  group('verbosity and provider helpers', () {
    test('verbosity for OpenAI GPT-5', () {
      expect(
        openAiVerbosityApiValue(
          verbosity: 'low',
          modelId: 'gpt-5.6',
          providerType: CloudApiType.openai,
        ),
        'low',
      );
      expect(
        openAiVerbosityApiValue(
          verbosity: 'high',
          modelId: 'gpt-4o',
          providerType: CloudApiType.openai,
        ),
        isNull,
      );
    });

    test('Z.AI thinking fields', () {
      expect(
        zAiThinkingFields(
          reasoningEnabled: true,
          providerType: CloudApiType.zAi,
        ),
        {
          'thinking': {'type': 'enabled'},
        },
      );
      expect(
        zAiThinkingFields(
          reasoningEnabled: false,
          providerType: CloudApiType.openai,
        ),
        isNull,
      );
    });

    test('llama.cpp thinking kwargs for Qwen 3.6', () {
      const id =
          '/Users/me/.lmstudio/models/DavidAU/Qwen3.6-27B-Fable-Fusion.gguf';
      expect(
        llamaCppThinkingFields(reasoning: 'high', modelId: id),
        {
          'chat_template_kwargs': {'enable_thinking': true},
        },
      );
      expect(
        llamaCppThinkingFields(reasoning: 'off', modelId: id),
        {
          'chat_template_kwargs': {'enable_thinking': false},
          'reasoning_budget_tokens': 0,
        },
      );
      expect(
        llamaCppThinkingFields(
          reasoning: 'high',
          modelId: id,
          providerType: CloudApiType.openai,
        ),
        isEmpty,
      );
      expect(
        llamaCppThinkingFields(
          reasoning: 'high',
          modelId: 'llama-3.1-8b-instruct',
          providerType: CloudApiType.openaiCompatible,
        ),
        isEmpty,
      );
      expect(
        llamaCppThinkingFields(
          reasoning: 'on',
          modelId: 'default',
          providerType: CloudApiType.unsloth,
        ),
        {'enable_thinking': true},
      );
      expect(
        llamaCppThinkingFields(
          reasoning: 'off',
          modelId: 'unsloth/gemma-3-27b-it-GGUF',
          providerType: CloudApiType.unsloth,
        ),
        {'enable_thinking': false},
      );
    });

    test('Compatible + openai.com uses first-party OpenAI request type', () {
      expect(isHostedOpenAiBaseUrl('https://api.openai.com'), isTrue);
      expect(isHostedOpenAiBaseUrl('https://api.openai.com/v1'), isTrue);
      expect(isHostedOpenAiBaseUrl('api.openai.com'), isTrue);
      expect(isHostedOpenAiBaseUrl('https://openai.com'), isTrue);
      expect(isHostedOpenAiBaseUrl('https://www.openai.com'), isTrue);
      expect(isHostedOpenAiBaseUrl('https://platform.openai.com'), isFalse);
      expect(isHostedOpenAiBaseUrl('https://openrouter.ai/api'), isFalse);
      expect(
        isHostedOpenAiBaseUrl('https://eastus.openai.azure.com'),
        isFalse,
      );

      expect(
        effectiveChatApiType(
          CloudApiType.openaiCompatible,
          'https://api.openai.com',
        ),
        CloudApiType.openai,
      );
      expect(
        effectiveChatApiType(
          CloudApiType.openaiCompatible,
          'http://127.0.0.1:8080',
        ),
        CloudApiType.openaiCompatible,
      );
      expect(
        effectiveChatApiType(
          CloudApiType.openRouter,
          'https://api.openai.com',
        ),
        CloudApiType.openRouter,
      );

      final hosted = CloudApiProvider(
        id: 't',
        name: 'Custom',
        type: CloudApiType.openaiCompatible,
        apiKey: 'sk-test',
        baseUrl: 'https://openai.com',
      );
      expect(hosted.effectiveBaseUrl, 'https://api.openai.com');
      expect(hosted.requestApiType, CloudApiType.openai);
    });

    test('new providers expose OpenAI-compatible URLs', () {
      expect(CloudApiType.zAi.defaultBaseUrl, contains('api.z.ai'));
      expect(CloudApiType.zAi.chatPath, '/chat/completions');
      expect(CloudApiType.vercelAiGateway.chatPath, '/v1/chat/completions');
      expect(CloudApiType.gemini.displayName, 'Google AI Studio');
      expect(CloudApiType.openRouter.supportsReasoningEffort, isTrue);
    });
  });

  group('openAiResponseFormat', () {
    test('omits the field when Structured output is off', () {
      expect(
        openAiResponseFormat(useStructuredOutput: false),
        isNull,
      );
      expect(
        openAiResponseFormat(
          useStructuredOutput: false,
          providerType: CloudApiType.openai,
        ),
        isNull,
      );
    });

    test('local LM Studio uses json_schema, not json_object', () {
      final format = openAiResponseFormat(useStructuredOutput: true);
      expect(format, isNotNull);
      expect(format!['type'], 'json_schema');
      expect(format.containsKey('json_schema'), isTrue);
    });

    test('hosted OpenAI keeps json_object', () {
      expect(
        openAiResponseFormat(
          useStructuredOutput: true,
          providerType: CloudApiType.openai,
        ),
        {'type': 'json_object'},
      );
      expect(
        openAiResponseFormat(
          useStructuredOutput: true,
          providerType: CloudApiType.openRouter,
        ),
        {'type': 'json_object'},
      );
    });
  });
}
