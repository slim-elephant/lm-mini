import 'dart:convert';

import '../models/chat_message.dart';
import 'pro_search_result_logger.dart';

/// One web page cited by `web_search` / LM Mini search / SearXNG.
class WebSearchSource {
  final String title;
  final String url;
  final String snippet;
  final String host;
  final String siteName;

  const WebSearchSource({
    required this.title,
    required this.url,
    required this.snippet,
    required this.host,
    required this.siteName,
  });

  /// DuckDuckGo icon CDN (no Google round-trip).
  String get faviconUrl => 'https://icons.duckduckgo.com/ip3/$host.ico';

  String get googleFaviconUrl =>
      'https://www.google.com/s2/favicons?domain=$host&sz=64';

  String get letter {
    final s = siteName.trim();
    if (s.isEmpty) return '?';
    return s.substring(0, 1).toUpperCase();
  }
}

/// Parse titles + URLs out of stored tool / MCP search payloads.
///
/// We do **not** get favicons from the tools — only titles, snippets, and
/// URLs. Site names come from the host; icons are fetched from the domain.
class WebSearchSources {
  WebSearchSources._();

  static bool isSearchToolName(String? name) {
    if (name == null) return false;
    final n = name.trim().toLowerCase().replaceAll('-', '_');
    return n == 'web_search' || n == 'websearch';
  }

  static bool isSearchCall(ChatMessage message) {
    return isSearchToolName(toolNameFromCall(message));
  }

  static bool isSearchResult(ChatMessage message) {
    return isSearchToolName(toolNameFromResult(message)) ||
        (message.role == 'tool' || message.role == 'mcp') &&
            looksLikeSearchPayload(message.content);
  }

  static String? toolNameFromCall(ChatMessage message) {
    final c = message.content;
    final toolCall = RegExp(r'Tool call:\s*([A-Za-z0-9_-]+)').firstMatch(c);
    if (toolCall != null) return toolCall.group(1);
    final mcp = RegExp(r'(?:🔧\s*)?MCP call:\s*([A-Za-z0-9_-]+)@')
        .firstMatch(c);
    return mcp?.group(1);
  }

  static String? toolNameFromResult(ChatMessage message) {
    final mcp = RegExp(r'✅\s*MCP result \(([^)]+)\)').firstMatch(message.content);
    return mcp?.group(1);
  }

  static String displayPayload(String content) {
    final header =
        RegExp(r'✅\s*MCP result \([^)]+\):\s*(.*)$', dotAll: true).firstMatch(content);
    final body = header?.group(1) ?? content;
    return ProSearchResultLogger.extractPlainText(body);
  }

  static bool looksLikeSearchPayload(String content) {
    final text = displayPayload(content);
    if (text.contains('Web Search Results') ||
        text.contains('SearXNG') ||
        text.contains('Powered by SearXNG')) {
      return true;
    }
    if (RegExp(r'^\d+\.\s+\*\*', multiLine: true).hasMatch(text)) return true;
    if (RegExp(r'(?:^|\n)\s*(?:Source|URL)\s*:', caseSensitive: false)
        .hasMatch(text)) {
      return true;
    }
    return false;
  }

