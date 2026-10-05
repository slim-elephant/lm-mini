// LM-MINI-PRO-STUB
part of '../../services/tool_service.dart';

/// Open-source build: only web_search (SearXNG) and get_current_time.
extension _ProTools on ToolService {
  static List<Map<String, dynamic>> _proExtraToolDefinitions({
    required bool isPremium,
    required bool enableCodeSandbox,
  }) =>
      const <Map<String, dynamic>>[];

  static Future<String?> _proExecuteTool(
    String toolName,
    Map<String, dynamic> arguments, {
    required MemoryScope memoryScope,
    String? memoryPersonaId,
    void Function(MemoryUpsertResult result)? onMemoryWrite,
  }) async {
    switch (toolName) {
      case 'run_code':
      case 'read_url':
      case 'save_memory':
      case 'update_memory':
      case 'delete_memory':
        return 'Error: $toolName is not available in this build.';
      default:
        return null;
    }
  }

  static Future<String?> _proPremiumWebSearch(
    String query,
    int numResults,
  ) async =>
      null;

  static String _proNoSearchProviderHint(String query) {
    return 'No search provider available for "$query".\n\n'
        '💡 Set up SearXNG for web search:\n'
        '   docker run -d -p 8888:8080 searxng/searxng\n'
        '   Then configure the URL in Settings → Tools → Web Search → Configure';
  }
}
