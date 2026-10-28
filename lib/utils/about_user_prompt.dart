/// Longest "About you" text Settings accepts.
const kAboutUserMaxLength = 1500;

/// System prompt block for Settings → About you, or null when the user has
/// set neither a name nor a description.
String? aboutUserPromptBlock({String? name, String? about}) {
  final n = name?.trim() ?? '';
  var a = about?.trim() ?? '';
  if (a.length > kAboutUserMaxLength) a = a.substring(0, kAboutUserMaxLength);
  if (n.isEmpty && a.isEmpty) return null;
  final buffer = StringBuffer()
    ..writeln('--- About the user ---')
    ..writeln('The user wrote this about themselves. Use it to personalize '
        'your replies, without repeating it back unless asked.');
  if (n.isNotEmpty) buffer.writeln('Name: $n');
  if (a.isNotEmpty) buffer.writeln(a);
  return buffer.toString().trim();
}