  /// Unique sources from a list of tool/MCP messages (calls + results).
  static List<WebSearchSource> fromMessages(List<ChatMessage> messages) {
    final out = <WebSearchSource>[];
    final seen = <String>{};
    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final next = i + 1 < messages.length ? messages[i + 1] : null;
      String? payload;
      if (isSearchCall(msg) &&
          next != null &&
          (next.role == 'tool' || next.role == 'mcp')) {
        payload = displayPayload(next.content);
        i++;
      } else if (isSearchResult(msg) && !isSearchCall(msg)) {
        payload = displayPayload(msg.content);
      }
      if (payload == null || payload.trim().isEmpty) continue;
      for (final source in parse(payload)) {
        final key = _normUrl(source.url);
        if (key.isEmpty || seen.contains(key)) continue;
        seen.add(key);
        out.add(source);
      }
    }
    return out;
  }

  static List<WebSearchSource> parse(String content) {
    final text = displayPayload(content);
    if (text.trim().isEmpty) return [];

    final fromJson = _parseJson(text);
    if (fromJson.isNotEmpty) return _dedupe(fromJson);

    final fromBlocks = _parseNumberedBlocks(text);
    if (fromBlocks.isNotEmpty) return _dedupe(fromBlocks);

    final fromSourceLines = _parseSourceLines(text);
    if (fromSourceLines.isNotEmpty) return _dedupe(fromSourceLines);

    final fromMd = _parseMarkdownLinks(text);
    if (fromMd.isNotEmpty) return _dedupe(fromMd);

    return _dedupe(_parseBareUrls(text));
  }

  static List<WebSearchSource> _dedupe(List<WebSearchSource> sources) {
    final seen = <String>{};
    final out = <WebSearchSource>[];
    for (final source in sources) {
      final key = _normUrl(source.url);
      if (key.isEmpty || !seen.add(key)) continue;
      out.add(source);
    }
    return out;
  }

  static List<WebSearchSource> _parseJson(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return [];
    try {
      final decoded = jsonDecode(trimmed);
      final rows = <Map<String, dynamic>>[];
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            rows.add(Map<String, dynamic>.from(item));
          }
        }
      } else if (decoded is Map) {
        final results = decoded['results'] ??
            decoded['organic_results'] ??
            decoded['items'] ??
            decoded['data'];
        if (results is List) {
          for (final item in results) {
            if (item is Map) {
              rows.add(Map<String, dynamic>.from(item));
            }
          }
        }
      }
      final out = <WebSearchSource>[];
      for (final row in rows) {
        final url = (row['url'] ?? row['link'] ?? row['href'] ?? '').toString();
        if (url.isEmpty || !url.startsWith('http')) continue;
        final title = (row['title'] ?? row['name'] ?? '').toString().trim();
        final snippet = (row['content'] ??
                row['snippet'] ??
                row['description'] ??
                row['body'] ??
                '')
            .toString()
            .trim();
        final source = fromUrl(
          url,
          title: title.isEmpty ? null : title,
          snippet: snippet,
        );
        if (source != null) out.add(source);
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  static List<WebSearchSource> _parseNumberedBlocks(String text) {
    final cards = <WebSearchSource>[];
    final blockRe = RegExp(
      r'(?:^|\n)\s*\d+\.\s+\*\*(.+?)\*\*\s*\n\s*(.*?)\n\s*(?:🔗\s*)?(https?://\S+)',
      dotAll: true,
    );
    for (final match in blockRe.allMatches(text)) {
      final title = match.group(1)?.trim() ?? '';
      final snippet =
          (match.group(2) ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
      final url = match.group(3)?.trim() ?? '';
      final source = fromUrl(url, title: title, snippet: snippet);
      if (source != null) cards.add(source);
    }
    if (cards.isNotEmpty) return cards;

    final loose = RegExp(
      r'(?:^|\n)\s*(?:\[\d+\]|\d+[.)])\s+(.+?)\n\s*(https?://\S+)',
      dotAll: true,
    );
    for (final match in loose.allMatches(text)) {
      var title = (match.group(1) ?? '').replaceAll('**', '').trim();
      title = title.split('\n').first.trim();
      final url = match.group(2)?.trim() ?? '';
      final source = fromUrl(url, title: title);
      if (source != null) cards.add(source);
    }
    return cards;
  }

  static List<WebSearchSource> _parseSourceLines(String text) {
    final out = <WebSearchSource>[];
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final urlMatch = RegExp(
        r'^(?:Source|URL)\s*:\s*(https?://\S+)',
        caseSensitive: false,
      ).firstMatch(line);
      if (urlMatch == null) continue;
      final url = urlMatch.group(1) ?? '';
      String? title;
      for (var j = i - 1; j >= 0 && j >= i - 3; j--) {
        final prev = lines[j].trim().replaceAll('**', '');
        if (prev.isEmpty) continue;
        if (RegExp(r'^https?://').hasMatch(prev)) continue;
        if (RegExp(r'^(?:Source|URL)\s*:', caseSensitive: false)
            .hasMatch(prev)) {
          continue;
        }
        title = prev.replaceFirst(RegExp(r'^\d+[.)]\s*'), '');
        break;
      }
      final source = fromUrl(url, title: title);
      if (source != null) out.add(source);
    }
    return out;
  }

  static List<WebSearchSource> _parseMarkdownLinks(String text) {
    final out = <WebSearchSource>[];
    final re = RegExp(r'\[([^\]]+)\]\((https?://[^)]+)\)');
    for (final match in re.allMatches(text)) {
      final source = fromUrl(
        match.group(2) ?? '',
        title: match.group(1),
      );
      if (source != null) out.add(source);
    }
    return out;
  }

  static List<WebSearchSource> _parseBareUrls(String text) {
    final out = <WebSearchSource>[];
    final re = RegExp(r'https?://[^\s)\]>]+');
    for (final match in re.allMatches(text)) {
      var url = match.group(0) ?? '';
      url = url.replaceFirst(RegExp(r'[.,;:]+$'), '');
      final source = fromUrl(url);
      if (source != null) out.add(source);
    }
    return out;
  }

  static WebSearchSource? fromUrl(
    String rawUrl, {
    String? title,
    String snippet = '',
  }) {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    var host = uri.host.toLowerCase();
    if (host.startsWith('www.')) host = host.substring(4);
    final siteName = _siteName(host);
    final cleanTitle = (title ?? '').trim();
    return WebSearchSource(
      title: cleanTitle.isEmpty ? siteName : cleanTitle,
      url: uri.toString(),
      snippet: snippet,
      host: host,
      siteName: siteName,
    );
  }

  static String _siteName(String host) {
    const multiTlds = {
      'co.uk',
      'com.au',
      'co.jp',
      'com.br',
      'co.kr',
      'com.tr',
      'co.nz',
      'org.uk',
    };
    var rest = host;
    for (final tld in multiTlds) {
      if (host.endsWith('.$tld')) {
        rest = host.substring(0, host.length - tld.length - 1);
        break;
      }
    }
    final parts = rest.split('.');
    final core = parts.length >= 2 ? parts[parts.length - 2] : parts.first;
    if (core.isEmpty) return host;
    return core[0].toUpperCase() + core.substring(1);
  }

  static String _normUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url.toLowerCase();
    var host = uri.host.toLowerCase();
    if (host.startsWith('www.')) host = host.substring(4);
    var path = uri.path;
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return '$host$path';
  }
}
