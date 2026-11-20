/// The model asked for a tool the app never offered it (often a made-up
/// name like `google_search`, or any tool while Tool Calling is off). A
/// model behaviour, not an app failure.
abstract final class UnknownToolError {
  static final _raw = RegExp(r'unknown tool "([^"]*)"', caseSensitive: false);
  static const _marker = "tried to use a tool it doesn't have";

  /// The tool name inside `Error: Unknown tool "name"`, or null.
  static String? toolName(Object? error) =>
      _raw.firstMatch(error?.toString() ?? '')?.group(1);

  static String userMessageFor(String? tool) {
    final name = (tool == null || tool.trim().isEmpty) ? '' : ' ("$tool")';
    return 'The model $_marker$name, so it stopped. Send your message '
        'again, turn on Tool Calling or Web Search if you want it to look '
        'things up, or pick another model.';
  }

  static bool matches(Object? error) {
    final text = error?.toString() ?? '';
    return text.contains(_marker) || _raw.hasMatch(text);
  }
}
