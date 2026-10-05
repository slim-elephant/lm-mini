// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lm_studio_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LMStudioModel _$LMStudioModelFromJson(Map<String, dynamic> json) =>
    LMStudioModel(
      id: json['id'] as String,
      object: json['object'] as String? ?? 'model',
      type: json['type'] as String? ?? 'llm',
      publisher: json['publisher'] as String? ?? '',
      arch: json['arch'] as String? ?? '',
      compatibilityType: json['compatibility_type'] as String? ?? '',
      quantization: json['quantization'] as String? ?? '',
      state: json['state'] as String? ?? 'not-loaded',
      maxContextLength: (json['max_context_length'] as num?)?.toInt() ?? 0,
      loadedContextLength: (json['loaded_context_length'] as num?)?.toInt(),
      sizeBytes: (json['size_bytes'] as num?)?.toInt(),
      paramsString: json['params_string'] as String?,
      capabilities: (json['capabilities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      v1DisplayName: json['v1DisplayName'] as String?,
      format: json['format'] as String?,
      description: json['description'] as String?,
      bitsPerWeight: (json['bitsPerWeight'] as num?)?.toDouble(),
      visionCapability: json['visionCapability'] as bool?,
      toolUseCapability: json['toolUseCapability'] as bool?,
      evalBatchSize: (json['evalBatchSize'] as num?)?.toInt(),
      flashAttention: json['flashAttention'] as bool?,
    );

Map<String, dynamic> _$LMStudioModelToJson(LMStudioModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'object': instance.object,
      'type': instance.type,
      'publisher': instance.publisher,
      'arch': instance.arch,
      'compatibility_type': instance.compatibilityType,
      'quantization': instance.quantization,
      'state': instance.state,
      'max_context_length': instance.maxContextLength,
      'loaded_context_length': instance.loadedContextLength,
      'size_bytes': instance.sizeBytes,
      'params_string': instance.paramsString,
      'capabilities': instance.capabilities,
      'v1DisplayName': instance.v1DisplayName,
      'format': instance.format,
      'description': instance.description,
      'bitsPerWeight': instance.bitsPerWeight,
      'visionCapability': instance.visionCapability,
      'toolUseCapability': instance.toolUseCapability,
      'evalBatchSize': instance.evalBatchSize,
      'flashAttention': instance.flashAttention,
    };

LMStudioModelsResponse _$LMStudioModelsResponseFromJson(
        Map<String, dynamic> json) =>
    LMStudioModelsResponse(
      object: json['object'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => LMStudioModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LMStudioModelsResponseToJson(
        LMStudioModelsResponse instance) =>
    <String, dynamic>{
      'object': instance.object,
      'data': instance.data,
    };
