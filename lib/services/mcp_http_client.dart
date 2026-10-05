import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/app_settings.dart';

/// Lightweight MCP client for remote HTTP / Streamable-HTTP servers.
///
/// Used when the active backend cannot host MCP itself (Ollama, cloud,
/// on-device). Discovers tools via `tools/list` and executes via `tools/call`.
///
/// Supports:
/// - JSON responses from Streamable HTTP POST
/// - SSE (`text/event-stream`) responses with `data:` JSON-RPC payloads
/// - Optional `Mcp-Session-Id` header continuity
class McpHttpClient {
  McpHttpClient._();
  static final McpHttpClient instance = McpHttpClient._();

  static const Duration _timeout = Duration(seconds: 30);

  int _nextId = 1;

  /// List tools from every active ephemeral MCP server and return them in
  /// OpenAI / Ollama tool-definition shape, plus a lookup table for execution.
  Future<McpToolCatalog> collectTools(List<McpServerConfig> servers) async {
    final tools = <Map<String, dynamic>>[];
    final registry = <String, McpToolRef>{};

    for (final server in servers) {
      try {
        final session = await _openSession(server);
        final listed = await _toolsList(server, session);
        for (final tool in listed) {
          final name = tool.name;
          if (name.isEmpty) continue;
          // Prefer the raw tool name so models that know MCP tool names work.
          // If two servers collide, namespace as mcp_<label>_<name>.
          var exposedName = name;
          if (registry.containsKey(exposedName)) {
            final safeLabel = server.label
                .toLowerCase()
                .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
            exposedName = 'mcp_${safeLabel}_$name';
          }
          registry[exposedName] = McpToolRef(
            server: server,
            sessionId: session.sessionId,
            remoteName: name,
          );
          tools.add({
            'type': 'function',
            'function': {
              'name': exposedName,
              'description': tool.description.isNotEmpty
                  ? tool.description
                  : 'MCP tool "$name" from ${server.label}',
              'parameters': tool.inputSchema.isNotEmpty
                  ? tool.inputSchema
                  : {
                      'type': 'object',
                      'properties': <String, dynamic>{},
                    },
            },
          });
        }
        debugPrint(
            '🔌 MCP ${server.label}: listed ${listed.length} tool(s)');
      } catch (e) {
        debugPrint('⚠️ MCP ${server.label}: failed to list tools: $e');
      }
    }

    return McpToolCatalog(tools: tools, registry: registry);
  }

  /// Execute a previously registered MCP tool.
  Future<String> callTool({
    required McpToolRef ref,
    required Map<String, dynamic> arguments,
  }) async {
    final session = await _openSession(ref.server, existingSessionId: ref.sessionId);
    final result = await _rpc(
      ref.server,
      session,
      method: 'tools/call',
      params: {
        'name': ref.remoteName,
        'arguments': arguments,
      },
    );
    return _stringifyToolResult(result);
  }

  Future<_McpSession> _openSession(
    McpServerConfig server, {
    String? existingSessionId,
  }) async {
    final session = _McpSession(sessionId: existingSessionId);
    // initialize is required by most Streamable HTTP servers.
    try {
      final init = await _rpc(
        server,
        session,
        method: 'initialize',
        params: {
          'protocolVersion': '2024-11-05',
          'capabilities': {
            'tools': {},
          },
          'clientInfo': {
            'name': 'lm-mini',
            'version': '1.0.0',
          },
        },
      );
      // Some servers return session via header only; body may include nothing.
      if (init is Map && init['serverInfo'] != null) {
        debugPrint('🔌 MCP ${server.label}: initialized');
      }
      // notifications/initialized (fire-and-forget)
      await _rpc(
        server,
        session,
        method: 'notifications/initialized',
        params: const {},
        notification: true,
      );
    } catch (e) {
      // Some simple HTTP MCP proxies don't require initialize — continue.
      debugPrint('🔌 MCP ${server.label}: initialize skipped/failed: $e');
    }
    return session;
  }

  Future<List<_McpListedTool>> _toolsList(
    McpServerConfig server,
    _McpSession session,
  ) async {
    final result = await _rpc(
      server,
      session,
      method: 'tools/list',
      params: const {},
    );
    final tools = <_McpListedTool>[];
    if (result is Map) {
      final list = result['tools'];
      if (list is List) {
        for (final entry in list.whereType<Map>()) {
          final name = entry['name']?.toString() ?? '';
          if (name.isEmpty) continue;
          final description = entry['description']?.toString() ?? '';
          final schema = entry['inputSchema'];
          tools.add(_McpListedTool(
            name: name,
            description: description,
            inputSchema: schema is Map<String, dynamic>
                ? schema
                : (schema is Map
                    ? Map<String, dynamic>.from(schema)
                    : <String, dynamic>{}),
          ));
        }
      }
    }
    return tools;
  }

