import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Debug logging helpers for Pro Search (`web_search` / `read_url`) tool output.
class ProSearchResultLogger {
  ProSearchResultLogger._();

  /// Log how many results came back and a short preview of the payload.
  static void logToolOutput({
    required String tool,
    Object? output,
    String? query,
  }) {
    final text = extractPlainText(output);
    final count = estimateResultCount(tool: tool, text: text);
    final preview = text.length <= 100
        ? text
        : '${text.substring(0, 100).replaceAll('\n', ' ')}…';
    final q = (query == null || query.isEmpty) ? '' : ' query="$query"';
    debugPrint(
      '🔍 Pro Search $tool:$q results=$count chars=${text.length} preview="$preview"',
    );
  }

  /// Flatten MCP / LMS tool output into plain text for logging.
  static String extractPlainText(Object? output) {
    if (output == null) return '';
    if (output is String) {
      final trimmed = output.trim();
      if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
        try {
          return extractPlainText(jsonDecode(trimmed));
        } catch (_) {
          return trimmed;
        }
      }
      return trimmed;
    }
    if (output is List) {
      final parts = <String>[];
      for (final item in output) {
        if (item is Map) {
          final type = item['type']?.toString();
          if (type == 'text' && item['text'] != null) {
            parts.add(item['text'].toString());
          } else if (item['text'] != null) {
            parts.add(item['text'].toString());
          } else {
            parts.add(jsonEncode(item));
          }
        } else {
          parts.add(item.toString());
        }
      }
      return parts.join('\n').trim();
    }
    if (output is Map) {
      if (output['text'] != null) return output['text'].toString().trim();
      if (output['content'] != null) {
        return extractPlainText(output['content']);
      }
      if (output['result'] != null) {
        return extractPlainText(output['result']);
      }
      return jsonEncode(output);
    }
    return output.toString().trim();
  }

  /// Best-effort count of discrete search/page results in [text].
  static int estimateResultCount({
    required String tool,
    required String text,
  }) {
    if (text.isEmpty) return 0;
    final lower = text.toLowerCase();
    if (lower.contains('no results found') ||
        lower.contains('search temporarily unavailable') ||
        lower.contains('no search provider')) {
      return 0;
    }

    if (tool == 'read_url') {
      // One URL read → one "result" if we got content.
      return text.trim().isEmpty ? 0 : 1;
    }

    // Numbered list: "1. …" / "1) …" / "[1] …"
    final numbered = RegExp(
      r'(?:^|\n)\s*(?:\[\d+\]|\d+[.)])\s+\S',
      multiLine: true,
    ).allMatches(text);
    if (numbered.isNotEmpty) return numbered.length;

    // "Source:" / "URL:" lines (common Pro Search formatting)
    final sources = RegExp(
      r'(?:^|\n)\s*(?:Source|URL)\s*:',
      caseSensitive: false,
    ).allMatches(text);
    if (sources.isNotEmpty) return sources.length;

    // Markdown links as a weak fallback
    final mdLinks = RegExp(r'\[[^\]]+\]\(https?://[^)]+\)').allMatches(text);
    if (mdLinks.isNotEmpty) return mdLinks.length;

    // Bare http(s) URLs
    final urls = RegExp(r'https?://\S+').allMatches(text);
    if (urls.isNotEmpty) return urls.length;

    // Non-empty content that isn't an explicit zero-result message.
    return text.trim().isEmpty ? 0 : 1;
  }
}
