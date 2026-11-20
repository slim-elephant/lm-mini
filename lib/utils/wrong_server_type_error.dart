import 'dart:convert';

/// The server answered an Ollama route with a bare 404: it is not Ollama
/// (llama.cpp, vLLM, a proxy, LM Studio, …) but was added as one.
///
/// A real Ollama 404 names the model (`model "x" not found, try pulling it
/// first`) and is left to `ModelNotFoundError`.
abstract final class WrongServerTypeError {
  static const _marker = "didn't answer like";

  static String userMessageFor(String serverType) =>
      "This server $_marker $serverType. Make sure you selected the correct "
      'server type in Settings. If you are unsure, add it as '
      'A.I Compatible API, which works with most API services.';

  /// True for a 404 whose body is empty, HTML, plain "not found", or a JSON
  /// error that only says "not found" — nothing about a model.
  static bool isBareNotFound(int statusCode, String body) {
    if (statusCode != 404) return false;
    var text = body.trim();
    if (text.isEmpty || text.startsWith('<')) return true;
    if (text.startsWith('{')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map) {
          final err =
              decoded['error'] ?? decoded['message'] ?? decoded['detail'];
          if (err is Map) {
            text = (err['message'] ?? '').toString();
          } else if (err != null) {
            text = err.toString();
          }
        }
      } catch (_) {}
    }
    final lower = text.trim().toLowerCase();
    if (lower.contains('model')) return false;
    return lower.isEmpty ||
        lower == 'not found' ||
        lower == '404 not found' ||
        lower == '404 page not found' ||
        lower == 'page not found' ||
        lower == 'not found.';
  }

  static bool matches(Object? error) =>
      error != null && error.toString().contains(_marker);
}
