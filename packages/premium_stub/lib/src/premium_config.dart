/// Global configuration for the premium package.
///
/// The main app sets [firebaseReady] after Firebase initialization
/// so premium services know whether Firebase is available.
class PremiumConfig {
  /// Whether Firebase has been successfully initialized.
  /// Set this from main.dart after Firebase.initializeApp().
  static bool firebaseReady = false;

  /// URL for the Pro Search MCP server (Firebase Cloud Function).
  /// Stub returns empty — Pro Search MCP not available without premium package.
  static String proSearchMcpUrl = '';

  /// URL for the Code Sandbox MCP.
  /// Stub returns empty — sandbox not available without premium package.
  static String codeSandboxMcpUrl = '';

  /// Resolved sandbox MCP URL (same as [codeSandboxMcpUrl] in the stub).
  static String get resolvedCodeSandboxMcpUrl => codeSandboxMcpUrl.trim();
}
