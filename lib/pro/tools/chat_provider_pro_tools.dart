// LM-MINI-PRO-STUB
part of '../../providers/chat_provider.dart';

/// Open-source build: Pro Search and the hosted Code Sandbox are not
/// included. Web search uses SearXNG (V0 client-side tools) when configured.
extension _ProToolsRouting on ChatProvider {
  bool _proExemptFromToolLoopCap(AppSettings settings) => false;

  bool _proIsProSearchActive(AppSettings settings,
          {required bool toolsEnabled}) =>
      false;

  bool _proProSearchUsesMcp(
          {required bool isProSearch, required bool isCloudRouted}) =>
      false;

  bool _proIsCodeSandboxActive(AppSettings settings) => false;

  bool _proCodeSandboxUsesMcp(AppSettings settings,
          {required bool isCloudRouted}) =>
      false;

  Future<List<Map<String, dynamic>>?> _proBuildEphemeralIntegrations({
    required AppSettings settings,
    required bool isProSearch,
    required bool isCloudRouted,
    required void Function(String message) onAuthFailed,
  }) async =>
      null;
}
