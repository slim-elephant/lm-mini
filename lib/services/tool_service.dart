import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';
import '../models/memory_category.dart';
import '../utils/pro_search_result_logger.dart';

part '../pro/tools/tool_service_pro.dart';

/// Service for handling tool execution
/// Provides local implementations of tools that can be called by LLMs
class ToolService {
  /// Get available tools as function definitions for the LLM.
  /// Includes premium tools (read_url) when the user has an active subscription.
  /// Set [enableWebSearch] to false to exclude the web_search tool.
  static List<Map<String, dynamic>> getAvailableTools({
    bool enableWebSearch = true,
    bool enableCodeSandbox = false,
  }) {
    final isPremium = SubscriptionService().isPremium;

    return [
      if (enableWebSearch)
        {
          'type': 'function',
          'function': {
            'name': 'web_search',
            'description': 'Search the web for current information. Use this when the user asks about recent events, current data, or information you don\'t have in your training data.',
            'parameters': {
              'type': 'object',
              'properties': {
                'query': {
                  'type': 'string',
                  'description': 'The search query',
                },
              },
              'required': ['query'],
              'additionalProperties': false,
            },
            'strict': true,
          },
        },
      ..._ProTools._proExtraToolDefinitions(
        isPremium: isPremium,
        enableCodeSandbox: enableCodeSandbox,
      ),
    ];
  }

  /// Execute a tool call
  /// Returns the result as a string
  static Future<String> executeTool({
    required String toolName,
    required Map<String, dynamic> arguments,
    String? searxngUrl, // Optional SearXNG instance URL
    int searchResultsCount = 5, // Default search results count
    bool preferSearxng = false, // Whether to override premium search

    /// Scope that memory writes from this turn are filed under, taken from the
    /// active persona. Keeps a roleplay model's `save_memory` calls out of the
    /// user's real memory.
    ///
    /// The memory tools are not advertised in [getAvailableTools] (see agent.md
    /// §1.2 — they stay background-only so they can't force the V0 API), but a
    /// model or MCP server can still name them, so these handlers honour scope
    /// rather than trusting the caller.
    MemoryScope memoryScope = MemoryScope.global,

    /// Owning persona for [memoryScope] when it isn't global.
    String? memoryPersonaId,

    /// Invoked for each successful memory write so the caller can surface an
    /// undo affordance, the same way auto-extraction does.
    void Function(MemoryUpsertResult result)? onMemoryWrite,
  }) async {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🔧 TOOL CALL: $toolName');
    debugPrint('📝 Arguments: $arguments');
    debugPrint('═══════════════════════════════════════════════════════════');
    
    try {
      final pro = await _ProTools._proExecuteTool(
        toolName,
        arguments,
        memoryScope: memoryScope,
        memoryPersonaId: memoryPersonaId,
        onMemoryWrite: onMemoryWrite,
      );
      if (pro != null) return pro;

      switch (toolName) {
        case 'web_search':
          // Validate required arguments
          if (!arguments.containsKey('query') || arguments['query'] == null) {
            return 'Error: Missing required argument "query" for web_search';
          }
          // Always use the user's setting — don't let the model override the count
          final numResults = searchResultsCount;
          // Sanitize: some models wrap the query in extra quotes (e.g.
          // `"current weather"`) which SearXNG treats as an exact-phrase
          // search and returns zero results. Strip wrapping quote marks.
          final rawQuery = arguments['query'] as String;
          final cleanedQuery = _sanitizeQuery(rawQuery);
          if (cleanedQuery.isEmpty) {
            return 'Error: Empty query for web_search';
          }
          debugPrint('🌐 WEB SEARCH - Query: "$cleanedQuery"'
              '${cleanedQuery != rawQuery ? " (was: \"$rawQuery\")" : ""}');
          debugPrint('🌐 WEB SEARCH - Num Results: $numResults (from settings)');
          debugPrint('🌐 WEB SEARCH - SearXNG URL: ${searxngUrl ?? "NOT CONFIGURED"}');
          return await _webSearch(
            query: cleanedQuery,
            numResults: numResults,
            searxngUrl: searxngUrl,
            preferSearxng: preferSearxng,
          );

        case 'get_current_time':
          return _getCurrentTime();

        default:
          return 'Error: Unknown tool "$toolName"';
      }
    } catch (e, stackTrace) {
      debugPrint('Tool execution error: $e\n$stackTrace');
      return 'Error executing tool "$toolName": $e';
    }
  }

  /// Strip wrapping quotes that some LLMs add around tool arguments.
  /// E.g. `"current weather"` → `current weather`.
  /// Iterates a few times to handle nested quoting like `""query""`.
  static String _sanitizeQuery(String raw) {
    var q = raw.trim();
    for (var i = 0; i < 3; i++) {
      if (q.length < 2) break;
      final first = q[0];
      final last = q[q.length - 1];
      const pairs = <List<String>>[
        ['"', '"'], ["'", "'"], ['`', '`'],
        ['\u201c', '\u201d'], // “ ”
        ['\u2018', '\u2019'], // ‘ ’
      ];
      final matched = pairs.any((p) => first == p[0] && last == p[1]);
      if (!matched) break;
      q = q.substring(1, q.length - 1).trim();
    }
    return q;
  }

