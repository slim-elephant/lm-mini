/// Stub premium tool delegate — all operations throw.
///
/// In the real premium package, this routes search, URL-read, and code
/// sandbox requests to the hosted Pro service.
class PremiumToolDelegate {
  /// Whether premium tool execution is available.
  /// Always false in stub.
  static bool get isAvailable => false;

  /// Premium search via the hosted Pro service.
  /// Throws in stub — caller should fall through to SearXNG.
  static Future<String> search(String query, int numResults) async {
    throw UnimplementedError('Premium search requires the premium package');
  }

  /// Read URL via the hosted Pro service.
  /// Throws in stub — caller should fall through to direct read.
  static Future<String> readUrl(String url) async {
    throw UnimplementedError('Premium URL reader requires the premium package');
  }

  /// Run code via the hosted Pro service.
  /// Throws in stub.
  static Future<String> runCode({
    required String language,
    required String code,
    int timeoutSec = 12,
  }) async {
    throw UnimplementedError('Code sandbox requires the premium package');
  }
}
