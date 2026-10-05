import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../services/database_service.dart';

/// Result of importing one or more chats.
class ImportResult {
  final int importedCount;
  final int skippedCount;
  final List<String> errors;

  ImportResult({
    required this.importedCount,
    this.skippedCount = 0,
    this.errors = const [],
  });
}

/// Parsed representation of a single LM Studio markdown chat export.
class _ParsedChat {
  final String title;
  final String? model;
  final DateTime? createdAt;
  final List<ChatMessage> messages;

  _ParsedChat({
    required this.title,
    this.model,
    this.createdAt,
    required this.messages,
  });
}

class ChatImportService {
  final DatabaseService _databaseService = DatabaseService();

  /// Let user pick .md or .zip file(s) and import them.
  Future<ImportResult?> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'zip'],
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return null;

    int totalImported = 0;
    int totalSkipped = 0;
    final allErrors = <String>[];

    for (final file in result.files) {
      if (file.path == null) continue;

      final path = file.path!;
      if (path.endsWith('.zip')) {
        final r = await _importZip(File(path));
        totalImported += r.importedCount;
        totalSkipped += r.skippedCount;
        allErrors.addAll(r.errors);
      } else if (path.endsWith('.md')) {
        final r = await _importMarkdownFile(File(path));
        totalImported += r.importedCount;
        totalSkipped += r.skippedCount;
        allErrors.addAll(r.errors);
      }
    }

    return ImportResult(
      importedCount: totalImported,
      skippedCount: totalSkipped,
      errors: allErrors,
    );
  }

  /// Import a single markdown file.
  Future<ImportResult> _importMarkdownFile(File file) async {
    try {
      final content = await file.readAsString();
      final parsed = _parseLmStudioMarkdown(content);
      if (parsed == null) {
        return ImportResult(importedCount: 0, skippedCount: 1, errors: [
          'Failed to parse: ${file.uri.pathSegments.last}',
        ]);
      }
      await _saveParsedChat(parsed);
      return ImportResult(importedCount: 1);
    } catch (e) {
      return ImportResult(importedCount: 0, skippedCount: 1, errors: [
        'Error reading ${file.uri.pathSegments.last}: $e',
      ]);
    }
  }

  /// Import a ZIP archive containing multiple .md files.
  Future<ImportResult> _importZip(File zipFile) async {
    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      int imported = 0;
      int skipped = 0;
      final errors = <String>[];

      for (final entry in archive) {
        if (!entry.isFile) continue;
        final name = entry.name.toLowerCase();
        if (!name.endsWith('.md')) continue;

        try {
          final content = utf8.decode(entry.content as List<int>);
          final parsed = _parseLmStudioMarkdown(content);
          if (parsed == null) {
            skipped++;
            errors.add('Failed to parse: ${entry.name}');
            continue;
          }
          await _saveParsedChat(parsed);
          imported++;
        } catch (e) {
          skipped++;
          errors.add('Error in ${entry.name}: $e');
        }
      }

      return ImportResult(
        importedCount: imported,
        skippedCount: skipped,
        errors: errors,
      );
    } catch (e) {
      return ImportResult(importedCount: 0, skippedCount: 1, errors: [
        'Failed to read ZIP: $e',
      ]);
    }
  }

  /// Parse an LM Studio markdown export into a structured chat.
  ///
  /// Format:
  /// ```
  /// # Chat Title
  /// Model: model-name
  /// Created: date string
  /// Exported from: LM Studio x.x.x
  ///
  /// ### System
  /// (system prompt text)
  ///
  /// ### User
  /// (user message)
  ///
  /// ### Assistant
  /// (assistant message, may contain <think> blocks and tool calls)
  ///
  /// ### Tool
  /// Tool call result:
  /// ```json
  /// {...}
  /// ```
  /// ```
  _ParsedChat? _parseLmStudioMarkdown(String content) {
    // Normalize Windows (CRLF) and old Mac (CR) line endings before any processing.
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    if (lines.isEmpty) return null;

    // Parse header — scan up to 20 lines (LM Studio headers are short but allow slack)
    String? title;
    String? model;
    DateTime? createdAt;
    int headerEndLine = 0;

    for (int i = 0; i < lines.length && i < 20; i++) {
      final line = lines[i];
      if (line.startsWith('# ') && title == null) {
        title = line.substring(2).trim();
      } else if (line.startsWith('Model: ')) {
        model = line.substring(7).trim();
      } else if (line.startsWith('Created: ')) {
        final dateStr = line.substring(9).trim();
        createdAt = _parseDate(dateStr);
      } else if (line.startsWith('Exported from:')) {
        // Skip, just metadata
      }

      // Find where the header ends — support both ### and ## section markers
      if (line.startsWith('### ') || line.startsWith('## ')) {
        headerEndLine = i;
        break;
      }
      headerEndLine = i + 1;
    }

    if (title == null) {
      // Try to extract from first line even without #
      if (lines.isNotEmpty && lines[0].trim().isNotEmpty) {
        title = lines[0].trim();
      } else {
        title = 'Imported Chat';
      }
    }

    // Split content into sections by ### or ## Role markers
    final sections = <_Section>[];
    String? currentRole;
    final currentContent = StringBuffer();

    for (int i = headerEndLine; i < lines.length; i++) {
      final line = lines[i];

      // Support both ### Role (LM Studio 0.3+) and ## Role (older exports)
      final isSectionMarker = line.startsWith('### ') || line.startsWith('## ');
      if (isSectionMarker) {
        // Save previous section
        if (currentRole != null) {
          sections.add(_Section(
            role: currentRole,
            content: currentContent.toString().trim(),
          ));
        }
        // Strip leading hashes to get role name
        currentRole = line.replaceFirst(RegExp(r'^#+\s*'), '').trim();
        currentContent.clear();
      } else {
        if (currentRole != null) {
          currentContent.writeln(line);
        }
      }
    }
    // Save last section
    if (currentRole != null) {
      sections.add(_Section(
        role: currentRole,
        content: currentContent.toString().trim(),
      ));
    }

    if (sections.isEmpty) return null;

    // Convert sections into ChatMessage objects.
    // Strategy:
    //   • Keep <think> blocks intact — the app's response parser renders them as an accordion.
    //   • Handle LM Studio's "### Think" sections: buffer the content and inject it as
    //     <think>...</think> into the IMMEDIATELY FOLLOWING assistant section.
    //   • Skip tool-call REQUEST blocks inside assistant content (metadata only).
    //   • Skip standalone "Tool" sections (tool results) — they are intermediate API plumbing.
    //   • Merge consecutive assistant sections that follow each other without an intervening
    //     user message (happens when the model makes several tool calls in one turn).
    final messages = <ChatMessage>[];
    final now = createdAt ?? DateTime.now();
    int messageIndex = 0;
    String? pendingThinkContent; // buffered ### Think section content

    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];
      final rawRole = section.role.toLowerCase().trim();

      // LM Studio exports DeepSeek-style "### Think" as a dedicated section.
      // Buffer its content so we can prepend it as <think>…</think> to the next
      // assistant section, where the accordion renderer will pick it up.
      if (rawRole == 'think' || rawRole == 'thinking') {
        final thinkBody = section.content.trim();
        if (thinkBody.isNotEmpty) {
          pendingThinkContent = (pendingThinkContent ?? '') +
              ((pendingThinkContent?.isNotEmpty ?? false) ? '\n\n' : '') +
              thinkBody;
        }
        continue;
      }

      final role = _normalizeRole(section.role);
      if (role == null) continue;

      // Skip tool-result sections entirely — they are plumbing, not chat content.
      if (role == 'tool') continue;

      String messageContent = section.content;

      if (role == 'assistant') {
        // Remove tool call request metadata blocks, but KEEP <think> content so the
        // accordion in message_bubble.dart can render it correctly.
        messageContent = _cleanAssistantContentKeepThink(messageContent);

        // Prepend buffered ### Think content (wrapped in tags) BEFORE inline answer.
        if (pendingThinkContent != null && pendingThinkContent.isNotEmpty) {
          // Only add if the content doesn't already start with <think>
          if (!messageContent.trimLeft().startsWith('<think>')) {
            messageContent = '<think>\n$pendingThinkContent\n</think>\n\n$messageContent';
          }
          pendingThinkContent = null;
        }

        // Merge any immediately following assistant sections (same logical turn).
        while (i + 1 < sections.length) {
          final nextRaw = sections[i + 1].role.toLowerCase().trim();
          final nextRole = _normalizeRole(sections[i + 1].role);
          if (nextRaw == 'think' || nextRaw == 'thinking') {
            // Another think section mid-stream — absorb it.
            final extra = sections[i + 1].content.trim();
            if (extra.isNotEmpty) {
              pendingThinkContent = (pendingThinkContent ?? '') +
                  ((pendingThinkContent?.isNotEmpty ?? false) ? '\n\n' : '') +
                  extra;
            }
            i++;
          } else if (nextRole == 'assistant') {
            i++;
            var extra = _cleanAssistantContentKeepThink(sections[i].content);
            // Flush any pending think into this merged extra chunk too.
            if (pendingThinkContent != null && pendingThinkContent.isNotEmpty) {
              if (!extra.trimLeft().startsWith('<think>')) {
                extra = '<think>\n$pendingThinkContent\n</think>\n\n$extra';
              }
              pendingThinkContent = null;
            }
            if (extra.isNotEmpty) {
              messageContent = '$messageContent\n\n$extra';
            }
          } else if (nextRole == 'tool') {
            // Skip over tool sections silently; keep looking for more assistant blocks.
            i++;
          } else {
            break;
          }
        }
      }

      // Skip empty system messages
      if (role == 'system' && messageContent.trim().isEmpty) continue;
      // Skip empty assistant messages (e.g. section contained only a tool-call request)
      if (messageContent.trim().isEmpty) continue;

      final messageId =
          '${now.millisecondsSinceEpoch}_import_${messageIndex}_${DateTime.now().microsecondsSinceEpoch}';
      final messageTimestamp =
          now.add(Duration(seconds: messageIndex));

      messages.add(ChatMessage(
        id: messageId,
        content: messageContent,
        role: role,
        timestamp: messageTimestamp,
        model: role == 'assistant' ? model : null,
      ));

      messageIndex++;
    }

    if (messages.isEmpty) return null;

    return _ParsedChat(
      title: title,
      model: model,
      createdAt: createdAt,
      messages: messages,
    );
  }

  /// Save a parsed chat to the database.
  Future<void> _saveParsedChat(_ParsedChat parsed) async {
    // Use current time for ID generation to ensure uniqueness across imports.
    // parsed.createdAt is only used as the displayed timestamp, not for IDs.
    final idBase = DateTime.now().millisecondsSinceEpoch;
    final now = parsed.createdAt ?? DateTime.now();
    final conversationId = '${idBase}_import';

    final messageIds = <String>[];
    for (final message in parsed.messages) {
      await _databaseService.insertMessage(message, conversationId);
      messageIds.add(message.id);
    }

    final conversation = ChatConversation(
      id: conversationId,
      title: parsed.title,
      createdAt: now,
      updatedAt: now,
      messageIds: messageIds,
      settings: parsed.model != null ? {'model': parsed.model} : {},
    );

    await _databaseService.insertConversation(conversation);
  }

  /// Normalize role strings from LM Studio format.
  String? _normalizeRole(String role) {
    switch (role.toLowerCase()) {
      case 'user':
        return 'user';
      case 'assistant':
        return 'assistant';
      case 'system':
        return 'system';
      case 'tool':
        return 'tool';
      default:
        return null;
    }
  }

  /// Like the old clean method but PRESERVES `<think>` blocks so that the
  /// in-app accordion renderer can show them. Only tool call request metadata
  /// is removed.
  String _cleanAssistantContentKeepThink(String content) {
    return content
        .replaceAll(
            RegExp(
                r'Tool call request:\s*\n```(?:json)?\s*\n[\s\S]*?\n```',
                multiLine: true),
            '')
        .trim();
  }

  /// Try to parse various date formats from LM Studio exports.
  DateTime? _parseDate(String dateStr) {
    // Try common formats: "3/24/2026, 2:32:25 AM", "2026-03-24T02:32:25"
    try {
      // US format: M/D/YYYY, H:MM:SS AM/PM
      final usMatch = RegExp(
              r'(\d{1,2})/(\d{1,2})/(\d{4}),?\s*(\d{1,2}):(\d{2}):(\d{2})\s*(AM|PM)?',
              caseSensitive: false)
          .firstMatch(dateStr);
      if (usMatch != null) {
        final month = int.parse(usMatch.group(1)!);
        final day = int.parse(usMatch.group(2)!);
        final year = int.parse(usMatch.group(3)!);
        var hour = int.parse(usMatch.group(4)!);
        final minute = int.parse(usMatch.group(5)!);
        final second = int.parse(usMatch.group(6)!);
        final amPm = usMatch.group(7);
        if (amPm != null) {
          if (amPm.toUpperCase() == 'PM' && hour != 12) hour += 12;
          if (amPm.toUpperCase() == 'AM' && hour == 12) hour = 0;
        }
        return DateTime(year, month, day, hour, minute, second);
      }
      // ISO format fallback
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }
}

/// Internal section representation during parsing.
class _Section {
  final String role;
  final String content;

  _Section({required this.role, required this.content});
}
