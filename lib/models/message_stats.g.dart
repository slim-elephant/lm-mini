// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageStats _$MessageStatsFromJson(Map<String, dynamic> json) => MessageStats(
      tokensPerSecond: (json['tokens_per_second'] as num?)?.toDouble(),
      timeToFirstToken: (json['time_to_first_token'] as num?)?.toDouble(),
      timeToFirstTokenSeconds:
          (json['time_to_first_token_seconds'] as num?)?.toDouble(),
      generationTime: (json['generation_time'] as num?)?.toDouble(),
      stopReason: json['stop_reason'] as String?,
      inputTokens: (json['input_tokens'] as num?)?.toInt(),
      totalOutputTokens: (json['total_output_tokens'] as num?)?.toInt(),
      reasoningOutputTokens: (json['reasoning_output_tokens'] as num?)?.toInt(),
      modelLoadTimeSeconds:
          (json['model_load_time_seconds'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$MessageStatsToJson(MessageStats instance) =>
    <String, dynamic>{
      'tokens_per_second': instance.tokensPerSecond,
      'time_to_first_token': instance.timeToFirstToken,
      'time_to_first_token_seconds': instance.timeToFirstTokenSeconds,
      'generation_time': instance.generationTime,
      'stop_reason': instance.stopReason,
      'input_tokens': instance.inputTokens,
      'total_output_tokens': instance.totalOutputTokens,
      'reasoning_output_tokens': instance.reasoningOutputTokens,
      'model_load_time_seconds': instance.modelLoadTimeSeconds,
    };

ModelInfo _$ModelInfoFromJson(Map<String, dynamic> json) => ModelInfo(
      arch: json['arch'] as String?,
      quant: json['quant'] as String?,
      format: json['format'] as String?,
      contextLength: (json['context_length'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ModelInfoToJson(ModelInfo instance) => <String, dynamic>{
      'arch': instance.arch,
      'quant': instance.quant,
      'format': instance.format,
      'context_length': instance.contextLength,
    };

RuntimeInfo _$RuntimeInfoFromJson(Map<String, dynamic> json) => RuntimeInfo(
      name: json['name'] as String?,
      version: json['version'] as String?,
      supportedFormats: (json['supported_formats'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$RuntimeInfoToJson(RuntimeInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': instance.version,
      'supported_formats': instance.supportedFormats,
    };

TokenUsage _$TokenUsageFromJson(Map<String, dynamic> json) => TokenUsage(
      promptTokens: (json['prompt_tokens'] as num).toInt(),
      completionTokens: (json['completion_tokens'] as num).toInt(),
      totalTokens: (json['total_tokens'] as num).toInt(),
    );

Map<String, dynamic> _$TokenUsageToJson(TokenUsage instance) =>
    <String, dynamic>{
      'prompt_tokens': instance.promptTokens,
      'completion_tokens': instance.completionTokens,
      'total_tokens': instance.totalTokens,
    };