  /// Search using SearXNG instance
  static Future<String> _searxngSearch(
    String query,
    int numResults,
    String searxngUrl,
  ) async {
    // SearXNG JSON API endpoint - must use /search path
    final baseUri = Uri.parse(searxngUrl);
    final url = Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.port,
      path: '/search',
      queryParameters: {
        'q': query,
        'format': 'json',
      },
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'LMStudioChat/1.0',
        'X-Forwarded-For': '127.0.0.1',
        'X-Real-IP': '127.0.0.1',
      },
    ).timeout(const Duration(seconds: 15));

    // Check for 403 - JSON API might be disabled
    if (response.statusCode == 403) {
      throw Exception('SearXNG JSON API is disabled. Enable it in settings.yml with:\njson:\n  enabled: true');
    }

    // Accept 200 or 202
    if (response.statusCode == 200 || response.statusCode == 202) {
      try {
        final data = jsonDecode(response.body);
        final results = data['results'] as List?;

        if (results == null || results.isEmpty) {
          return 'No results found for "$query" via SearXNG.\n\n💡 Tip: Check if SearXNG is running: http://localhost:8888';
        }

        // Format results as markdown
        final buffer = StringBuffer();
        buffer.writeln('**Web Search Results (SearXNG) for "$query":**\n');

        final limitedResults = results.take(numResults);
        for (var i = 0; i < limitedResults.length; i++) {
          final result = limitedResults.elementAt(i);
          final title = result['title'] ?? 'No title';
          final content = result['content'] ?? result['snippet'] ?? '';
          final url = result['url'] ?? '';

          buffer.writeln('${i + 1}. **$title**');
          if (content.isNotEmpty) {
            buffer.writeln('   $content');
          }
          if (url.isNotEmpty) {
            buffer.writeln('   🔗 $url\n');
          }
        }

        buffer.writeln('---');
        buffer.writeln('✨ Powered by SearXNG');
        return buffer.toString();
      } catch (e) {
        debugPrint('❌ SearXNG JSON parse error: $e');
        throw Exception('Failed to parse SearXNG response: $e');
      }
    } else {
      throw Exception('SearXNG returned status ${response.statusCode}');
    }
  }

  /// Web search using premium search API (for subscribers) or SearXNG fallback.
  static Future<String> _webSearch({
    required String query,
    int numResults = 5,
    String? searxngUrl,
    bool preferSearxng = false,
  }) async {
    final isPremium = SubscriptionService().isPremium;

    debugPrint('───────────────────────────────────────────────────────────');
    debugPrint('🔍 WEB SEARCH EXECUTION STARTED');
    debugPrint('   Query: "$query"');
    debugPrint('   Requested results: $numResults');
    debugPrint('   Premium: $isPremium');
    debugPrint('   Prefer SearXNG: $preferSearxng');
    debugPrint('───────────────────────────────────────────────────────────');

    // 0️⃣ If the user explicitly prefers SearXNG, try it first
    if (preferSearxng && searxngUrl != null && searxngUrl.isNotEmpty) {
      try {
        debugPrint('🔍 TRYING SEARXNG (FORCED EXPECTATION)...');
        debugPrint('   URL: $searxngUrl');
        final result = await _searxngSearch(query, numResults, searxngUrl);
        debugPrint('✅ SEARXNG SUCCESS');
        debugPrint('───────────────────────────────────────────────────────────');
        return result;
      } catch (e) {
        debugPrint('❌ SEARXNG FAILED: $e');
        // Premium users can still use Pro Search; don't hard-fail here.
        if (!isPremium) {
          return 'SearXNG search failed for "$query": $e\n\n'
              '💡 Check your SearXNG configuration or set up SearXNG:\n'
              '   docker run -d -p 8888:8080 searxng/searxng\n'
              '   Then add http://localhost:8888 in Settings → Tools → Web Search → Configure';
        }
        debugPrint('↩️ Falling through to premium search after SearXNG failure');
      }
    }

    // 1️⃣ Premium search — no setup needed, just works
    final premium = await _ProTools._proPremiumWebSearch(query, numResults);
    if (premium != null) return premium;

    // 2️⃣ SearXNG fallback (self-hosted) if not already tried
    if (!preferSearxng && searxngUrl != null && searxngUrl.isNotEmpty) {
      try {
        debugPrint('🔍 TRYING SEARXNG...');
        debugPrint('   URL: $searxngUrl');
        final result = await _searxngSearch(query, numResults, searxngUrl);
        debugPrint('✅ SEARXNG SUCCESS');
        debugPrint('───────────────────────────────────────────────────────────');
        return result;
      } catch (e) {
        debugPrint('❌ SEARXNG FAILED: $e');
        return 'SearXNG search failed for "$query": $e\n\n'
            '💡 Check your SearXNG configuration or set up SearXNG:\n'
            '   docker run -d -p 8888:8080 searxng/searxng\n'
            '   Then add http://localhost:8888 in Settings → Tools → Web Search → Configure';
      }
    }

    // 3️⃣ No search provider available
    debugPrint('⚠️ No search provider configured');
    if (!isPremium) {
      return _ProTools._proNoSearchProviderHint(query);
    }
    return 'Search temporarily unavailable for "$query". Please try again.';
  }

  /// Get current date and time
  static String _getCurrentTime() {
    final now = DateTime.now();
    return 'Current date and time: ${now.toString()}\n'
        'Date: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}\n'
        'Time: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }
}
