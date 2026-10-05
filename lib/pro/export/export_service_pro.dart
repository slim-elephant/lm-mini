// LM-MINI-PRO-STUB
part of '../../services/export_service.dart';

/// Open-source build: Markdown / Obsidian / JSON export and copy-as-Markdown
/// are not included (PDF, TXT and ZIP export stay available).
extension _ProExport on ExportService {
  Future<void> _proCopyToClipboard(
    ChatConversation conversation,
    List<ChatMessage> messages,
  ) =>
      Future<void>.error(
          UnsupportedError('Available in the official LM Mini app.'));

  Future<File> _proExportMarkdown(
    ChatConversation conversation,
    List<ChatMessage> messages,
  ) =>
      Future<File>.error(
          UnsupportedError('Available in the official LM Mini app.'));

  Future<File> _proExportObsidian(
    ChatConversation conversation,
    List<ChatMessage> messages,
  ) =>
      Future<File>.error(
          UnsupportedError('Available in the official LM Mini app.'));

  Future<File> _proExportJson(
    ChatConversation conversation,
    List<ChatMessage> messages,
  ) =>
      Future<File>.error(
          UnsupportedError('Available in the official LM Mini app.'));
}
