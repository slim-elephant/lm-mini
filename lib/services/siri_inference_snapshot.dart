import '../models/app_settings.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

/// Frozen copy of the active chat backend for iOS Siri / App Intents.
///
/// Native Swift reads this from the App Group and, when [eligible], POSTs a
/// one-shot OpenAI-compatible completion without launching Flutter. On-device
/// GGUF/MLX, USB, Apple Intelligence, and loopback URLs stay on the Dart path.
class SiriInferenceSnapshot {
  static const appGroupId = 'group.net.neuro9.lmmini';
  static const defaultsKey = 'siriInferenceSnapshot';

  static const hopByHopHeaders = {
    'content-length',
    'transfer-encoding',
    'host',
    'connection',
    'expect',
  };

  final bool eligible;
  final String providerKind;
  final String? chatUrl;
  final String? model;
  final Map<String, String> headers;
  final double temperature;
  final int maxTokens;
  final String? ineligibleReason;

  const SiriInferenceSnapshot({
    required this.eligible,
    required this.providerKind,
    this.chatUrl,
    this.model,
    this.headers = const {},
    this.temperature = 0.7,
    this.maxTokens = 512,
    this.ineligibleReason,
  });

  factory SiriInferenceSnapshot.from({
    required AppSettings settings,
    CloudApiProvider? cloud,
    bool forceOnDevice = false,
  }) {
    final kind = forceOnDevice
        ? (settings.activeProviderKind == 'onDeviceMlx'
            ? 'onDeviceMlx'
            : 'onDeviceGguf')
        : settings.activeProviderKind;

    if (forceOnDevice ||
        kind == 'onDeviceGguf' ||
        kind == 'onDeviceMlx' ||
        kind == 'appleIntelligence') {
      return SiriInferenceSnapshot(
        eligible: false,
        providerKind: kind,
        ineligibleReason: 'on-device',
      );
    }

    // USB and Ollama still get a chatUrl so the in-app Dart wait path can
    // POST. Native Siri HTTP skips them (`eligible: false`): USB is
    // loopback, Ollama's primary API is `/api/chat`.

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    String? chatUrl;
    String? model = settings.selectedModel?.trim();

    if (cloud != null &&
        (kind == 'cloud' ||
            kind == 'omlx' ||
            kind == 'jan' ||
            CloudApiType.isFreeLocalKind(kind))) {
      chatUrl = _joinUrl(cloud.effectiveBaseUrl, cloud.type.chatPath);
      model = (cloud.selectedModel ?? model)?.trim();
      headers.addAll(cloud.type.extraHeaders);
      final key = cloud.apiKey.trim();
      if (key.isNotEmpty) {
        headers['Authorization'] = 'Bearer $key';
      }
      if (cloud.customHeadersEnabled && cloud.customHeaders != null) {
        _mergeHeaders(headers, cloud.customHeaders!);
      }
    } else {
      final base = settings.serverUrl.trim();
      if (base.isEmpty) {
        return SiriInferenceSnapshot(
          eligible: false,
          providerKind: kind,
          ineligibleReason: 'no-url',
        );
      }
      chatUrl = _joinUrl(base, '/v1/chat/completions');
      final token = settings.apiToken?.trim();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final extra = settings.effectiveExtraHeaders;
      if (extra != null) _mergeHeaders(headers, extra);
    }

    // Relay token + routing only for requests to the paired relay URL —
    // never to a cloud API or LAN host.
    if (settings.isActiveRelayUrl(chatUrl)) {
      final relay = settings.remoteAuthToken?.trim();
      if (relay != null && relay.isNotEmpty) {
        headers['X-LM-Mini-Token'] = relay;
        if (cloud?.type == CloudApiType.omlx) {
          headers['X-LM-Mini-Backend'] = 'omlx';
        } else if (cloud?.type == CloudApiType.ollama) {
          headers['X-LM-Mini-Backend'] = 'ollama';
        } else if (cloud?.type == CloudApiType.jan) {
          headers['X-LM-Mini-Backend'] = 'jan';
        } else if (cloud?.type == CloudApiType.unsloth) {
          headers['X-LM-Mini-Backend'] = 'unsloth';
        } else {
          headers['X-LM-Mini-Backend'] =
              headers['X-LM-Mini-Backend'] ?? 'lmStudio';
        }
      }
    }

    final host = Uri.tryParse(chatUrl ?? '')?.host;
    if (isLoopbackHost(host)) {
      return SiriInferenceSnapshot(
        eligible: false,
        providerKind: kind,
        chatUrl: chatUrl,
        model: model,
        headers: Map.unmodifiable(headers),
        temperature: settings.temperature,
        maxTokens: settings.maxTokens,
        ineligibleReason: 'loopback',
      );
    }

    if (chatUrl.isEmpty) {
      return SiriInferenceSnapshot(
        eligible: false,
        providerKind: kind,
        ineligibleReason: 'no-url',
      );
    }

    if (model == null || model.isEmpty) {
      return SiriInferenceSnapshot(
        eligible: false,
        providerKind: kind,
        chatUrl: chatUrl,
        headers: Map.unmodifiable(headers),
        ineligibleReason: 'no-model',
      );
    }

    final maxTokens = settings.maxTokens.clamp(64, 1024);
    return SiriInferenceSnapshot(
      eligible: true,
      providerKind: kind,
      chatUrl: chatUrl,
      model: model,
      headers: Map.unmodifiable(headers),
      temperature: settings.temperature,
      maxTokens: maxTokens,
    );
  }

  Map<String, dynamic> toMap() => {
        'eligible': eligible,
        'providerKind': providerKind,
        'chatUrl': chatUrl,
        'model': model,
        'headers': headers,
        'temperature': temperature,
        'maxTokens': maxTokens,
        'ineligibleReason': ineligibleReason,
      };

  factory SiriInferenceSnapshot.fromMap(Map<String, dynamic> map) {
    final rawHeaders = map['headers'];
    final headers = <String, String>{};
    if (rawHeaders is Map) {
      for (final entry in rawHeaders.entries) {
        headers['${entry.key}'] = '${entry.value}';
      }
    }
    return SiriInferenceSnapshot(
      eligible: map['eligible'] == true,
      providerKind: (map['providerKind'] as String?) ?? 'lmStudio',
      chatUrl: map['chatUrl'] as String?,
      model: map['model'] as String?,
      headers: Map.unmodifiable(headers),
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: (map['maxTokens'] as num?)?.toInt() ?? 512,
      ineligibleReason: map['ineligibleReason'] as String?,
    );
  }

  static bool isLoopbackHost(String? host) {
    if (host == null || host.isEmpty) return true;
    final h = host.toLowerCase();
    if (h == 'localhost' ||
        h == '127.0.0.1' ||
        h == '0.0.0.0' ||
        h == '::1' ||
        h == '[::1]') {
      return true;
    }
    return h.endsWith('.localhost');
  }

  static String joinUrl(String base, String path) => _joinUrl(base, path);

  static String _joinUrl(String base, String path) {
    var b = base.trim();
    while (b.endsWith('/')) {
      b = b.substring(0, b.length - 1);
    }
    final p = path.startsWith('/') ? path : '/$path';
    return '$b$p';
  }

  static void _mergeHeaders(
    Map<String, String> into,
    Map<String, String> extra,
  ) {
    extra.forEach((key, value) {
      final trimmed = key.trim();
      if (trimmed.isEmpty) return;
      if (hopByHopHeaders.contains(trimmed.toLowerCase())) return;
      into[trimmed] = value;
    });
  }
}
