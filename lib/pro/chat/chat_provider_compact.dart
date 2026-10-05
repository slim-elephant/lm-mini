// LM-MINI-PRO-STUB
part of '../../providers/chat_provider.dart';

/// Open-source build: Compact chat is not included. Conversations that were
/// already compacted (for example synced ones) still send their stored
/// summary plus the newer turns.
extension _ProCompact on ChatProvider {
  Future<void> _proCompactCurrentConversation(
    AppSettings settings, {
    SettingsProvider? settingsProvider,
    BuildContext? uiContext,
  }) async {}
}