  Future<dynamic> _rpc(
    McpServerConfig server,
    _McpSession session, {
    required String method,
    required Map<String, dynamic> params,
    bool notification = false,
  }) async {
    final id = notification ? null : _nextId++;
    final payload = <String, dynamic>{
      'jsonrpc': '2.0',
      if (id != null) 'id': id,
      'method': method,
      if (params.isNotEmpty || !notification) 'params': params,
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json, text/event-stream',
      if (server.authorization != null && server.authorization!.isNotEmpty)
        'Authorization': server.authorization!,
      if (session.sessionId != null) 'Mcp-Session-Id': session.sessionId!,
      ...?server.headers,
    };

    final response = await http
        .post(
          Uri.parse(server.url),
          headers: headers,
          body: jsonEncode(payload),
        )
        .timeout(_timeout);

    final sessionHeader = response.headers['mcp-session-id'] ??
        response.headers['Mcp-Session-Id'];
    if (sessionHeader != null && sessionHeader.isNotEmpty) {
      session.sessionId = sessionHeader;
    }

    if (notification) return null;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'MCP HTTP ${response.statusCode} from ${server.label}: ${response.body}');
    }

    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('text/event-stream')) {
      return _parseSseJsonRpc(response.body, expectedId: id);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      if (decoded['error'] != null) {
        throw Exception('MCP error from ${server.label}: ${decoded['error']}');
      }
      return decoded['result'];
    }
    // Some servers return a JSON array of messages.
    if (decoded is List) {
      for (final entry in decoded.whereType<Map>()) {
        if (entry['id'] == id) {
          if (entry['error'] != null) {
            throw Exception(
                'MCP error from ${server.label}: ${entry['error']}');
          }
          return entry['result'];
        }
      }
    }
    return decoded;
  }

  dynamic _parseSseJsonRpc(String body, {required int? expectedId}) {
    dynamic lastResult;
    for (final line in body.split('\n')) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data:')) continue;
      final data = trimmed.substring(5).trim();
      if (data.isEmpty || data == '[DONE]') continue;
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          if (expectedId != null &&
              decoded['id'] != null &&
              decoded['id'] != expectedId) {
            continue;
          }
          if (decoded['error'] != null) {
            throw Exception('MCP SSE error: ${decoded['error']}');
          }
          if (decoded.containsKey('result')) {
            lastResult = decoded['result'];
          }
        }
      } catch (e) {
        if (e.toString().contains('MCP SSE error')) rethrow;
        continue;
      }
    }
    return lastResult;
  }

  String _stringifyToolResult(dynamic result) {
    if (result == null) return '';
    if (result is String) return result;
    if (result is Map) {
      final content = result['content'];
      if (content is List) {
        final parts = <String>[];
        for (final part in content) {
          if (part is Map) {
            final type = part['type']?.toString();
            if (type == 'text') {
              parts.add(part['text']?.toString() ?? '');
            } else {
              parts.add(jsonEncode(part));
            }
          } else {
            parts.add(part.toString());
          }
        }
        final joined = parts.where((p) => p.isNotEmpty).join('\n');
        if (joined.isNotEmpty) return joined;
      }
      if (result['isError'] == true) {
        return 'MCP tool error: ${jsonEncode(result)}';
      }
    }
    return jsonEncode(result);
  }
}

class McpToolCatalog {
  final List<Map<String, dynamic>> tools;
  final Map<String, McpToolRef> registry;

  const McpToolCatalog({
    required this.tools,
    required this.registry,
  });

  bool get isEmpty => tools.isEmpty;
  bool get isNotEmpty => tools.isNotEmpty;
}

class McpToolRef {
  final McpServerConfig server;
  final String? sessionId;
  final String remoteName;

  const McpToolRef({
    required this.server,
    required this.remoteName,
    this.sessionId,
  });
}

class _McpSession {
  String? sessionId;
  _McpSession({this.sessionId});
}

class _McpListedTool {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;

  const _McpListedTool({
    required this.name,
    required this.description,
    required this.inputSchema,
  });
}
