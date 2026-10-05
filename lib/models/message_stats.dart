import 'package:json_annotation/json_annotation.dart';

part 'message_stats.g.dart';

/// Performance statistics for a message generation
@JsonSerializable()
class MessageStats {
  @JsonKey(name: 'tokens_per_second')
  final double? tokensPerSecond;
  
  @JsonKey(name: 'time_to_first_token')
  final double? timeToFirstToken;
  
  @JsonKey(name: 'time_to_first_token_seconds')
  final double? timeToFirstTokenSeconds; // v1 API naming
  
  @JsonKey(name: 'generation_time')
  final double? generationTime;
  
  @JsonKey(name: 'stop_reason')
  final String? stopReason;
  
  // New v1 API stats fields
  @JsonKey(name: 'input_tokens')
  final int? inputTokens;
  
  @JsonKey(name: 'total_output_tokens')
  final int? totalOutputTokens;
  
  @JsonKey(name: 'reasoning_output_tokens')
  final int? reasoningOutputTokens;
  
  @JsonKey(name: 'model_load_time_seconds')
  final double? modelLoadTimeSeconds;

  MessageStats({
    this.tokensPerSecond,
    this.timeToFirstToken,
    this.timeToFirstTokenSeconds,
    this.generationTime,
    this.stopReason,
    this.inputTokens,
    this.totalOutputTokens,
    this.reasoningOutputTokens,
    this.modelLoadTimeSeconds,
  });

  factory MessageStats.fromJson(Map<String, dynamic> json) =>
      _$MessageStatsFromJson(json);

  Map<String, dynamic> toJson() => _$MessageStatsToJson(this);

  String get formattedTokensPerSecond =>
      tokensPerSecond != null ? '${tokensPerSecond!.toStringAsFixed(1)} t/s' : 'N/A';

  String get formattedTTFT {
    if (timeToFirstTokenSeconds != null) {
      return '${(timeToFirstTokenSeconds! * 1000).toStringAsFixed(0)} ms';
    }
    if (timeToFirstToken != null) {
      return '${(timeToFirstToken! * 1000).toStringAsFixed(0)} ms';
    }
    return 'N/A';
  }

  String get formattedGenerationTime =>
      generationTime != null ? '${generationTime!.toStringAsFixed(2)} s' : 'N/A';
  
  int? get totalTokens {
    if (inputTokens != null && totalOutputTokens != null) {
      return inputTokens! + totalOutputTokens!;
    }
    return null;
  }
}

/// Model information returned by LM Studio
@JsonSerializable()
class ModelInfo {
  final String? arch;
  final String? quant;
  final String? format;
  
  @JsonKey(name: 'context_length')
  final int? contextLength;

  ModelInfo({
    this.arch,
    this.quant,
    this.format,
    this.contextLength,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) =>
      _$ModelInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ModelInfoToJson(this);

  String get displayInfo {
    final parts = <String>[];
    if (arch != null) parts.add(arch!);
    if (quant != null) parts.add(quant!);
    if (format != null) parts.add(format!);
    return parts.join(' • ');
  }
}

/// Runtime information from LM Studio
@JsonSerializable()
class RuntimeInfo {
  final String? name;
  final String? version;
  
  @JsonKey(name: 'supported_formats')
  final List<String>? supportedFormats;

  RuntimeInfo({
    this.name,
    this.version,
    this.supportedFormats,
  });

  factory RuntimeInfo.fromJson(Map<String, dynamic> json) =>
      _$RuntimeInfoFromJson(json);

  Map<String, dynamic> toJson() => _$RuntimeInfoToJson(this);

  String get displayName {
    if (name == null) return 'Unknown';
    
    // Parse runtime name to show friendly version
    if (name!.contains('metal')) return 'Metal (GPU)';
    if (name!.contains('cuda')) return 'CUDA (GPU)';
    if (name!.contains('vulkan')) return 'Vulkan (GPU)';
    if (name!.contains('cpu')) return 'CPU';
    
    return name!;
  }
}

/// Token usage information
@JsonSerializable()
class TokenUsage {
  @JsonKey(name: 'prompt_tokens')
  final int promptTokens;
  
  @JsonKey(name: 'completion_tokens')
  final int completionTokens;
  
  @JsonKey(name: 'total_tokens')
  final int totalTokens;

  TokenUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory TokenUsage.fromJson(Map<String, dynamic> json) =>
      _$TokenUsageFromJson(json);

  Map<String, dynamic> toJson() => _$TokenUsageToJson(this);
}
