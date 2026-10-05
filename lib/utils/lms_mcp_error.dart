/// LM Studio V1 `integrations` failures: native plugins (`mcp/playwright`) vs
/// Mini's ephemeral Pro Search / Code Sandbox MCPs.
abstract final class LmsMcpError {
  static const pluginConnectionType = 'plugin_connection_error';
  static const mcpConnectionType = 'mcp_connection_error';

  static const unrecognizedGenericUserMessage =
      'LM Studio rejected an MCP. Make sure it is defined in LM Studio as well.';

  static const proSearchUserMessage =
      'Pro Search is temporarily unavailable. Please try again in a moment.';

  static const sandboxUserMessage =
      'Code Sandbox is temporarily unavailable. Please try again in a moment.';

  static const proToolsUserMessage =
      'Pro tools (Search / Sandbox) are temporarily unavailable. Please try again in a moment.';

  static final _pluginId = RegExp(
    r"""mcp/([A-Za-z0-9][A-Za-z0-9._-]*)""",
    caseSensitive: false,
  );

  static final _quotedRemoteServer = RegExp(
    r"""remote mcp server ['\"]([^'\"]+)['\"]""",
    caseSensitive: false,
  );

  static final _bareRemoteServer = RegExp(
    r"""remote mcp server\s+([A-Za-z0-9._-]+)""",
    caseSensitive: false,
  );

  static String _text(Object? error) => error?.toString() ?? '';

  static String _lower(Object? error) => _text(error).toLowerCase();

  static String? _typeOf(Object? error, String? errorType) {
    if (errorType != null && errorType.trim().isNotEmpty) {
      return errorType.trim().toLowerCase();
    }
    if (error is Map) {
      final typed = error['error_type'] ??
          error['type'] ??
          (error['error'] is Map ? error['error']['type'] : null);
      if (typed != null) return typed.toString().trim().toLowerCase();
    }
    return null;
  }

  /// Native LMS plugin (`{"type":"plugin","id":"mcp/…"}`) is missing or unloaded.
  static bool isUnrecognizedPlugin(Object? error, {String? errorType}) {
    final type = _typeOf(error, errorType);
    if (type == pluginConnectionType) return true;
    final lower = _lower(error);
    if (lower.contains('mcp is not recognized by lm studio') ||
        lower.contains('mcps are not recognized by lm studio') ||
        lower.contains('mcp plugin is not recognized by lm studio')) {
      return true;
    }
    return lower.contains('permission denied to use plugin') ||
        lower.contains('cannot find plugin handle') ||
        lower.contains('unable to get plugin tools') ||
        lower.contains('plugin identifier');
  }

  /// Mini's own Pro Search / Code Sandbox MCPs. Those failures can be reported.
  /// Any other MCP rejection is a server setup issue.
  static bool isProToolFailure(Object? error) {
    final lower = _lower(error);
    if (lower.isEmpty) return false;
    if (lower.contains('lmmini-search') || lower.contains('lmmini-sandbox')) {
      return true;
    }
    if (lower.contains('web_search') || lower.contains('run_code')) {
      return true;
    }
    if (lower.contains('pro search is temporarily unavailable') ||
        lower.contains('code sandbox is temporarily unavailable') ||
        lower.contains(
          'pro tools (search / sandbox) are temporarily unavailable',
        )) {
      return true;
    }
    final name = remoteServerName(error)?.toLowerCase();
    return name == 'lmmini-search' || name == 'lmmini-sandbox';
  }

  static bool isEphemeralConnection(Object? error, {String? errorType}) {
    if (isUnrecognizedPlugin(error, errorType: errorType)) return false;
    final type = _typeOf(error, errorType);
    if (type == mcpConnectionType) return true;
    final lower = _lower(error);
    return lower.contains('remote mcp server') ||
        lower.contains('ephemeral_mcp') ||
        lower.contains('mcp_connection_error') ||
        lower.contains('allowed_tools') ||
        lower.contains('invalid tool');
  }

  /// LMS still sends `chat.end` after these — wait instead of aborting.
  static bool shouldWaitForChatEnd(Object? error, {String? errorType}) {
    return isUnrecognizedPlugin(error, errorType: errorType) ||
        isEphemeralConnection(error, errorType: errorType);
  }

