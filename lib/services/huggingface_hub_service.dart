import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Summary of a public Hugging Face model returned by the Hub search API.
class HfModelSummary {
  final String id;
  final int downloads;
  final int likes;
  final String? pipelineTag;
  final List<String> tags;

  const HfModelSummary({
    required this.id,
    required this.downloads,
    required this.likes,
    this.pipelineTag,
    this.tags = const [],
  });

  factory HfModelSummary.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'];
    return HfModelSummary(
      id: (json['modelId'] ?? json['id'] ?? '') as String,
      downloads: (json['downloads'] as num?)?.toInt() ?? 0,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      pipelineTag: json['pipeline_tag'] as String?,
      tags: tagsRaw is List ? tagsRaw.map((e) => e.toString()).toList() : const [],
    );
  }

  String get owner => id.contains('/') ? id.split('/').first : id;

  bool get isTextGeneration =>
      pipelineTag == 'text-generation' ||
      tags.any((t) => t == 'text-generation' || t == 'conversational');

  bool get isLmStudioTagged => tags.any((t) => t.toLowerCase().contains('lmstudio'));

  String get shortName => id.contains('/') ? id.split('/').last : id;
}

/// Extra metadata from `GET /api/models/{repo}` for the info sheet.
class HfModelDetails {
  final String id;
  final int downloads;
  final int likes;
  final String? pipelineTag;
  final String? libraryName;
  final String? license;
  final String? baseModel;
  final List<String> tags;
  final DateTime? lastModified;

  const HfModelDetails({
    required this.id,
    required this.downloads,
    required this.likes,
    this.pipelineTag,
    this.libraryName,
    this.license,
    this.baseModel,
    this.tags = const [],
    this.lastModified,
  });

  factory HfModelDetails.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'];
    final card = json['cardData'];
    Map<String, dynamic>? cardData;
    if (card is Map) cardData = Map<String, dynamic>.from(card);

    DateTime? modified;
    final lm = json['lastModified'] as String?;
    if (lm != null) modified = DateTime.tryParse(lm);

    return HfModelDetails(
      id: (json['modelId'] ?? json['id'] ?? '') as String,
      downloads: (json['downloads'] as num?)?.toInt() ?? 0,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      pipelineTag: json['pipeline_tag'] as String?,
      libraryName: json['library_name'] as String?,
      license: cardData?['license'] as String?,
      baseModel: cardData?['base_model'] as String?,
      tags: tagsRaw is List ? tagsRaw.map((e) => e.toString()).toList() : const [],
      lastModified: modified,
    );
  }

  bool get isLmStudioTagged =>
      tags.any((t) => t.toLowerCase().contains('lmstudio'));
}

/// A GGUF file inside a Hugging Face repo.
class HfGgufFile {
  final String path;
  final int size;
  final String quantization;
  final String filename;

  const HfGgufFile({
    required this.path,
    required this.size,
    required this.quantization,
    required this.filename,
  });
}

/// Public Hugging Face Hub REST helpers — no API key required for public repos.
class HuggingFaceHubService {
  HuggingFaceHubService._();
  static final HuggingFaceHubService instance = HuggingFaceHubService._();

  static const String _apiBase = 'https://huggingface.co/api';

  /// Search/browse GGUF models on the Hub.
  Future<List<HfModelSummary>> searchModels({
    String query = '',
    bool lmStudioOnly = false,
    int limit = 24,
  }) async {
    final params = <String, String>{
      'limit': '$limit',
      'sort': 'downloads',
      'direction': '-1',
      'full': 'false',
    };
    if (query.trim().isNotEmpty) {
      params['search'] = query.trim();
    }
    if (lmStudioOnly) {
      params['apps'] = 'lmstudio';
    } else {
      params['filter'] = 'gguf';
    }

    final uri = Uri.parse('$_apiBase/models').replace(queryParameters: params);
    debugPrint('HuggingFaceHubService: GET $uri');
    final res = await http.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw HuggingFaceHubException('Hub search failed (HTTP ${res.statusCode})');
    }
    final body = json.decode(res.body);
    if (body is! List) return const [];

