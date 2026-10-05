import 'package:lm_mini_premium/lm_mini_premium.dart';

import '../models/arena_models.dart';

/// Helpers for shaping OpenAI Chat Completions bodies for current models
/// (GPT-5 / o-series reject deprecated `max_tokens` and often reject
/// non-default sampling params).

/// Strips provider prefixes (`openai/gpt-5.6` → `gpt-5.6`).
String bareOpenAiModelId(String? modelId) {
  final id = (modelId ?? '').trim().toLowerCase();
  if (id.isEmpty) return '';
  final slash = id.lastIndexOf('/');
  return slash >= 0 ? id.substring(slash + 1) : id;
}

/// GPT-5 family or o-series (o1 / o3 / o4 / …), including OpenRouter-style ids.
bool isOpenAiGpt5OrOSeries(String? modelId) {
  final bare = bareOpenAiModelId(modelId);
  if (bare.isEmpty) return false;
  if (bare.startsWith('gpt-5')) return true;
  // o1, o1-mini, o3, o3-mini, o4-mini, …
  if (RegExp(r'^o[1-9]([\.-]|$)').hasMatch(bare)) return true;
  return false;
}

/// Whether Chat Completions must use `max_completion_tokens` instead of
/// deprecated `max_tokens`.
///
/// - Direct OpenAI provider: always (current API prefers this key).
/// - Other providers: only when the model id looks like GPT-5 / o-series
///   (e.g. OpenRouter `openai/gpt-5.6`), which reject `max_tokens`.
bool openAiUsesMaxCompletionTokens({
  String? modelId,
  CloudApiType? providerType,
}) {
  if (providerType == CloudApiType.openai) return true;
  return isOpenAiGpt5OrOSeries(modelId);
}

/// Whether to omit temperature / top_p / frequency_penalty / presence_penalty.
///
/// GPT-5 reasoning models and o-series reject non-default sampling values.
/// `gpt-5-chat*` still accepts sampling and is excluded.
bool openAiOmitsSamplingParams(String? modelId) {
  final bare = bareOpenAiModelId(modelId);
  if (bare.isEmpty) return false;
  if (bare.startsWith('gpt-5-chat')) return false;
  if (bare.startsWith('gpt-5')) return true;
  if (RegExp(r'^o[1-9]([\.-]|$)').hasMatch(bare)) return true;
  return false;
}

/// Maps app reasoning setting to OpenAI Chat Completions `reasoning_effort`.
/// Returns null when the param should be omitted.
String? openAiReasoningEffortApiValue({
  required String reasoning,
  String? modelId,
  CloudApiType? providerType,
}) {
  final providerSupports = providerType?.supportsReasoningEffort == true;
  final modelLooksReasoning = isOpenAiGpt5OrOSeries(modelId);
  // Direct OpenAI / gateways: only send for GPT-5 / o-series style models.
  // DeepSeek: send whenever reasoning isn't off (model pick is deepseek-reasoner).
  if (providerType == CloudApiType.deepSeek) {
    if (reasoning == 'off') return null;
    switch (reasoning) {
      case 'low':
        return 'low';
      case 'high':
        return 'high';
      case 'on':
      case 'medium':
      default:
        return 'medium';
    }
  }
  if (!providerSupports && !modelLooksReasoning) return null;
  if (!isOpenAiGpt5OrOSeries(modelId)) return null;
  // gpt-5-chat is not a reasoning-effort model in practice.
  if (bareOpenAiModelId(modelId).startsWith('gpt-5-chat')) return null;
  switch (reasoning) {
    case 'off':
      return 'none';
    case 'low':
      return 'low';
    case 'medium':
      return 'medium';
    case 'high':
      return 'high';
    case 'on':
      return 'medium';
    default:
      return null;
  }
}

/// OpenAI GPT-5 `verbosity` when the provider supports it.
String? openAiVerbosityApiValue({
  required String verbosity,
  String? modelId,
  CloudApiType? providerType,
}) {
  if (providerType?.supportsVerbosity != true) return null;
  // Verbosity applies to GPT-5 family (including chat variants).
  final bare = bareOpenAiModelId(modelId);
  if (!bare.startsWith('gpt-5') && providerType != CloudApiType.openai) {
    // On gateways only attach for gpt-5* model ids.
    return null;
  }
  if (providerType == CloudApiType.openai &&
      bare.isNotEmpty &&
      !bare.startsWith('gpt-5')) {
    return null;
  }
  switch (verbosity) {
    case 'low':
    case 'medium':
    case 'high':
      return verbosity;
    default:
      return null;
  }
}

/// Z.AI thinking payload when reasoning is enabled for that provider.
Map<String, dynamic>? zAiThinkingFields({
  required bool reasoningEnabled,
  CloudApiType? providerType,
}) {
  if (providerType?.supportsZAiThinking != true) return null;
  return {
    'thinking': {'type': reasoningEnabled ? 'enabled' : 'disabled'},
  };
}

/// llama.cpp / vLLM OpenAI-compat thinking controls (`enable_thinking`).
///
/// Used on `/v1/chat/completions` for llama-server and other local OpenAI
/// backends. Not sent to hosted OpenAI / OpenRouter / DeepSeek (those use
/// `reasoning_effort` or provider-specific fields).
Map<String, dynamic> llamaCppThinkingFields({
  required String reasoning,
  required String modelId,
  CloudApiType? providerType,
}) {
  final enabled = reasoning != 'off' && reasoning != 'false';
  if (providerType == CloudApiType.unsloth) {
    return {'enable_thinking': enabled};
  }
  if (providerType != null && providerType != CloudApiType.openaiCompatible) {
    return const {};
  }
  if (!ArenaContestant.looksLikeReasoningModel(modelId)) {
    return const {};
  }
  return {
    'chat_template_kwargs': {'enable_thinking': enabled},
    // Older llama.cpp honours the template kwarg; newer builds prefer a
    // token budget of 0 to force thinking off.
    if (!enabled) 'reasoning_budget_tokens': 0,
  };
}

/// Chat Completions `response_format` when Structured output is on.
///
/// Current LM Studio only accepts `json_schema` or `text`. Sending
/// `json_object` (OpenAI JSON mode) returns HTTP 400 and used to kick us
/// off V1 onto a failing V0 retry. Hosted OpenAI / OpenRouter still want
/// `json_object`.
Map<String, dynamic>? openAiResponseFormat({
  required bool useStructuredOutput,
  CloudApiType? providerType,
}) {
  if (!useStructuredOutput) return null;
  if (providerType == null) {
    return {
      'type': 'json_schema',
      'json_schema': {
        'name': 'json_object',
        'schema': {
          'type': 'object',
          'additionalProperties': true,
        },
      },
    };
  }
  return {'type': 'json_object'};
}

/// Builds the max-token field for a Chat Completions request body.
Map<String, dynamic> openAiMaxTokensFields({
  required int maxTokens,
  String? modelId,
  CloudApiType? providerType,
}) {
  if (openAiUsesMaxCompletionTokens(
    modelId: modelId,
    providerType: providerType,
  )) {
    return {'max_completion_tokens': maxTokens};
  }
  return {'max_tokens': maxTokens};
}