  /// Unknown MCP / plugin setup. Pro Search and Code Sandbox stay reportable.
  static bool matches(Object? error, {String? errorType}) {
    if (isProToolFailure(error)) return false;
    if (isUnrecognizedPlugin(error, errorType: errorType)) return true;
    if (isEphemeralConnection(error, errorType: errorType)) return true;
    final lower = _lower(error);
    if (lower.isEmpty) return false;
    return lower.contains('lm studio rejected') ||
        lower.contains('the server rejected an mcp') ||
        lower.contains('the server rejected mcp/') ||
        lower.contains("can't reach mcp server") ||
        lower.contains('cannot reach mcp server');
  }

  /// `'rss-reader'` / `lmmini-search` from LMS "Unable to connect to remote MCP server …".
  static String? remoteServerName(Object? error) {
    final text = _text(error);
    if (text.isEmpty) return null;
    final quoted = _quotedRemoteServer.firstMatch(text);
    final quotedName = quoted?.group(1)?.trim();
    if (quotedName != null && quotedName.isNotEmpty) return quotedName;
    final bare = _bareRemoteServer.firstMatch(text);
    final bareName = bare?.group(1)?.trim();
    if (bareName == null || bareName.isEmpty) return null;
    return bareName;
  }

  static List<String> pluginIds(Object? error) {
    final text = _text(error);
    final seen = <String>{};
    final ids = <String>[];
    for (final match in _pluginId.allMatches(text)) {
      final id = match.group(1)?.trim() ?? '';
      if (id.isEmpty) continue;
      final key = id.toLowerCase();
      if (!seen.add(key)) continue;
      ids.add(id);
    }
    return ids;
  }

  static String displayName(String pluginId) {
    var name = pluginId.trim();
    if (name.toLowerCase().startsWith('mcp/')) {
      name = name.substring(4);
    }
    if (name.isEmpty) return 'MCP';
    if (name == name.toUpperCase()) return name;
    return name.split(RegExp(r'[-_.]+')).where((p) => p.isNotEmpty).map((part) {
      if (part == part.toUpperCase() && part.length > 1) return part;
      return '${part[0].toUpperCase()}${part.substring(1)}';
    }).join(' ');
  }

  static String unrecognizedUserMessageFor(
    Object? error, {
    bool lmStudio = true,
  }) {
    final names = pluginIds(error).map(displayName).toList();
    if (names.isEmpty) {
      return lmStudio
          ? unrecognizedGenericUserMessage
          : 'The server rejected an MCP. Make sure it is defined on the server as well.';
    }
    final labels = names.map((name) => 'MCP/$name').toList();
    final host = lmStudio ? 'LM Studio' : 'The server';
    final where = lmStudio ? 'in LM Studio' : 'on the server';
    if (labels.length == 1) {
      return '$host rejected ${labels.first}. '
          'Make sure this MCP is defined $where as well.';
    }
    final head = labels.sublist(0, labels.length - 1).join(', ');
    return '$host rejected $head and ${labels.last}. '
        'Make sure these MCPs are defined $where as well.';
  }

  static String userMessage(
    Object? error, {
    String? errorType,
    bool lmStudio = true,
  }) {
    if (isUnrecognizedPlugin(error, errorType: errorType)) {
      return unrecognizedUserMessageFor(error, lmStudio: lmStudio);
    }
    final msg = _text(error);
    final name = remoteServerName(error);
    final nameLower = name?.toLowerCase() ?? '';
    final mentionsSandbox = msg.contains('lmmini-sandbox') ||
        msg.contains('run_code') ||
        nameLower == 'lmmini-sandbox';
    final mentionsSearch = msg.contains('lmmini-search') ||
        msg.contains('web_search') ||
        nameLower == 'lmmini-search';
    if (mentionsSandbox && mentionsSearch) return proToolsUserMessage;
    if (mentionsSandbox) return sandboxUserMessage;
    if (mentionsSearch) return proSearchUserMessage;
    if (name != null && name.isNotEmpty) {
      return "Can't reach MCP server \"$name\". Check the server URL in "
          'LM Studio (Program → Integrations).';
    }
    return proSearchUserMessage;
  }

  static String streamingStatus(String userMessage) {
    if (userMessage.contains('rejected MCP') ||
        userMessage.contains('rejected an MCP')) {
      return '⚠️ MCP rejected...';
    }
    if (userMessage.contains('not recognized by LM Studio')) {
      return '⚠️ MCP not recognized by LM Studio...';
    }
    if (userMessage.startsWith("Can't reach MCP server")) {
      return '⚠️ MCP server unreachable...';
    }
    if (userMessage.startsWith('Code Sandbox')) {
      return '⚠️ Code Sandbox connection issue...';
    }
    if (userMessage.startsWith('Pro tools')) {
      return '⚠️ Pro tools connection issue...';
    }
    return '⚠️ Pro Search connection issue...';
  }
}