    return body
        .whereType<Map>()
        .map((m) => HfModelSummary.fromJson(Map<String, dynamic>.from(m)))
        .where((m) => m.id.contains('/'))
        .toList();
  }

  /// Fetch model card metadata for the info dialog.
  Future<HfModelDetails> fetchModelDetails(String repoOrUrl) async {
    final repo = _normalizeRepo(repoOrUrl);
    final apiUrl = '$_apiBase/models/$repo';
    final response = await http
        .get(Uri.parse(apiUrl))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw HuggingFaceHubException(
          'Failed to load model info (HTTP ${response.statusCode})');
    }
    return HfModelDetails.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// List GGUF quantizations in a repo (`owner/repo` or HF URL).
  Future<List<HfGgufFile>> listGgufFiles(String repoOrUrl) async {
    final repo = _normalizeRepo(repoOrUrl);
    final apiUrl = '$_apiBase/models/$repo/tree/main';
    debugPrint('HuggingFaceHubService: GET $apiUrl');

    final response = await http
        .get(Uri.parse(apiUrl))
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw HuggingFaceHubException(
          'Failed to list repo files (HTTP ${response.statusCode})');
    }

    final List<dynamic> files = jsonDecode(response.body);
    return files
        .where((file) =>
            file is Map &&
            file['type'] == 'file' &&
            file['path'].toString().toLowerCase().endsWith('.gguf'))
        .map((file) {
          final path = file['path'].toString();
          final size = (file['size'] as num?)?.toInt() ?? 0;
          final filename = path.split('/').last;
          return HfGgufFile(
            path: path,
            size: size,
            quantization: _extractQuantization(filename),
            filename: filename,
          );
        })
        .toList()
      ..sort((a, b) => b.size.compareTo(a.size));
  }

  /// Merge LM Studio's authoritative quant names with HF file sizes.
  Future<List<HfGgufFile>> ggufFilesForLmStudioQuants(
    String repo,
    List<String> lmStudioQuants,
  ) async {
    List<HfGgufFile> hfFiles = const [];
    try {
      hfFiles = await listGgufFiles(repo);
    } catch (_) {
      // Size lookup is best-effort; quants still come from LM Studio.
    }
    return lmStudioQuants.map((q) {
      final qUpper = q.toUpperCase();
      HfGgufFile? match;
      for (final f in hfFiles) {
        if (f.quantization.toUpperCase() == qUpper ||
            f.filename.toUpperCase().contains(qUpper)) {
          match = f;
          break;
        }
      }
      return HfGgufFile(
        path: match?.path ?? '',
        size: match?.size ?? 0,
        quantization: q,
        filename: match?.filename ?? q,
      );
    }).toList();
  }

  /// Convert selection to a download reference for [LocalModelDownloadService].
  String downloadRef(String repo, HfGgufFile file) => '$repo/${file.path}';

  /// Full Hugging Face repo URL for LM Studio download API.
  String repoUrl(String repo) => 'https://huggingface.co/$repo';

  String _normalizeRepo(String input) {
    final trimmed = input.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.host.contains('huggingface.co')) {
      final segs = uri.pathSegments;
      if (segs.length >= 2) return '${segs[0]}/${segs[1]}';
    }
    return trimmed.replaceAll('https://huggingface.co/', '');
  }

  static String _extractQuantization(String filename) {
    final filenameUpper = filename.toUpperCase();
    final patterns = [
      RegExp(r'IQ\d+_[A-Z]+'),
      RegExp(r'Q\d+_K(?:_[SMLV])?'),
      RegExp(r'Q\d+_\d+'),
      RegExp(r'Q\d+(?![_A-Z0-9])'),
      RegExp(r'(?:BF|F)\d+'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(filenameUpper);
      if (match != null) return match.group(0)!;
    }
    return 'Unknown';
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String formatDownloads(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

class HuggingFaceHubException implements Exception {
  final String message;
  HuggingFaceHubException(this.message);
  @override
  String toString() => message;
}
