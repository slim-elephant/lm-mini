import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'math_markdown.dart';
import '../models/chat_message.dart';
import '../models/file_attachment.dart';
import '../models/memory_category.dart';
import '../utils/file_picker_helper.dart';
import '../utils/response_parser.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../services/tts_service.dart';
import '../services/kokoro_tts_service.dart';
import '../services/remote_kokoro_tts_service.dart';
import '../services/elevenlabs_tts_service.dart';
import '../services/grok_tts_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/chat_font_helper.dart';
import '../utils/image_picker_helper.dart';
import '../utils/theme_extensions.dart';
import '../utils/layout_utils.dart';
import '../models/app_theme.dart';
import '../utils/selection_utils.dart';
import '../utils/share_helper.dart';
import '../utils/kokoro_speaker_resolver.dart';
import '../utils/elevenlabs_voice_resolver.dart';
import '../utils/grok_voice_resolver.dart';
import '../utils/tts_engine.dart';
import '../utils/web_search_sources.dart';
import 'full_width_streaming_status.dart';
import 'search_source_pile.dart';
import 'image_gen_button.dart';
import '../utils/generated_image_info.dart';
import 'persona_avatar.dart';
import 'transcription_job_card.dart';
import 'think_brain_icon.dart';
import 'glass_popup_menu.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

/// Resolves a stored image path (relative or absolute) and returns a
/// [FileImage] if the file exists, or null if not found.
FileImage? _resolveFileImage(String storedPath) {
  final resolved = ImagePickerHelper.resolveImagePathSync(storedPath);
  if (resolved == null) return null;
  return FileImage(File(resolved));
}

/// Chat photos are stored as a relative path or an older absolute path.
/// [Image.file] on the raw string misses both after the app container moves.
Widget _storedChatImage(
  String storedPath, {
  required Widget onError,
  BoxFit fit = BoxFit.cover,
}) {
  final resolved = ImagePickerHelper.resolveImagePathSync(storedPath);
  if (resolved == null) return onError;
  return Image.file(
    File(resolved),
    fit: fit,
    errorBuilder: (_, __, ___) => onError,
  );
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isStreaming;
  final String? userAvatarPath;
  final String? assistantAvatarPath;
  final Map<String, dynamic>? conversationSettings;
  final List<ChatMessage>?
      allMessages; // Chronological messages for preceding tool/MCP lookback
  /// Chronological index into [allMessages] (oldest→newest). Not reverse-ListView index.
  final int? messageIndex;
  final VoidCallback? onRegenerate;
  final void Function(String newContent, {bool andRegenerate})? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onBranch;
  final void Function(ChatMessage updated)? onMessageUpdated;
  final void Function(int newIndex)? onAlternativeSelected;
  final bool isLastAssistantMessage;
  final String? participantName;
  final String? participantAvatarPath;
  final int? participantColor;

  /// Face focus for assistant / participant bubble avatars.
  final Alignment assistantAvatarAlignment;
  final double assistantAvatarScale;

  /// Opens persona profile when the assistant avatar is tapped.
  final VoidCallback? onAssistantAvatarTap;

  const MessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.userAvatarPath,
    this.assistantAvatarPath,
    this.conversationSettings,
    this.allMessages,
    this.messageIndex,
    this.onRegenerate,
    this.onEdit,
    this.onDelete,
    this.onBranch,
    this.onMessageUpdated,
    this.onAlternativeSelected,
    this.isLastAssistantMessage = false,
    this.participantName,
    this.participantAvatarPath,
    this.participantColor,
    this.assistantAvatarAlignment = const Alignment(0, -0.28),
    this.assistantAvatarScale = 1.0,
    this.onAssistantAvatarTap,
  });

  String? _shortModelLabel(String? model) {
    if (model == null || model.isEmpty) return null;
    final slashIndex = model.lastIndexOf('/');
    return slashIndex >= 0 ? model.substring(slashIndex + 1) : model;
  }

  bool _isTranscriptionMessage() {
    return message.role == 'assistant' &&
        message.content.contains('## Transcription');
  }

  String? _transcriptionJobIdFromUserMessage() {
    if (message.role != 'user' || !message.id.endsWith('_user')) return null;
    final c = message.content;
    final looksLikeJob = c.startsWith('Audio:') ||
        c.contains('Transcrib') ||
        c.startsWith('🎙️');
    if (!looksLikeJob) return null;
    return message.id.substring(0, message.id.length - '_user'.length);
  }

  bool _isTranscriptionUserMessage() =>
      _transcriptionJobIdFromUserMessage() != null;

  Future<void> _shareTranscript(BuildContext context) async {
    // Prefer the entry matching this message's job id (multi-file chats).
    final jobId = message.id.endsWith('_assistant')
        ? message.id.substring(0, message.id.length - '_assistant'.length)
        : null;
    String? srt;
    String? plain;
    final raw = conversationSettings?['transcriptions'];
    if (jobId != null && raw is List) {
      for (final e in raw) {
        if (e is Map && e['jobId']?.toString() == jobId) {
          srt = e['srtText']?.toString().trim();
          plain = e['plainText']?.toString().trim();
          break;
        }
      }
    }
    srt ??= conversationSettings?['transcriptionSrtText']?.toString().trim();
    plain ??=
        conversationSettings?['transcriptionPlainText']?.toString().trim();
    final text = (srt != null && srt.isNotEmpty) ? srt : plain;
    if (text == null || text.isEmpty) return;
    await shareTextFromContext(context, text, subject: 'Transcription');
  }

  @override
  Widget build(BuildContext context) {
    String currentSelection = '';

    final isUser = message.role == 'user';
    final isTool = message.role == 'tool';
    final isMcp = message.role == 'mcp';
    final isToolCall =
        message.role == 'assistant' && message.content.startsWith('Tool call:');
    final isMcpCall = message.role == 'assistant' &&
        (message.content.startsWith('MCP call:') ||
            message.content.startsWith('🔧 MCP call:'));

    // Hide tool calls, tool results, MCP calls, and MCP results - they're shown as badges on assistant messages
    if (isTool || isToolCall || isMcp || isMcpCall) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final parsed = !isUser ? ResponseParser.parse(message.content) : null;
    final thinking = parsed?.thinking;
    // Strip [IMG_PROMPT: ...] tag from display text (it's only for image generation)
    // Also strip truncated tags where closing ] is missing (max output hit)
    final rawAnswer = parsed?.answer ?? message.content;
    String answer = rawAnswer
        .replaceAll(RegExp(r'\[IMG_PROMPT:\s*.+?\]', dotAll: true), '')
        .replaceAll(RegExp(r'\[IMG_PROMPT:[^\]]*$', dotAll: true), '')
        // Strip leading [Name]: prefix that models copy from the context format
        .replaceFirst(
            participantName != null && !isUser
                ? RegExp(
                    '^\\[${RegExp.escape(participantName!)}\\]:\\s*',
                    caseSensitive: false,
                  )
                : RegExp(r'^\x00'), // no-op pattern when no participantName
            '')
        .trim();

    final chatProvider = context.read<ChatProvider>();
    if (chatProvider.isGroupChat && !isUser) {
      for (final p in chatProvider.groupParticipants) {
        final pattern = RegExp('\\[${RegExp.escape(p.displayName)}\\]',
            caseSensitive: false);
        answer =
            answer.replaceAllMapped(pattern, (_) => '**@${p.displayName}**');
      }
    }

    final thinkingDurationMs = !isUser
        ? context.select<ChatProvider, int?>(
            (p) => p.thinkingDurationFor(message.id))
        : null;
    final settings = context.watch<SettingsProvider>().settings;
    final l10n = AppLocalizations.of(context);
    final wideThread = settings.fullWidthAssistant;
    final fullWidthAssistant = wideThread && !isUser;
    final deferRichMarkdown = !isUser &&
        settings.lowBatteryMode &&
        (isStreaming ||
            (isLastAssistantMessage && chatProvider.isSendingMessage));

    // Detect if this assistant message has tool calls/results or MCP calls/results preceding it
    List<ChatMessage> toolMessages = [];
    if (!isUser &&
        allMessages != null &&
        messageIndex != null &&
        messageIndex! > 0) {
      // Look backwards for tool call and result pairs that came before this message.
      // [messageIndex] must be chronological (oldest→newest), not reverse-ListView index.
      for (int i = messageIndex! - 1; i >= 0; i--) {
        final msg = allMessages![i];
        final isToolCallAssistant = msg.role == 'assistant' &&
            (msg.content.startsWith('Tool call:') ||
                msg.content.startsWith('MCP call:') ||
                msg.content.startsWith('🔧 MCP call:'));
        final isToolOrMcp =
            msg.role == 'tool' || msg.role == 'mcp' || isToolCallAssistant;
        if (isToolOrMcp) {
          toolMessages.insert(0, msg); // Insert at beginning to maintain order
        } else if (msg.role == 'user') {
          // Stop when we hit the user message for this exchange
          break;
        } else if (msg.role == 'assistant') {
          // Previous final answer — don't steal its tools for this bubble
          break;
        }
      }
    }

    final hasMedia =
        (message.imageUrls != null && message.imageUrls!.isNotEmpty) ||
            (message.fileAttachments != null &&
                message.fileAttachments!.isNotEmpty) ||
            message.hasGeneratedImages;
    final hasText = answer.isNotEmpty ||
        (thinking != null && thinking.isNotEmpty) ||
        toolMessages.isNotEmpty;
    if (!isStreaming && !hasMedia && !hasText) {
      return const SizedBox.shrink();
    }

    // Get custom colors from conversation settings, then theme, then colorScheme
    final userBubbleColorValue =
        conversationSettings?['userBubbleColor'] as int?;
    final userTextColorValue = conversationSettings?['userTextColor'] as int?;
    final assistantBubbleColorValue =
        conversationSettings?['assistantBubbleColor'] as int?;
    final assistantTextColorValue =
        conversationSettings?['assistantTextColor'] as int?;
    final chatFontFamily = conversationSettings?['chatFontFamily'] as String?;

    final themeColors = context.appThemeColors;

    final bubbleColor = isUser
        ? (userBubbleColorValue != null
            ? Color(userBubbleColorValue)
            : themeColors.userBubbleColor ?? theme.colorScheme.primary)
        : (assistantBubbleColorValue != null
            ? Color(assistantBubbleColorValue)
            : themeColors.assistantBubbleColor ??
                theme.colorScheme.surfaceContainerHighest);

    final textColor = isUser
        ? (userTextColorValue != null
            ? Color(userTextColorValue)
            : themeColors.userBubbleTextColor ?? theme.colorScheme.onPrimary)
        : (assistantTextColorValue != null
            ? Color(assistantTextColorValue)
            : fullWidthAssistant
                ? theme.colorScheme.onSurface
                : themeColors.assistantBubbleTextColor ??
                    theme.colorScheme.onSurfaceVariant);

    final isAssistantStreamingBubble = isStreaming && !isUser;
    final isThinkingOngoing = !isUser &&
        thinking != null &&
        thinking.isNotEmpty &&
        thinkingDurationMs == null &&
        isAssistantStreamingBubble;
    final hideAvatars = settings.hideAvatars;
    final avatarRadius = settings.chatBubbleAvatarRadius;
    // Hide pictures leaves "picture above messages" on in settings; treat
    // that as side-by-side so bubbles keep their normal vertical gap.
    final avatarAbove = settings.avatarAboveMessage && !hideAvatars;
    final assistantModelLabel = !isUser && !_isTranscriptionMessage()
        ? _shortModelLabel(message.model)
        : null;
    final currentBubbleStyle = context.appTheme.bubbleStyle;

    // Resolve avatar for this bubble: participant override > global assistant
    final effectiveAvatarPath = participantAvatarPath ?? assistantAvatarPath;
    // Participant accent color for group chat bubble border
    final pColor = participantColor != null ? Color(participantColor!) : null;

    // Build the avatar widget (reused in both layouts)
    Widget buildAssistantAvatar() {
      final avatar = PersonaAvatar(
        imagePath: effectiveAvatarPath,
        radius: avatarRadius,
        backgroundColor: pColor ?? theme.colorScheme.secondary,
        alignment: assistantAvatarAlignment,
        scale: assistantAvatarScale,
        fallbackIconColor: theme.colorScheme.onSecondary,
      );
      if (onAssistantAvatarTap == null) return avatar;
      return Tooltip(
        message: AppLocalizations.of(context).viewProfile,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onAssistantAvatarTap,
            child: avatar,
          ),
        ),
      );
    }

    Widget buildUserAvatar() => CircleAvatar(
          radius: avatarRadius,
          backgroundColor: theme.colorScheme.primary,
          backgroundImage: (userAvatarPath != null)
              ? _resolveFileImage(userAvatarPath!)
              : null,
          child: (userAvatarPath == null ||
                  _resolveFileImage(userAvatarPath!) == null)
              ? Icon(
                  Icons.person,
                  size: avatarRadius * 0.6,
                  color: theme.colorScheme.onPrimary,
                )
              : null,
        );

    // Builds the thinking + main-text section (what changes per alternative).
    Widget buildMessageContent() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && thinking != null && thinking.isNotEmpty) ...[
              SelectionContainer.disabled(
                child: _ThinkingExpansionTile(
                  textColor: textColor,
                  isThinkingOngoing: isThinkingOngoing,
                  toolMessages: toolMessages,
                  theme: theme,
                  onShowToolDialog: (toolMsg) =>
                      _showToolDialog(context, toolMsg, theme),
                  thinkingLabel: isThinkingOngoing ? l10n.thinking : 'Thought',
                  thinkingDuration:
                      (!isThinkingOngoing && thinkingDurationMs != null)
                          ? _formatDurationClock(thinkingDurationMs)
                          : null,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: textColor.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: fullWidthAssistant
                            ? null
                            : Border(
                                left: BorderSide(
                                    color: textColor.withOpacity(0.15),
                                    width: 2)),
                      ),
                      child: Text(
                        thinking,
                        style: ChatFontHelper.apply(
                          chatFontFamily,
                          TextStyle(
                              color: textColor.withOpacity(0.7),
                              fontSize: 13,
                              height: 1.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
            ],
            SelectionArea(
              onSelectionChanged: (content) {
                currentSelection = content?.plainText ?? '';
              },
              contextMenuBuilder: (context, selectableRegionState) {
                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: selectableRegionState.contextMenuAnchors,
                  buttonItems:
                      selectableRegionState.contextMenuButtonItems.map((item) {
                    if (item.type == ContextMenuButtonType.copy) {
                      return ContextMenuButtonItem(
                        onPressed: () {
                          String copiedText = SelectionUtils.extractMarkdown(
                              currentSelection, answer);
                          Clipboard.setData(ClipboardData(text: copiedText));
                          selectableRegionState.hideToolbar();
                        },
                        type: ContextMenuButtonType.copy,
                      );
                    }
                    return item;
                  }).toList(),
                );
              },
              child: isUser
                  ? (_isTranscriptionUserMessage()
                      ? TranscriptionJobCard(
                          jobId: _transcriptionJobIdFromUserMessage()!,
                          conversationSettings: conversationSettings,
                          textColor: textColor,
                        )
                      : Text(
                          answer,
                          style: ChatFontHelper.apply(
                            chatFontFamily,
                            TextStyle(
                                color: textColor,
                                fontSize: settings.chatFontSize,
                                height: 1.45),
                          ),
                        ))
                  : deferRichMarkdown
                      ? Text(
                          answer,
                          style: ChatFontHelper.apply(
                            chatFontFamily,
                            TextStyle(
                                color: textColor,
                                fontSize: settings.chatFontSize,
                                height: 1.45),
                          ),
                        )
                      : MathMarkdown(
                          data: answer,
                          selectable: false,
                          textColor: textColor,
                          baseFontSize: settings.chatFontSize,
                          extensionSet: md.ExtensionSet(
                            md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                            [
                              md.EmojiSyntax(),
                              ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                            ],
                          ),
                          onTapLink: (text, href, title) {
                            if (href != null) {
                              launchUrl(Uri.parse(href));
                            }
                          },
                          styleSheet: MarkdownStyleSheet(
                            p: ChatFontHelper.apply(
                              chatFontFamily,
                              TextStyle(
                                  color: textColor,
                                  fontSize: settings.chatFontSize,
                                  height: 1.5),
                            ),
                            h1: ChatFontHelper.apply(
                              chatFontFamily,
                              TextStyle(
                                  color: textColor,
                                  fontSize: settings.chatFontSize + 10,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4),
                            ),
                            h1Padding:
                                const EdgeInsets.only(top: 16, bottom: 8),
                            h2: ChatFontHelper.apply(
                              chatFontFamily,
                              TextStyle(
                                  color: textColor,
                                  fontSize: settings.chatFontSize + 6,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4),
                            ),
                            h2Padding:
                                const EdgeInsets.only(top: 14, bottom: 6),
                            h3: ChatFontHelper.apply(
                              chatFontFamily,
                              TextStyle(
                                  color: textColor,
                                  fontSize: settings.chatFontSize + 4,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4),
                            ),
                            h3Padding:
                                const EdgeInsets.only(top: 12, bottom: 4),
                            h4: ChatFontHelper.apply(
                              chatFontFamily,
                              TextStyle(
                                  color: textColor,
                                  fontSize: settings.chatFontSize + 2,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4),
                            ),
                            h5: ChatFontHelper.apply(
                              chatFontFamily,
                              TextStyle(
                                  color: textColor,
                                  fontSize: settings.chatFontSize,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4),
                            ),
                            h6: ChatFontHelper.apply(
                              chatFontFamily,
                              TextStyle(
                                  color: textColor,
                                  fontSize: settings.chatFontSize - 2,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4),
                            ),
                            em: ChatFontHelper.apply(
                              chatFontFamily,
                              TextStyle(
                                  color: textColor,
                                  fontStyle: FontStyle.italic),
                            ),
                            strong: ChatFontHelper.apply(
                              chatFontFamily,
                              TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold),
                            ),
                            del: ChatFontHelper.apply(
                              chatFontFamily,
                              TextStyle(
                                  color: textColor.withOpacity(0.6),
                                  decoration: TextDecoration.lineThrough),
                            ),
                            blockquote: ChatFontHelper.apply(
                              chatFontFamily,
                              TextStyle(
                                  color: textColor.withOpacity(0.8),
                                  fontStyle: FontStyle.italic),
                            ),
                            blockquoteDecoration: BoxDecoration(
                              border: Border(
                                  left: BorderSide(
                                      color: textColor.withOpacity(0.5),
                                      width: 4)),
                              color: textColor.withOpacity(0.05),
                            ),
                            blockquotePadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            code: TextStyle(
                              color: textColor,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHigh,
                              fontFamily: 'monospace',
                              fontSize: settings.chatFontSize - 1,
                            ),
                            codeblockDecoration: const BoxDecoration(),
                            codeblockPadding: EdgeInsets.zero,
                            listBullet: ChatFontHelper.apply(
                              chatFontFamily,
                              TextStyle(
                                  color: textColor,
                                  fontSize: settings.chatFontSize),
                            ),
                            listIndent: 24,
                            listBulletPadding: const EdgeInsets.only(right: 8),
                            tableHead: ChatFontHelper.apply(
                              chatFontFamily,
                              TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold),
                            ),
                            tableBody: ChatFontHelper.apply(
                              chatFontFamily,
                              TextStyle(color: textColor),
                            ),
                            tableBorder: TableBorder.all(
                                color: textColor.withOpacity(0.3)),
                            tableColumnWidth: const IntrinsicColumnWidth(),
                            tableCellsPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            tableHeadAlign: TextAlign.center,
                            a: ChatFontHelper.apply(
                              chatFontFamily,
                              TextStyle(
                                  color: theme.colorScheme.primary,
                                  decoration: TextDecoration.underline),
                            ),
                            horizontalRuleDecoration: BoxDecoration(
                              border: Border(
                                  top: BorderSide(
                                      color: textColor.withOpacity(0.3),
                                      width: 1)),
                            ),
                          ),
                          builders: {
                            'code': CodeBlockBuilder(
                                theme: theme,
                                textColor: textColor,
                                baseFontSize: settings.chatFontSize),
                          },
                        ),
            ),
          ],
        );

    // Build the main message row (avatars hidden if avatarAbove or Hide pictures)
    final showSideAvatars = !hideAvatars && !avatarAbove;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhoneLayout = !isTabletClassLayout(context);
    final fullWidthAssistantBubble = avatarAbove && isPhoneLayout && !isUser;
    // Hide pictures should not stretch user pills to 95%. Keep the same
    // ~75% cap as side-avatar layout; only assistant can go wide.
    final bubbleMaxWidth = fullWidthAssistant
        ? double.infinity
        : ((!isUser && (hideAvatars || fullWidthAssistantBubble))
            ? screenWidth * 0.95
            : screenWidth * 0.75);

    final messageRow = Padding(
      padding: EdgeInsets.symmetric(
        vertical: wideThread ? (avatarAbove ? 0 : 12) : (avatarAbove ? 0 : 4),
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && showSideAvatars) ...[
            buildAssistantAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            fit: fullWidthAssistant ? FlexFit.tight : FlexFit.loose,
            child: _RevealOnTap(
              key: ValueKey('user-actions-${message.id}'),
              enabled: wideThread && isUser,
              builder: (context, userActionsRevealed, toggleUserActions) {
                return GestureDetector(
                  onTap: wideThread && isUser && !userActionsRevealed
                      ? toggleUserActions
                      : null,
                  behavior: wideThread && isUser && !userActionsRevealed
                      ? HitTestBehavior.opaque
                      : HitTestBehavior.deferToChild,
                  onHorizontalDragEnd: (details) {
                    if (!isUser &&
                        message.alternatives != null &&
                        message.alternatives!.isNotEmpty &&
                        onAlternativeSelected != null) {
                      final total = message.alternatives!.length + 1;
                      final currentIndex = message.alternativeIndex ??
                          message.alternatives!.length;
                      final velocity = details.primaryVelocity ?? 0;

                      if (velocity < -300) {
                        // Swipe left -> next alternative
                        if (currentIndex < total - 1) {
                          onAlternativeSelected!(currentIndex + 1);
                        }
                      } else if (velocity > 300) {
                        // Swipe right -> previous alternative
                        if (currentIndex > 0) {
                          onAlternativeSelected!(currentIndex - 1);
                        }
                      }
                    }
                  },
                  child: IgnorePointer(
                    ignoring: wideThread && isUser && !userActionsRevealed,
                    child: Container(
                      width: fullWidthAssistant ? double.infinity : null,
                      constraints: BoxConstraints(
                        maxWidth: bubbleMaxWidth,
                      ),
                      decoration: fullWidthAssistant
                          ? null
                          : BoxDecoration(
                              color: bubbleColor,
                              borderRadius: _bubbleBorderRadius(
                                  currentBubbleStyle, isUser),
                              border: (pColor != null && !isUser)
                                  ? Border(
                                      left: BorderSide(color: pColor, width: 3),
                                    )
                                  : null,
                            ),
                      padding: fullWidthAssistant
                          ? const EdgeInsets.fromLTRB(2, 2, 2, 6)
                          : _bubblePadding(currentBubbleStyle),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Participant name for group chats (skip if avatar-above shows it)
                          if (participantName != null &&
                              !isUser &&
                              !avatarAbove) ...[
                            Text(
                              participantName!,
                              style: GoogleFonts.poppins(
                                color: pColor ?? theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                height: 1.2,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          // Tool/MCP badges — shown inline with thinking row when thinking exists,
                          // or as a standalone row when there's no thinking content
                          if (toolMessages.isNotEmpty &&
                              !isUser &&
                              (thinking == null || thinking.isEmpty)) ...[
                            SelectionContainer.disabled(
                              child: _ToolBadgeRow(
                                toolMessages: toolMessages,
                                textColor: textColor,
                                theme: theme,
                                onShowToolDialog: (toolMsg) =>
                                    _showToolDialog(context, toolMsg, theme),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          // Display attached images
                          if (message.imageUrls != null &&
                              message.imageUrls!.isNotEmpty) ...[
                            ...message.imageUrls!.map((imageUrl) {
                              final isBase64 =
                                  imageUrl.startsWith('data:image');
                              final failedImage = Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.red.withOpacity(0.1),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.error,
                                        size: 16, color: Colors.red),
                                    const SizedBox(width: 4),
                                    Text(l10n.failedToLoadImage,
                                        style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              );
                              final imageWidget = isBase64
                                  ? Image.memory(
                                      _decodeBase64Image(imageUrl),
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                      errorBuilder: (_, __, ___) => failedImage,
                                    )
                                  : _storedChatImage(
                                      imageUrl,
                                      onError: failedImage,
                                    );

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => Scaffold(
                                          backgroundColor: Colors.black,
                                          body: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: InteractiveViewer(
                                                  panEnabled: true,
                                                  minScale: 0.5,
                                                  maxScale: 4.0,
                                                  clipBehavior: Clip.none,
                                                  child: Center(
                                                    child: isBase64
                                                        ? Image.memory(
                                                            _decodeBase64Image(
                                                                imageUrl))
                                                        : _storedChatImage(
                                                            imageUrl,
                                                            fit: BoxFit.contain,
                                                            onError: const Icon(
                                                              Icons
                                                                  .broken_image,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: MediaQuery.of(context)
                                                        .padding
                                                        .top +
                                                    8,
                                                left: 8,
                                                child: IconButton(
                                                  icon: const Icon(Icons.close,
                                                      color: Colors.white,
                                                      size: 30),
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: imageWidget,
                                  ),
                                ),
                              );
                            }),
                          ],
                          // Display file attachments as clickable links
                          if (message.fileAttachments != null &&
                              message.fileAttachments!.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: message.fileAttachments!.map((file) {
                                return _FileAttachmentChip(
                                  file: file,
                                  textColor: textColor,
                                  bubbleColor: bubbleColor,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (fullWidthAssistant && isStreaming)
                            FullWidthStreamingStatusHost(
                              fontSize: settings.chatFontSize,
                            ),
                          if (!(fullWidthAssistant && isStreaming && !hasText))
                            _SlideContent(
                              slideKey: message.alternativeIndex ??
                                  (message.alternatives?.length ?? 0),
                              child: buildMessageContent(),
                            ),
                          if (isStreaming && !fullWidthAssistant) ...[
                            const SizedBox(height: 4),
                            _TypingDots(color: textColor),
                          ],
                          if (!fullWidthAssistant && !wideThread) ...[
                            const SizedBox(height: 4),
                            // Timestamp row
                            Row(
                              children: [
                                Text(
                                  _formatTime(message.timestamp),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: (isUser
                                            ? theme.colorScheme.onPrimary
                                            : theme
                                                .colorScheme.onSurfaceVariant)
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (fullWidthAssistant && !isStreaming) ...[
                            const SizedBox(height: 16),
                            _WideThreadAssistantBar(
                              answer: answer,
                              textColor: textColor,
                              iconSize: settings.chatIconSize,
                              message: message,
                              isStreaming: isStreaming,
                              isLastAssistantMessage: isLastAssistantMessage,
                              onRegenerate: onRegenerate,
                              onEdit: onEdit == null || isStreaming
                                  ? null
                                  : () => _showEditDialog(context, isUser),
                              onBranch: onBranch == null || isStreaming
                                  ? null
                                  : onBranch,
                              onDelete: onDelete == null || isStreaming
                                  ? null
                                  : () => _confirmDelete(context),
                              onShareTranscript: _isTranscriptionMessage()
                                  ? () => _shareTranscript(context)
                                  : null,
                              onAlternativeSelected: onAlternativeSelected,
                              onMessageUpdated: onMessageUpdated,
                              showImageGen: settings.imageGenEnabled &&
                                  settings.isImageGenReady &&
                                  !isStreaming &&
                                  message.content.isNotEmpty &&
                                  onMessageUpdated != null,
                            ),
                          ] else if (!(wideThread && isUser) ||
                              userActionsRevealed) ...[
                            // Action buttons row
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: fullWidthAssistant
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.end,
                              children: [
                                if (!isUser &&
                                    ((message.alternatives?.length ?? 0) >
                                        0)) ...[
                                  _AlternativesNavigator(
                                    total: message.alternatives!.length + 1,
                                    currentIndex: message.alternativeIndex ??
                                        message.alternatives!.length,
                                    onSelect: onAlternativeSelected,
                                    textColor: textColor,
                                  ),
                                ],
                                if (assistantModelLabel != null &&
                                    !fullWidthAssistant) ...[
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, right: 10),
                                      child: Text(
                                        assistantModelLabel,
                                        textAlign: TextAlign.end,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme
                                              .colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.72),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                // Copy button for assistant messages
                                if (!isUser && message.content.isNotEmpty) ...[
                                  _CopyButton(
                                      content: answer,
                                      textColor: textColor,
                                      iconSize: settings.chatIconSize),
                                  const SizedBox(width: 12),
                                  if (_isTranscriptionMessage()) ...[
                                    Builder(
                                      builder: (shareContext) =>
                                          _ActionIconButton(
                                        icon: Icons.share_outlined,
                                        tooltip: l10n.shareTranscript,
                                        textColor: textColor,
                                        iconSize: settings.chatIconSize,
                                        onTap: () =>
                                            _shareTranscript(shareContext),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  _ReadAloudButton(
                                      content: answer,
                                      textColor: textColor,
                                      iconSize: settings.chatIconSize,
                                      message: message),
                                  const SizedBox(width: 12),
                                ],
                                // Regenerate button for the last assistant message
                                if (!isUser &&
                                    isLastAssistantMessage &&
                                    onRegenerate != null &&
                                    !isStreaming) ...[
                                  _ActionIconButton(
                                    icon: Icons.refresh,
                                    tooltip: l10n.regenerate,
                                    textColor: textColor,
                                    iconSize: settings.chatIconSize,
                                    onTap: onRegenerate!,
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                // Edit button
                                if (onEdit != null && !isStreaming) ...[
                                  _ActionIconButton(
                                    icon: Icons.edit_outlined,
                                    tooltip: l10n.edit,
                                    textColor: textColor,
                                    iconSize: settings.chatIconSize,
                                    onTap: () =>
                                        _showEditDialog(context, isUser),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                // Branch button (premium only — hidden for free users)
                                if (onBranch != null && !isStreaming) ...[
                                  _ActionIconButton(
                                    icon: Icons.account_tree_outlined,
                                    tooltip: l10n.branchFromHere,
                                    textColor: textColor,
                                    iconSize: settings.chatIconSize,
                                    onTap: onBranch!,
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                // Delete button
                                if (onDelete != null && !isStreaming) ...[
                                  _ActionIconButton(
                                    icon: Icons.delete_outline,
                                    tooltip: l10n.delete,
                                    textColor: textColor,
                                    iconSize: settings.chatIconSize,
                                    onTap: () => _confirmDelete(context),
                                  ),
                                ],
                                // Image generation button (icon-only, same style as other action icons)
                                if (settings.imageGenEnabled &&
                                    settings.isImageGenReady &&
                                    !isStreaming &&
                                    message.content.isNotEmpty &&
                                    onMessageUpdated != null) ...[
                                  const SizedBox(width: 12),
                                  ImageGenButton(
                                    message: message,
                                    onMessageUpdated: onMessageUpdated!,
                                    textColor: textColor,
                                  ),
                                ],
                              ],
                            ),
                          ],
                          // Generated image display (below the action row, not inside it)
                          if (message.hasGeneratedImages)
                            GeneratedImageDisplay(
                              imagePaths: message.allGeneratedImagePaths,
                            ),
                          if (!isUser &&
                              settings.showRuntimeInfo &&
                              isComfyGeneratedImageInfo(
                                  message.generatedImageInfo))
                            ComfyUiDetailsButton(
                              infoJson: message.generatedImageInfo!,
                              textColor: textColor,
                            ),
                          // Model info and runtime display
                          if (!isUser && settings.showRuntimeInfo) ...[
                            // Stats from v1 API
                            if (message.stats != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHigh
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.speed,
                                            size: 12,
                                            color: textColor.withValues(
                                                alpha: 0.7)),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.performanceStats,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: textColor.withValues(
                                                alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        if (message.stats!.tokensPerSecond !=
                                            null)
                                          _StatChip(
                                            label:
                                                '${message.stats!.tokensPerSecond!.toStringAsFixed(1)} t/s',
                                            icon: Icons.flash_on,
                                            color: textColor,
                                          ),
                                        if (message.stats!.inputTokens != null)
                                          _StatChip(
                                            label:
                                                '${message.stats!.inputTokens} in',
                                            icon: Icons.input,
                                            color: textColor,
                                          ),
                                        if (message.stats!.totalOutputTokens !=
                                            null)
                                          _StatChip(
                                            label:
                                                '${message.stats!.totalOutputTokens} out',
                                            icon: Icons.output,
                                            color: textColor,
                                          ),
                                        if (message.stats!
                                                    .reasoningOutputTokens !=
                                                null &&
                                            message.stats!
                                                    .reasoningOutputTokens! >
                                                0)
                                          _StatChip(
                                            label:
                                                '${message.stats!.reasoningOutputTokens} reasoning',
                                            icon: Icons.psychology,
                                            color: textColor,
                                          ),
                                        if (message.stats!
                                                    .timeToFirstTokenSeconds !=
                                                null ||
                                            message.stats!.timeToFirstToken !=
                                                null)
                                          _StatChip(
                                            label: message.stats!.formattedTTFT,
                                            icon: Icons.timer,
                                            color: textColor,
                                          ),
                                        if (message.stats!.totalTokens != null)
                                          _StatChip(
                                            label:
                                                '${message.stats!.totalTokens} total',
                                            icon: Icons.calculate,
                                            color: textColor,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ]
                            // Fallback: show legacy usage data when stats are not available
                            else if (message.usage != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHigh
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.speed,
                                            size: 12,
                                            color: textColor.withValues(
                                                alpha: 0.7)),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.performanceStats,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: textColor.withValues(
                                                alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        _StatChip(
                                          label:
                                              '${message.usage!.promptTokens} in',
                                          icon: Icons.input,
                                          color: textColor,
                                        ),
                                        _StatChip(
                                          label:
                                              '${message.usage!.completionTokens} out',
                                          icon: Icons.output,
                                          color: textColor,
                                        ),
                                        _StatChip(
                                          label:
                                              '${message.usage!.totalTokens} total',
                                          icon: Icons.calculate,
                                          color: textColor,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            // Legacy model/runtime info
                            if (message.modelInfo != null ||
                                message.runtimeInfo != null) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (message.modelInfo != null &&
                                      message.modelInfo!.displayInfo.isNotEmpty)
                                    _InfoChip(
                                      icon: Icons.memory,
                                      label: message.modelInfo!.displayInfo,
                                      color: textColor,
                                    ),
                                  if (message.runtimeInfo != null)
                                    _InfoChip(
                                      icon: Icons.developer_board,
                                      label: message.runtimeInfo!.displayName,
                                      color: textColor,
                                    ),
                                ],
                              ),
                            ],
                          ],
                          // Legacy token usage display (v0 API)
                          if (!isUser &&
                              message.usage != null &&
                              !settings.showRuntimeInfo) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${message.usage!.totalTokens} tokens (${message.usage!.promptTokens} + ${message.usage!.completionTokens})',
                              style: TextStyle(
                                fontSize: 9,
                                color: textColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                          // Memory extraction events — shown as chips with undo
                          if (!isUser)
                            _MemoryEventRow(
                                messageId: message.id, textColor: textColor),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isUser && showSideAvatars) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: avatarRadius,
              backgroundColor: theme.colorScheme.primary,
              backgroundImage: (userAvatarPath != null)
                  ? _resolveFileImage(userAvatarPath!)
                  : null,
              child: (userAvatarPath == null ||
                      _resolveFileImage(userAvatarPath!) == null)
                  ? Icon(
                      Icons.person,
                      size: avatarRadius * 0.6,
                      color: theme.colorScheme.onPrimary,
                    )
                  : null,
            ),
          ],
        ],
      ),
    );

    // Avatar-above layout: wrap messageRow in Column with avatar on top
    if (avatarAbove) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: wideThread ? 12 : 4),
        child: Column(
          crossAxisAlignment: fullWidthAssistant
              ? CrossAxisAlignment.stretch
              : (isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start),
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: isUser ? 0 : 4,
                right: isUser ? 4 : 0,
                bottom: 4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isUser) ...[
                    buildAssistantAvatar(),
                    if (participantName != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        participantName!,
                        style: GoogleFonts.poppins(
                          color: pColor ?? theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1.2,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ],
                  if (isUser) buildUserAvatar(),
                ],
              ),
            ),
            messageRow,
          ],
        ),
      );
    }

    return messageRow;
  }

  static BorderRadius _bubbleBorderRadius(BubbleStyle style, bool isUser) {
    switch (style) {
      case BubbleStyle.rounded:
        return BorderRadius.circular(16);
      case BubbleStyle.tail:
        // iOS-style with one sharp corner on the sender's side
        return BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft:
              isUser ? const Radius.circular(18) : const Radius.circular(4),
          bottomRight:
              isUser ? const Radius.circular(4) : const Radius.circular(18),
        );
      case BubbleStyle.flat:
        return BorderRadius.circular(4);
      case BubbleStyle.pill:
        return BorderRadius.circular(28);
    }
  }

  static EdgeInsets _bubblePadding(BubbleStyle style) {
    switch (style) {
      case BubbleStyle.rounded:
      case BubbleStyle.tail:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case BubbleStyle.flat:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case BubbleStyle.pill:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    }
  }

  static final Map<String, Uint8List> _imageCache = {};

  Uint8List _decodeBase64Image(String base64String) {
    if (_imageCache.containsKey(base64String)) {
      return _imageCache[base64String]!;
    }
    // Remove data:image/...;base64, prefix if present
    final base64Data =
        base64String.contains(',') ? base64String.split(',')[1] : base64String;
    final bytes = base64Decode(base64Data);

    // Prevent infinite growth
    if (_imageCache.length >= 20) {
      _imageCache.remove(_imageCache.keys.first);
    }
    _imageCache[base64String] = bytes;
    return bytes;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDurationClock(int ms) {
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showEditDialog(BuildContext context, bool isUser) {
    final l10n = AppLocalizations.of(context);
    final chatProvider = context.read<ChatProvider>();
    final mentionableParticipants =
        chatProvider.isGroupChat ? chatProvider.groupParticipants : null;
    final controller = TextEditingController(text: message.content);
    String? activeMentionQuery;
    final focusNode = FocusNode();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            void onMentionTextChanged() {
              if (mentionableParticipants == null ||
                  mentionableParticipants.isEmpty) {
                return;
              }
              final cursor = controller.selection.baseOffset;
              if (cursor < 0) {
                if (activeMentionQuery != null) {
                  setState(() => activeMentionQuery = null);
                }
                return;
              }
              final before = controller.text.substring(0, cursor);
              final match = RegExp(r'@(\w*)$').firstMatch(before);
              if (match != null) {
                final query = match.group(1)!;
                if (activeMentionQuery != query) {
                  setState(() => activeMentionQuery = query);
                }
              } else {
                if (activeMentionQuery != null) {
                  setState(() => activeMentionQuery = null);
                }
              }
            }

            void completeMention(String name) {
              final text = controller.text;
              final cursor = controller.selection.baseOffset;
              if (cursor < 0) return;
              final before = text.substring(0, cursor);
              final after = text.substring(cursor);
              final newBefore =
                  before.replaceFirst(RegExp(r'@\w*$'), '@$name ');
              controller.value = TextEditingValue(
                text: newBefore + after,
                selection: TextSelection.collapsed(offset: newBefore.length),
              );
              setState(() => activeMentionQuery = null);
              focusNode.requestFocus();
            }

            // Must attach listener on first build relative to lifecycle or safely re-attach
            controller.removeListener(onMentionTextChanged);
            controller.addListener(onMentionTextChanged);

            return AlertDialog(
              title: Row(
                children: [
                  Icon(isUser ? Icons.person : Icons.smart_toy, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.editMessage),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (activeMentionQuery != null)
                      ...(() {
                        final query = activeMentionQuery!.toLowerCase();
                        final filtered = mentionableParticipants!
                            .where((p) =>
                                p.displayName.toLowerCase().startsWith(query))
                            .toList();
                        if (filtered.isEmpty) return <Widget>[];
                        return [
                          Container(
                            constraints: const BoxConstraints(maxHeight: 150),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(ctx)
                                  .colorScheme
                                  .surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (c, i) {
                                final p = filtered[i];
                                final avatarBg = Color(p.color ?? 0xFFEEEEEE);
                                final isDark =
                                    avatarBg.computeLuminance() < 0.5;
                                return InkWell(
                                  onTap: () => completeMention(p.displayName),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: avatarBg,
                                          child: Text(
                                            p.displayName
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(p.displayName,
                                            style: Theme.of(ctx)
                                                .textTheme
                                                .bodyMedium),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        ];
                      })(),
                    Flexible(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        maxLines: null,
                        minLines: 3,
                        autofocus: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          hintText: l10n.editMessageHint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                // For user messages, offer "Save & Regenerate"
                if (isUser)
                  FilledButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text(l10n.saveAndRegenerate),
                    onPressed: () {
                      final newContent = controller.text.trim();
                      if (newContent.isNotEmpty) {
                        // Always regenerate — even if content unchanged
                        onEdit?.call(newContent, andRegenerate: true);
                      }
                      Navigator.pop(ctx);
                    },
                  ),
                FilledButton.tonal(
                  onPressed: () {
                    final newContent = controller.text.trim();
                    if (newContent.isNotEmpty &&
                        newContent != message.content) {
                      onEdit?.call(newContent, andRegenerate: false);
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteMessage),
        content: Text(l10n.deleteMessageConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              onDelete?.call();
              Navigator.pop(ctx);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showToolDialog(
      BuildContext context, ChatMessage toolMsg, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final isToolCall = toolMsg.content.startsWith('Tool call:');
    final isMcpCall = toolMsg.content.startsWith('MCP call:') ||
        toolMsg.content.startsWith('🔧 MCP call:');
    final isMcpResult = toolMsg.role == 'mcp' ||
        (toolMsg.role == 'tool' && toolMsg.content.startsWith('✅ MCP result'));

    String title;
    IconData icon;
    Color accentColor;
    if (isMcpCall) {
      title = l10n.mcpCallTitle;
      icon = Icons.dns;
      accentColor = theme.colorScheme.tertiary;
    } else if (isMcpResult) {
      title = l10n.mcpResultTitle;
      icon = Icons.dns_outlined;
      accentColor = theme.colorScheme.tertiary;
    } else if (isToolCall) {
      title = l10n.toolCallTitle;
      icon = Icons.build_circle;
      accentColor = theme.colorScheme.primary;
    } else {
      title = l10n.toolResultTitle;
      icon = Icons.data_object;
      accentColor = theme.colorScheme.primary;
    }

    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = screenWidth < 600 ? screenWidth * 0.92 : 500.0;

        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: (screenWidth - dialogWidth) / 2,
            vertical: 24,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.08),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 20, color: accentColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 20),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildToolDialogContent(
                      context,
                      toolMsg,
                      theme,
                      accentColor,
                      isToolCall: isToolCall,
                      isMcpCall: isMcpCall,
                      isMcpResult: isMcpResult,
                    ),
                  ),
                ),
                // Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: toolMsg.content));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.copiedToClipboard),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: Text(l10n.copy),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolDialogContent(
    BuildContext context,
    ChatMessage toolMsg,
    ThemeData theme,
    Color accentColor, {
    required bool isToolCall,
    required bool isMcpCall,
    required bool isMcpResult,
  }) {
    final content = toolMsg.content;

    // Parse MCP result: "✅ MCP result (tool-name): ..."
    if (isMcpResult) {
      return _buildMcpResultContent(context, content, theme, accentColor);
    }

    // Parse MCP call: "🔧 MCP call: tool@server" or "MCP call: tool@server({...})"
    if (isMcpCall) {
      return _buildMcpCallContent(context, content, theme, accentColor);
    }

    // Parse tool call: "Tool call: web_search({...})"
    if (isToolCall) {
      return _buildToolCallContent(context, content, theme, accentColor);
    }

    // Generic tool result
    return _buildGenericResultContent(context, content, theme, accentColor);
  }

  Widget _buildMcpResultContent(BuildContext context, String content,
      ThemeData theme, Color accentColor) {
    // Extract tool name and result body
    String toolName = '';
    String body = content;

    final headerMatch =
        RegExp(r'✅\s*MCP result \(([^)]+)\):\s*(.*)$', dotAll: true)
            .firstMatch(content);
    if (headerMatch != null) {
      toolName = headerMatch.group(1) ?? '';
      body = headerMatch.group(2) ?? content;
    }

    // Try to parse JSON content (often an array of {type, text} objects)
    List<Map<String, dynamic>>? jsonParts;
    try {
      final decoded = jsonDecode(body);
      if (decoded is List) {
        jsonParts = decoded.cast<Map<String, dynamic>>();
      }
    } catch (_) {
      // Not JSON, use as plain text
    }

    final searchText = jsonParts != null
        ? jsonParts
            .map((part) => part['text'] as String? ?? '')
            .where((t) => t.isNotEmpty)
            .join('\n')
        : body;
    final searchCards = _parseWebSearchResultCards(
      searchText.isEmpty ? body : searchText,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tool name badge
        if (toolName.isNotEmpty)
          _buildInfoChip(theme, Icons.check_circle, toolName, Colors.green),
        if (toolName.isNotEmpty) const SizedBox(height: 12),

        if (searchCards != null && searchCards.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < searchCards.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _buildSearchResultCard(theme, accentColor, searchCards[i]),
              ],
            ],
          )
        else if (jsonParts != null)
          ...jsonParts.map((part) {
            final text = part['text'] as String? ?? jsonEncode(part);
            return _buildFormattedTextBlock(theme, text);
          })
        else
          _buildFormattedTextBlock(theme, body),
      ],
    );
  }

  Widget _buildMcpCallContent(BuildContext context, String content,
      ThemeData theme, Color accentColor) {
    final l10n = AppLocalizations.of(context);
    String toolName = '';
    String serverName = '';
    String args = '';

    // Parse "🔧 MCP call: tool@server" or "MCP call: tool@server({...})"
    final match = RegExp(r'(?:🔧\s*)?MCP call:\s*(\S+?)@(\S+?)(?:\((.*)\))?$',
            dotAll: true)
        .firstMatch(content);
    if (match != null) {
      toolName = match.group(1) ?? '';
      serverName = match.group(2) ?? '';
      args = match.group(3) ?? '';
    }

    // Try to format JSON args
    String formattedArgs = args;
    try {
      if (args.isNotEmpty) {
        final decoded = jsonDecode(args);
        formattedArgs = const JsonEncoder.withIndent('  ').convert(decoded);
      }
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (toolName.isNotEmpty)
          _buildInfoChip(theme, Icons.build_circle, toolName, accentColor),
        if (serverName.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildInfoChip(theme, Icons.dns_outlined, serverName,
              theme.colorScheme.secondary),
        ],
        if (formattedArgs.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.arguments,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
            ),
            child: SelectableText(
              formattedArgs,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.85),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildToolCallContent(BuildContext context, String content,
      ThemeData theme, Color accentColor) {
    final l10n = AppLocalizations.of(context);
    String toolName = '';
    String args = '';

    final match = RegExp(r'Tool call:\s*(\w+)\((.*)\)$', dotAll: true)
        .firstMatch(content);
    if (match != null) {
      toolName = match.group(1) ?? '';
      args = match.group(2) ?? '';
    }

    String formattedArgs = args;
    try {
      if (args.isNotEmpty) {
        final decoded = jsonDecode(args);
        formattedArgs = const JsonEncoder.withIndent('  ').convert(decoded);
      }
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (toolName.isNotEmpty)
          _buildInfoChip(theme, Icons.build_circle, toolName, accentColor),
        if (formattedArgs.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.arguments,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
            ),
            child: SelectableText(
              formattedArgs,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.85),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGenericResultContent(BuildContext context, String content,
      ThemeData theme, Color accentColor) {
    final searxngCards = _parseWebSearchResultCards(content);
    if (searxngCards != null && searxngCards.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < searxngCards.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _buildSearchResultCard(theme, accentColor, searxngCards[i]),
          ],
        ],
      );
    }

    // Try to parse as JSON for nicer display
    String displayContent = content;
    try {
      final decoded = jsonDecode(content);
      displayContent = const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {}

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: SelectableText(
        displayContent,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: theme.colorScheme.onSurface.withOpacity(0.85),
        ),
      ),
    );
  }

  /// Parse SearXNG / numbered web search payloads into title/snippet/url cards.
  List<({String title, String snippet, String? url})>?
      _parseWebSearchResultCards(String content) {
    final parsed = WebSearchSources.parse(content);
    if (parsed.isEmpty) return null;
    return [
      for (final source in parsed)
        (title: source.title, snippet: source.snippet, url: source.url),
    ];
  }

  Widget _buildSearchResultCard(
    ThemeData theme,
    Color accentColor,
    ({String title, String snippet, String? url}) card,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (card.snippet.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              card.snippet,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: theme.colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
          ],
          if (card.url != null) ...[
            const SizedBox(height: 6),
            Text(
              card.url!,
              style: TextStyle(
                fontSize: 11,
                color: accentColor,
                decoration: TextDecoration.underline,
                decorationColor: accentColor.withOpacity(0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(
      ThemeData theme, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedTextBlock(ThemeData theme, String text) {
    // Parse structured text: look for sections like **Status:** or **Full Content:**
    final lines = text.split('\n');
    final widgets = <Widget>[];
    final buffer = StringBuffer();

    for (final line in lines) {
      // Detect section headers like "**Status:** ..." or "**Full Content:**"
      final sectionMatch =
          RegExp(r'^\*\*(.+?):\*\*\s*(.*)$').firstMatch(line.trim());
      if (sectionMatch != null) {
        // Flush previous buffer
        if (buffer.isNotEmpty) {
          widgets.add(_buildTextParagraph(theme, buffer.toString().trim()));
          buffer.clear();
        }
        final sectionTitle = sectionMatch.group(1) ?? '';
        final sectionValue = sectionMatch.group(2) ?? '';
        widgets.add(const SizedBox(height: 8));
        widgets.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$sectionTitle: ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (sectionValue.isNotEmpty)
                Expanded(
                  child: Text(
                    sectionValue,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
            ],
          ),
        );
      } else if (line.trim().startsWith('URL:')) {
        if (buffer.isNotEmpty) {
          widgets.add(_buildTextParagraph(theme, buffer.toString().trim()));
          buffer.clear();
        }
        widgets.add(const SizedBox(height: 4));
        widgets.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.link, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Expanded(
                child: SelectableText(
                  line
                      .trim()
                      .replaceFirst('URL: ', '')
                      .replaceFirst('URL:', ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        );
      } else if (RegExp(r'^\d+\.\s').hasMatch(line.trim())) {
        // Numbered list item like "1. CoinMarketCap ..."
        if (buffer.isNotEmpty) {
          widgets.add(_buildTextParagraph(theme, buffer.toString().trim()));
          buffer.clear();
        }
        final numMatch = RegExp(r'^(\d+)\.\s(.*)$').firstMatch(line.trim());
        if (numMatch != null) {
          widgets.add(const SizedBox(height: 8));
          widgets.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      numMatch.group(1)!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      numMatch.group(2)!,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        buffer.writeln(line);
      }
    }

    if (buffer.isNotEmpty) {
      widgets.add(_buildTextParagraph(theme, buffer.toString().trim()));
    }

    if (widgets.isEmpty) {
      widgets.add(_buildTextParagraph(theme, text));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildTextParagraph(ThemeData theme, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SelectableText(
        text,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withOpacity(0.85),
          height: 1.5,
        ),
      ),
    );
  }
}

/// Copy button widget with visual feedback
class _CopyButton extends StatefulWidget {
  final String content;
  final Color textColor;
  final double iconSize;

  const _CopyButton(
      {required this.content, required this.textColor, required this.iconSize});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.content));
    setState(() => _copied = true);

    // Reset after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copyToClipboard,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _copied ? Icons.check : Icons.copy,
          key: ValueKey(_copied),
          size: widget.iconSize,
          color:
              _copied ? Colors.green : widget.textColor.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

/// Read aloud button with TTS control
class _ReadAloudButton extends StatefulWidget {
  final String content;
  final Color textColor;
  final double iconSize;
  final ChatMessage message;

  const _ReadAloudButton({
    super.key,
    required this.content,
    required this.textColor,
    required this.iconSize,
    required this.message,
  });

  @override
  State<_ReadAloudButton> createState() => _ReadAloudButtonState();
}

enum _ReadAloudState { idle, preparing, speaking }

class _ReadAloudButtonState extends State<_ReadAloudButton> {
  final TtsService _tts = TtsService();
  _ReadAloudState _state = _ReadAloudState.idle;

  @override
  void initState() {
    super.initState();
    _tts.onComplete = _onTtsComplete;
    _tts.onCancel = _onTtsComplete;
  }

  void _onTtsComplete() {
    if (mounted) setState(() => _state = _ReadAloudState.idle);
  }

  void toggle() => _toggleReadAloud();

  void _toggleReadAloud() async {
    if (_state == _ReadAloudState.preparing ||
        _state == _ReadAloudState.speaking) {
      // Stop everything
      await _tts.stop();
      final kokoroTts = KokoroTtsService();
      await kokoroTts.stop();
      await RemoteKokoroTtsService().stop();
      await ElevenLabsTtsService().stop();
      await GrokTtsService().stop();
      setState(() => _state = _ReadAloudState.idle);
    } else {
      final settings = context.read<SettingsProvider>().settings;
      // Public builds have no cloud TTS: ElevenLabs / Grok fall back to native.
      final ttsProvider = TtsEngine.effective(settings.voiceTtsProvider);
      final chatProvider = context.read<ChatProvider>();
      final voice = KokoroSpeakerResolver.resolveVoiceForMessage(
        settings: settings,
        message: widget.message,
        conversation: chatProvider.currentConversation,
      );
      setState(() => _state = _ReadAloudState.preparing);

      // Strip thinking/reasoning and hidden tags — only read the answer aloud
      final parsed = ResponseParser.parse(widget.content);
      final textToRead = ResponseParser.cleanForTts(parsed.answer);
      if (textToRead.trim().isEmpty) {
        setState(() => _state = _ReadAloudState.idle);
        return;
      }

      if (ttsProvider == 'kokoro_remote') {
        final remoteTts = RemoteKokoroTtsService();
        final ok = await remoteTts.initialize(
          serverUrl: settings.effectiveVoiceRemoteKokoroUrl,
          authToken: settings.voiceRemoteKokoroHeaders?['X-LM-Mini-Token'],
          language: settings.locale ?? settings.voiceSttLanguage,
        );
        if (ok) {
          remoteTts.setSpeakerId(voice.speakerId);
          remoteTts.setSpeed(voice.speed);
          remoteTts.onComplete = _onTtsComplete;
          remoteTts.onPlaybackStart = () {
            if (mounted && _state == _ReadAloudState.preparing) {
              setState(() => _state = _ReadAloudState.speaking);
            }
          };
          remoteTts.startStreaming();
          remoteTts.feedText(textToRead);
          remoteTts.finishStreaming();
        } else {
          // Remote not available, fall back to native
          if (mounted) setState(() => _state = _ReadAloudState.speaking);
          await _tts.initialize();
          await _tts.setSpeechRate(settings.voiceSpeechRate);
          await _tts.setPitch(settings.voicePitch);
          await _tts.setLanguage(settings.voiceLanguage);
          if (settings.voiceName != null) {
            await _tts.setVoice(settings.voiceName);
          }
          await _tts.speak(textToRead);
        }
      } else if (ttsProvider == 'kokoro') {
        final kokoroTts = KokoroTtsService();
        final ok = await kokoroTts.initialize(
          language: settings.locale ?? settings.voiceSttLanguage,
        );
        if (ok) {
          kokoroTts.setSpeakerId(voice.speakerId);
          kokoroTts.setSpeed(voice.speed);
          kokoroTts.onComplete = _onTtsComplete;
          kokoroTts.onPlaybackStart = () {
            if (mounted && _state == _ReadAloudState.preparing) {
              setState(() => _state = _ReadAloudState.speaking);
            }
          };
          // Use streaming for faster first-sentence playback
          kokoroTts.startStreaming();
          kokoroTts.feedText(textToRead);
          kokoroTts.finishStreaming();
        } else {
          // Kokoro not ready, fall back to native
          if (mounted) setState(() => _state = _ReadAloudState.speaking);
          await _tts.initialize();
          await _tts.setSpeechRate(settings.voiceSpeechRate);
          await _tts.setPitch(settings.voicePitch);
          await _tts.setLanguage(settings.voiceLanguage);
          if (settings.voiceName != null) {
            await _tts.setVoice(settings.voiceName);
          }
          await _tts.speak(textToRead);
        }
      } else if (ttsProvider == TtsEngine.elevenLabs) {
        final elTts = ElevenLabsTtsService();
        final ok = await elTts.initialize(
          apiKey: settings.voiceElevenLabsApiKey,
          voiceId: ElevenLabsVoiceResolver.resolveVoiceIdForMessage(
            settings: settings,
            message: widget.message,
            conversation: chatProvider.currentConversation,
          ),
          modelId: settings.voiceElevenLabsModelId,
          speed: voice.speed,
        );
        if (ok) {
          elTts.onComplete = _onTtsComplete;
          elTts.onPlaybackStart = () {
            if (mounted && _state == _ReadAloudState.preparing) {
              setState(() => _state = _ReadAloudState.speaking);
            }
          };
          elTts.startStreaming();
          elTts.feedText(textToRead);
          elTts.finishStreaming();
        } else {
          if (mounted) setState(() => _state = _ReadAloudState.speaking);
          await _tts.initialize();
          await _tts.setSpeechRate(settings.voiceSpeechRate);
          await _tts.setPitch(settings.voicePitch);
          await _tts.setLanguage(settings.voiceLanguage);
          if (settings.voiceName != null) {
            await _tts.setVoice(settings.voiceName);
          }
          await _tts.speak(textToRead);
        }
      } else if (ttsProvider == TtsEngine.grok) {
        final grokTts = GrokTtsService();
        final ok = await grokTts.initialize(
          apiKey: settings.voiceGrokApiKey,
          voiceId: GrokVoiceResolver.resolveVoiceIdForMessage(
            settings: settings,
            message: widget.message,
            conversation: chatProvider.currentConversation,
          ),
          language: settings.locale ?? settings.voiceLanguage,
          speed: voice.speed,
        );
        if (ok) {
          grokTts.onComplete = _onTtsComplete;
          grokTts.onPlaybackStart = () {
            if (mounted && _state == _ReadAloudState.preparing) {
              setState(() => _state = _ReadAloudState.speaking);
            }
          };
          grokTts.startStreaming();
          grokTts.feedText(textToRead);
          grokTts.finishStreaming();
        } else {
          if (mounted) setState(() => _state = _ReadAloudState.speaking);
          await _tts.initialize();
          await _tts.setSpeechRate(settings.voiceSpeechRate);
          await _tts.setPitch(settings.voicePitch);
          await _tts.setLanguage(settings.voiceLanguage);
          if (settings.voiceName != null) {
            await _tts.setVoice(settings.voiceName);
          }
          await _tts.speak(textToRead);
        }
      } else {
        // Native TTS — plays immediately
        if (mounted) setState(() => _state = _ReadAloudState.speaking);
        await _tts.initialize();
        await _tts.setSpeechRate(settings.voiceSpeechRate);
        await _tts.setPitch(settings.voicePitch);
        await _tts.setLanguage(settings.voiceLanguage);
        if (settings.voiceName != null) {
          await _tts.setVoice(settings.voiceName);
        }
        await _tts.speak(textToRead);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    switch (_state) {
      case _ReadAloudState.idle:
        icon = Icons.volume_up_outlined;
        color = widget.textColor.withValues(alpha: 0.7);
        break;
      case _ReadAloudState.preparing:
        icon = Icons.hourglass_top_rounded;
        color = Colors.orange;
        break;
      case _ReadAloudState.speaking:
        icon = Icons.stop_circle_outlined;
        color = Colors.orange;
        break;
    }
    return GestureDetector(
      onTap: _toggleReadAloud,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          icon,
          key: ValueKey(_state),
          size: widget.iconSize,
          color: color,
        ),
      ),
    );
  }
}

/// Small icon button matching the copy button style for the message footer row.
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color textColor;
  final double iconSize;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.textColor,
    required this.onTap,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Icon(
          icon,
          size: iconSize,
          color: textColor.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

/// Local tap-to-reveal for user-bubble actions in full-width layout.
class _RevealOnTap extends StatefulWidget {
  final bool enabled;
  final Widget Function(
    BuildContext context,
    bool revealed,
    VoidCallback toggle,
  ) builder;

  const _RevealOnTap({
    super.key,
    this.enabled = true,
    required this.builder,
  });

  @override
  State<_RevealOnTap> createState() => _RevealOnTapState();
}

class _RevealOnTapState extends State<_RevealOnTap> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.builder(context, true, () {});
    }
    return widget.builder(context, _revealed, () {
      if (_revealed) return;
      setState(() => _revealed = true);
    });
  }
}

/// Custom expansion tile for the thinking/reasoning section.
/// Brain icon sits next to the expand chevron on the right,
/// with the label text on the left.
class _ThinkingExpansionTile extends StatefulWidget {
  final Color textColor;
  final bool isThinkingOngoing;
  final String? thinkingLabel;
  final String? thinkingDuration;
  final List<Widget> children;
  final List<ChatMessage> toolMessages;
  final ThemeData theme;
  final void Function(ChatMessage)? onShowToolDialog;

  const _ThinkingExpansionTile({
    required this.textColor,
    required this.isThinkingOngoing,
    this.thinkingLabel,
    this.thinkingDuration,
    required this.children,
    this.toolMessages = const [],
    required this.theme,
    this.onShowToolDialog,
  });

  @override
  State<_ThinkingExpansionTile> createState() => _ThinkingExpansionTileState();
}

class _ThinkingExpansionTileState extends State<_ThinkingExpansionTile>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchSources = WebSearchSources.fromMessages(widget.toolMessages);
    final otherToolBadges = _otherToolMessages(widget.toolMessages);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.thinkingLabel != null)
                  Text(
                    widget.thinkingLabel!,
                    style: TextStyle(
                        color: widget.textColor.withOpacity(0.7), fontSize: 12),
                  ),
                if (widget.thinkingDuration != null) ...[
                  const SizedBox(width: 3),
                  Text(
                    widget.thinkingDuration!,
                    style: TextStyle(
                        color: widget.textColor.withOpacity(0.45),
                        fontSize: 11),
                  ),
                ],
                if (widget.isThinkingOngoing)
                  _TypingDots(color: widget.textColor),
                if (searchSources.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: SearchSourcePile(
                        sources: searchSources,
                        textColor: widget.textColor,
                        compact: true,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                if (otherToolBadges.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {},
                    child: _ToolBadgeRow(
                      toolMessages: widget.toolMessages,
                      textColor: widget.textColor,
                      theme: widget.theme,
                      onShowToolDialog: widget.onShowToolDialog,
                      compact: true,
                      showSearchPile: false,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                ThinkBrainIcon(
                    size: 16, color: widget.textColor.withOpacity(0.5)),
                const SizedBox(width: 6),
                RotationTransition(
                  turns: _rotation,
                  child: Icon(
                    Icons.expand_more,
                    size: 20,
                    color: widget.textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        ClipRect(
          child: AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.children,
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ),
      ],
    );
  }
}

/// Single compact chip for memory events — tap to see details + undo.
class _MemoryEventRow extends StatelessWidget {
  final String messageId;
  final Color textColor;

  const _MemoryEventRow({required this.messageId, required this.textColor});

  @override
  Widget build(BuildContext context) {
    final events = context.select<ChatProvider, List<MemoryEvent>>(
      (p) => p.memoryEventsFor(messageId),
    );
    if (events.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final count = events.length;
    final hasUpdates = events.any((e) => e.wasUpdate);
    // Character notes read as fiction, not as something learned about the user,
    // so they get their own colour and wording.
    final allLore = events.every((e) => e.scope == MemoryScope.lore);
    final badgeColor = allLore
        ? memoryScopeColor(MemoryScope.lore, theme.colorScheme)
        : theme.colorScheme.primary;
    final label = allLore
        ? '${l10n.memoryScopeLore} ($count)'
        : hasUpdates
            ? '${l10n.memoryUpdates} ($count)'
            : '${l10n.memorySaved} ($count)';

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: GestureDetector(
        onTap: () => _showMemoryDialog(context, theme, badgeColor),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                  allLore
                      ? memoryScopeIcon(MemoryScope.lore)
                      : Icons.psychology,
                  size: 14,
                  color: badgeColor.withOpacity(0.8)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: badgeColor.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  size: 14, color: badgeColor.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  void _showMemoryDialog(
      BuildContext context, ThemeData theme, Color badgeColor) {
    final provider = context.read<ChatProvider>();
    showDialog(
      context: context,
      builder: (ctx) => _MemoryEventsDialog(
        messageId: messageId,
        provider: provider,
        theme: theme,
        badgeColor: badgeColor,
      ),
    );
  }
}

class _MemoryEventsDialog extends StatefulWidget {
  final String messageId;
  final ChatProvider provider;
  final ThemeData theme;
  final Color badgeColor;

  const _MemoryEventsDialog({
    required this.messageId,
    required this.provider,
    required this.theme,
    required this.badgeColor,
  });

  @override
  State<_MemoryEventsDialog> createState() => _MemoryEventsDialogState();
}

class _MemoryEventsDialogState extends State<_MemoryEventsDialog> {
  late List<MemoryEvent> _events;

  @override
  void initState() {
    super.initState();
    _events = List.of(widget.provider.memoryEventsFor(widget.messageId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.psychology, color: widget.badgeColor),
          const SizedBox(width: 8),
          Text(l10n.memoryUpdates),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _events.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('All changes undone.', textAlign: TextAlign.center),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: _events.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final event = _events[i];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: Icon(
                      event.wasUpdate
                          ? Icons.edit_note
                          : Icons.add_circle_outline,
                      color: widget.badgeColor,
                      size: 20,
                    ),
                    title: Text(
                      event.fact,
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      event.wasUpdate
                          ? 'Updated · ${event.category}'
                          : 'Saved · ${event.category}',
                      style: TextStyle(
                          fontSize: 11,
                          color: widget.theme.colorScheme.onSurfaceVariant),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        await widget.provider
                            .undoMemoryEvent(widget.messageId, event);
                        setState(() {
                          _events = List.of(widget.provider
                              .memoryEventsFor(widget.messageId));
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 0),
                      ),
                      child: const Text('Undo', style: TextStyle(fontSize: 12)),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.done),
        ),
      ],
    );
  }
}

List<ChatMessage> _otherToolMessages(List<ChatMessage> toolMessages) {
  final searchSources = WebSearchSources.fromMessages(toolMessages);
  if (searchSources.isEmpty) return toolMessages;
  final consumed = <ChatMessage>{};
  for (var i = 0; i < toolMessages.length; i++) {
    final msg = toolMessages[i];
    final next = i + 1 < toolMessages.length ? toolMessages[i + 1] : null;
    if (WebSearchSources.isSearchCall(msg) &&
        next != null &&
        (next.role == 'tool' || next.role == 'mcp')) {
      consumed.add(msg);
      consumed.add(next);
      i++;
    } else if (WebSearchSources.isSearchResult(msg) &&
        !WebSearchSources.isSearchCall(msg)) {
      if (WebSearchSources.parse(msg.content).isNotEmpty) {
        consumed.add(msg);
      }
    }
  }
  return toolMessages.where((m) => !consumed.contains(m)).toList();
}

/// Reusable row of tool/MCP badges. Used both standalone (when no thinking)
/// and inline inside _ThinkingExpansionTile (when thinking is present).
class _ToolBadgeRow extends StatelessWidget {
  final List<ChatMessage> toolMessages;
  final Color textColor;
  final ThemeData theme;
  final void Function(ChatMessage)? onShowToolDialog;

  /// When true, uses smaller padding for inline use inside the thinking row.
  final bool compact;
  final bool showSearchPile;

  const _ToolBadgeRow({
    required this.toolMessages,
    required this.textColor,
    required this.theme,
    this.onShowToolDialog,
    this.compact = false,
    this.showSearchPile = true,
  });

  /// Result payload that follows a `Tool call:` / MCP call message.
  static String? _pairedToolResult(
      List<ChatMessage> toolMessages, ChatMessage toolCall) {
    final idx = toolMessages.indexOf(toolCall);
    if (idx < 0 || idx + 1 >= toolMessages.length) return null;
    final next = toolMessages[idx + 1];
    if (next.role == 'tool' || next.role == 'mcp') return next.content;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final searchSources = showSearchPile
        ? WebSearchSources.fromMessages(toolMessages)
        : const <WebSearchSource>[];
    final otherMessages = _otherToolMessages(toolMessages);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (searchSources.isNotEmpty)
          SearchSourcePile(
            sources: searchSources,
            textColor: textColor,
            compact: compact,
          ),
        ...otherMessages.map((toolMsg) {
          final isToolCall = toolMsg.content.startsWith('Tool call:');
          final isMcpCall = toolMsg.content.startsWith('MCP call:') ||
              toolMsg.content.startsWith('🔧 MCP call:');
          final isMcpResult = toolMsg.role == 'mcp' ||
              (toolMsg.role == 'tool' &&
                  toolMsg.content.startsWith('✅ MCP result'));

          IconData icon;
          String label;
          Color badgeColor;

          if (isMcpCall) {
            icon = Icons.dns;
            final mcpName = RegExp(r'(?:🔧\s*)?MCP call:\s*([A-Za-z0-9_-]+)')
                .firstMatch(toolMsg.content)
                ?.group(1);
            label = (mcpName != null && mcpName.isNotEmpty)
                ? mcpName
                : l10n.mcpBadge;
            badgeColor = theme.colorScheme.tertiary;
          } else if (isMcpResult) {
            icon = Icons.dns_outlined;
            final mcpName = RegExp(r'✅\s*MCP result \(([^)]+)\)')
                .firstMatch(toolMsg.content)
                ?.group(1);
            label = (mcpName != null && mcpName.isNotEmpty)
                ? mcpName
                : l10n.mcpResultBadge;
            badgeColor = theme.colorScheme.tertiary;
          } else if (isToolCall) {
            // Show specific icon/label for known tools
            final toolNameMatch =
                RegExp(r'Tool call:\s*(\w+)').firstMatch(toolMsg.content);
            final toolName = toolNameMatch?.group(1) ?? '';
            if (toolName == 'save_memory') {
              icon = Icons.psychology;
              label = l10n.memorySaved;
              badgeColor = theme.colorScheme.primary;
            } else if (toolName == 'web_search') {
              // Label from the paired tool result (historical), not live settings —
              // otherwise flipping Prefer SearXNG / Pro Search relabels old bubbles.
              final paired = _pairedToolResult(toolMessages, toolMsg);
              final isSearxng = paired != null &&
                  (paired.contains('SearXNG') ||
                      paired.contains('Powered by SearXNG'));
              icon = isSearxng ? Icons.travel_explore : Icons.bolt;
              label = isSearxng ? 'SearXNG' : l10n.proSearch;
              badgeColor = isSearxng ? textColor : theme.colorScheme.primary;
            } else if (toolName == 'read_url') {
              icon = Icons.article_outlined;
              label = l10n.readUrl;
              badgeColor = textColor;
            } else {
              icon = Icons.build_circle;
              label = l10n.toolBadge;
              badgeColor = textColor;
            }
          } else {
            icon = Icons.data_object;
            label = l10n.resultBadge;
            badgeColor = textColor;
          }

          final hPad = compact ? 7.0 : 8.0;
          final vPad = compact ? 3.0 : 4.0;

          return Padding(
            padding: const EdgeInsets.only(left: 4),
            child: InkWell(
              onTap: onShowToolDialog != null
                  ? () => onShowToolDialog!(toolMsg)
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: compact ? 12 : 14,
                        color: badgeColor.withOpacity(0.8)),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: compact ? 10 : 11,
                        color: badgeColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _TypingDots extends StatefulWidget {
  final Color color;

  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> {
  int _count = 0; // 0..3
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() {
        _count = (_count + 1) % 4; // 0..3
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _count; // 0..3 dots (empty when 0)
    return Text(dots, style: TextStyle(color: widget.color, fontSize: 12));
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9, color: color.withValues(alpha: 0.6)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: color.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// Custom code block builder with copy button and language label
class CodeBlockBuilder extends MarkdownElementBuilder {
  final ThemeData theme;
  final Color textColor;
  final double baseFontSize;

  CodeBlockBuilder(
      {required this.theme,
      required this.textColor,
      required this.baseFontSize});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // Only handle fenced code blocks (pre > code), not inline code
    if (element.tag != 'code') return null;

    // Check if this is inside a pre tag (code block vs inline code)
    final isCodeBlock = element.attributes['class'] != null ||
        element.textContent.contains('\n');

    if (!isCodeBlock) {
      // Return null to use default inline code styling
      return null;
    }

    final language =
        element.attributes['class']?.replaceFirst('language-', '') ?? '';
    final code = element.textContent.trim();

    return _CodeBlockWidget(
      code: code,
      language: language,
      theme: theme,
      textColor: textColor,
      baseFontSize: baseFontSize,
    );
  }
}

class _CodeBlockWidget extends StatefulWidget {
  final String code;
  final String language;
  final ThemeData theme;
  final Color textColor;
  final double baseFontSize;

  const _CodeBlockWidget({
    required this.code,
    required this.language,
    required this.theme,
    required this.textColor,
    required this.baseFontSize,
  });

  @override
  State<_CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<_CodeBlockWidget> {
  bool _copied = false;

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _shareCode(BuildContext anchorContext) async {
    await shareTextFromContext(
      anchorContext,
      widget.code,
      subject: widget.language.toLowerCase() == 'srt'
          ? 'Transcription subtitles'
          : 'Code',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = widget.theme.brightness == Brightness.dark;

    // Map common language aliases to highlight.js language names
    final languageMap = {
      'js': 'javascript',
      'ts': 'typescript',
      'py': 'python',
      'rb': 'ruby',
      'yml': 'yaml',
      'sh': 'bash',
      'shell': 'bash',
      'zsh': 'bash',
      'md': 'markdown',
      'objc': 'objectivec',
      'objective-c': 'objectivec',
    };

    final isSrt = widget.language.toLowerCase() == 'srt';
    final highlightLanguage = isSrt
        ? 'plaintext'
        : (languageMap[widget.language.toLowerCase()] ??
            widget.language.toLowerCase());

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF282C34) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with language and copy button
              SelectionContainer.disabled(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.shade200,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(7),
                      topRight: Radius.circular(7),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        widget.language.isNotEmpty
                            ? widget.language
                            : l10n.code,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.textColor.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (isSrt) ...[
                        Builder(
                          builder: (shareContext) => InkWell(
                            onTap: () => _shareCode(shareContext),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.share_outlined,
                                    size: 14,
                                    color: widget.textColor.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Share',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: widget.textColor.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      InkWell(
                        onTap: _copyCode,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _copied ? Icons.check : Icons.copy,
                                size: 14,
                                color: _copied
                                    ? Colors.green
                                    : widget.textColor.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _copied ? l10n.copied : l10n.copy,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _copied
                                      ? Colors.green
                                      : widget.textColor.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Code content — plain monospace for SRT; syntax highlight for code.
              if (isSrt)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    widget.code,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: widget.baseFontSize - 1,
                      height: 1.4,
                      color: isDark
                          ? const Color(0xFFABB2BF)
                          : const Color(0xFF383A42),
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: HighlightView(
                    widget.code,
                    language: highlightLanguage.isNotEmpty
                        ? highlightLanguage
                        : 'plaintext',
                    theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
                    padding: const EdgeInsets.all(12),
                    textStyle: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: widget.baseFontSize - 1,
                      height: 1.4,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collapsible bubble for tool calls and results
class _ToolMessageBubble extends StatefulWidget {
  final ChatMessage message;

  const _ToolMessageBubble({
    required this.message,
  });

  @override
  State<_ToolMessageBubble> createState() => _ToolMessageBubbleState();
}

class _ToolMessageBubbleState extends State<_ToolMessageBubble> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isToolCall = widget.message.content.startsWith('Tool call:');
    final isMcpCall = widget.message.content.startsWith('MCP call:') ||
        widget.message.content.startsWith('🔧 MCP call:');
    final isMcpResult = widget.message.role == 'mcp';

    // Extract tool info
    String toolName = '';
    String serverName = '';
    String toolContent = widget.message.content;

    if (isToolCall) {
      // Parse "Tool call: web_search({...})"
      final match = RegExp(r'Tool call: (\w+)\((.*)\)')
          .firstMatch(widget.message.content);
      if (match != null) {
        toolName = match.group(1) ?? '';
        toolContent = match.group(2) ?? '';
      }
    } else if (isMcpCall) {
      // Parse "MCP call: toolname@server({...})"
      final match = RegExp(r'MCP call: (\w+)@(\w+)\((.*)\)')
          .firstMatch(widget.message.content);
      if (match != null) {
        toolName = match.group(1) ?? '';
        serverName = match.group(2) ?? '';
        toolContent = match.group(3) ?? '';
      }
    }

    // Determine display info based on message type
    IconData icon;
    String label;
    Color iconColor;

    if (isMcpCall) {
      icon = Icons.dns;
      label = '🔌 MCP: $toolName ($serverName)';
      iconColor = theme.colorScheme.tertiary;
    } else if (isMcpResult) {
      icon = Icons.dns_outlined;
      label = '📡 MCP Result';
      iconColor = theme.colorScheme.tertiary;
    } else if (isToolCall) {
      icon = Icons.build_circle;
      label = '🔧 Tool: $toolName';
      iconColor = theme.colorScheme.primary;
    } else {
      icon = Icons.data_object;
      label = '📦 Tool Result';
      iconColor = theme.colorScheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (isMcpCall || isMcpResult)
                  ? theme.colorScheme.tertiary.withOpacity(0.3)
                  : theme.colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    icon,
                    size: 16,
                    color: iconColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    _isExpanded ? l10n.hideDetails : l10n.showDetails,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SelectableText(
                    toolContent,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A chip widget that displays file attachment info and opens file on tap
class _FileAttachmentChip extends StatelessWidget {
  final FileAttachment file;
  final Color textColor;
  final Color bubbleColor;

  const _FileAttachmentChip({
    required this.file,
    required this.textColor,
    required this.bubbleColor,
  });

  IconData _getFileIcon() {
    switch (file.type) {
      case FileAttachmentType.text:
        return Icons.description_outlined;
      case FileAttachmentType.csv:
        return Icons.table_chart_outlined;
      case FileAttachmentType.pdf:
        return Icons.picture_as_pdf_rounded;
      case FileAttachmentType.image:
        return Icons.image_outlined;
    }
  }

  /// Accent color for the type badge (readable on both light/dark bubbles).
  Color _typeAccent() {
    switch (file.type) {
      case FileAttachmentType.pdf:
        return const Color(0xFFFF6B6B);
      case FileAttachmentType.csv:
        return const Color(0xFF4ADE80);
      case FileAttachmentType.text:
        return const Color(0xFF60A5FA);
      case FileAttachmentType.image:
        return const Color(0xFFFBBF24);
    }
  }

  String _typeShortLabel() => file.extensionLabel;

  Future<void> _openFile(BuildContext context) async {
    try {
      final fileToOpen = File(file.filePath);
      if (await fileToOpen.exists()) {
        final type =
            file.type == FileAttachmentType.pdf ? 'application/pdf' : null;
        final result = await OpenFile.open(
          file.filePath,
          type: type,
        );
        if (result.type != ResultType.done && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.message.isNotEmpty
                    ? result.message
                    : 'Could not open file',
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File not found')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: $e')),
        );
      }
    }
  }

  void _showFilePreview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(_getFileIcon(), color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.fileName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${file.typeDisplayName} • ${file.fileSizeDisplay}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new),
                      tooltip: 'Open with external app',
                      onPressed: () => _openFile(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: FilePickerHelper.isExtractedTextPreviewable(
                          file.extractedText)
                      ? SelectableText(
                          file.extractedText!,
                          style: TextStyle(
                            fontFamily: file.type == FileAttachmentType.csv
                                ? 'monospace'
                                : null,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                file.type == FileAttachmentType.pdf
                                    ? Icons.picture_as_pdf
                                    : Icons.visibility_off,
                                size: 48,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                file.type == FileAttachmentType.pdf
                                    ? 'PDF preview not available in chat'
                                    : 'Preview not available',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                file.type == FileAttachmentType.pdf
                                    ? 'Open this PDF in another app to view it.'
                                    : 'Tap "Open with external app" to view this file',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(color: theme.colorScheme.outline),
                              ),
                              if (file.type == FileAttachmentType.pdf) ...[
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _openFile(context);
                                  },
                                  icon: const Icon(Icons.open_in_new),
                                  label: const Text('Open PDF'),
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _typeAccent();
    const onAccent = Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (file.type == FileAttachmentType.pdf) {
            _openFile(context);
          } else {
            _showFilePreview(context);
          }
        },
        onLongPress: file.type == FileAttachmentType.pdf
            ? () => _showFilePreview(context)
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 240,
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Type badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getFileIcon(), size: 16, color: onAccent),
                    Text(
                      _typeShortLabel(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: onAccent.withValues(alpha: 0.95),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.fileName,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.2,
                        color: textColor.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${file.typeDisplayName} · ${file.fileSizeDisplay}',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.2,
                        color: textColor.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.north_east_rounded,
                size: 16,
                color: textColor.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps changing content with a directional slide + fade transition whenever
/// [slideKey] changes (e.g. when the user switches between AI alternatives).
class _SlideContent extends StatefulWidget {
  final int slideKey;
  final Widget child;

  const _SlideContent({required this.slideKey, required this.child});

  @override
  State<_SlideContent> createState() => _SlideContentState();
}

class _SlideContentState extends State<_SlideContent> {
  bool _goingRight = true;

  @override
  void didUpdateWidget(_SlideContent old) {
    super.didUpdateWidget(old);
    if (old.slideKey != widget.slideKey) {
      _goingRight = widget.slideKey > old.slideKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        final isEntering = child.key is ValueKey<int> &&
            (child.key as ValueKey<int>).value == widget.slideKey;

        final enterOffset = Offset(_goingRight ? 1.0 : -1.0, 0.0);
        final exitOffset = Offset(_goingRight ? -1.0 : 1.0, 0.0);

        final slidePosition = Tween<Offset>(
          begin: isEntering ? enterOffset : exitOffset,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: isEntering ? Curves.easeOut : Curves.easeIn,
        ));

        return SlideTransition(
          position: slidePosition,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      layoutBuilder: (currentChild, previousChildren) => ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          alignment: Alignment.topLeft,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(widget.slideKey),
        child: widget.child,
      ),
    );
  }
}

class _AlternativesNavigator extends StatelessWidget {
  final int total;
  final int currentIndex;
  final void Function(int newIndex)? onSelect;
  final Color textColor;

  const _AlternativesNavigator({
    required this.total,
    required this.currentIndex,
    required this.onSelect,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (total <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (index) {
        return GestureDetector(
          onTap: () {
            if (onSelect != null) onSelect!(index);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3.0),
            width: 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == currentIndex
                  ? textColor
                  : textColor.withOpacity(0.5),
            ),
          ),
        );
      }),
    );
  }
}

/// Copy + overflow menu under full-width assistant replies.
class _WideThreadAssistantBar extends StatefulWidget {
  final String answer;
  final Color textColor;
  final double iconSize;
  final ChatMessage message;
  final bool isStreaming;
  final bool isLastAssistantMessage;
  final VoidCallback? onRegenerate;
  final VoidCallback? onEdit;
  final VoidCallback? onBranch;
  final VoidCallback? onDelete;
  final VoidCallback? onShareTranscript;
  final void Function(int newIndex)? onAlternativeSelected;
  final void Function(ChatMessage updated)? onMessageUpdated;
  final bool showImageGen;

  const _WideThreadAssistantBar({
    required this.answer,
    required this.textColor,
    required this.iconSize,
    required this.message,
    required this.isStreaming,
    required this.isLastAssistantMessage,
    this.onRegenerate,
    this.onEdit,
    this.onBranch,
    this.onDelete,
    this.onShareTranscript,
    this.onAlternativeSelected,
    this.onMessageUpdated,
    this.showImageGen = false,
  });

  @override
  State<_WideThreadAssistantBar> createState() =>
      _WideThreadAssistantBarState();
}

class _WideThreadAssistantBarState extends State<_WideThreadAssistantBar> {
  final _readAloudKey = GlobalKey<_ReadAloudButtonState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chatProvider = context.watch<ChatProvider>();
    final isGenerating = chatProvider.isImageGeneratingFor(widget.message.id);
    final iconColor = widget.textColor.withValues(alpha: 0.7);
    final hasCopy = widget.answer.isNotEmpty;
    final hasAlts = (widget.message.alternatives?.length ?? 0) > 0;

    final items = <GlassPopupMenuItem>[
      if (hasCopy)
        GlassPopupMenuItem(
          id: 'readAloud',
          label: l10n.readAloud,
          icon: Icons.volume_up_outlined,
        ),
      if (widget.onShareTranscript != null)
        GlassPopupMenuItem(
          id: 'share',
          label: l10n.shareTranscript,
          icon: Icons.share_outlined,
        ),
      if (widget.isLastAssistantMessage &&
          widget.onRegenerate != null &&
          !widget.isStreaming)
        GlassPopupMenuItem(
          id: 'regenerate',
          label: l10n.regenerate,
          icon: Icons.refresh,
        ),
      if (widget.onEdit != null)
        GlassPopupMenuItem(
          id: 'edit',
          label: l10n.edit,
          icon: Icons.edit_outlined,
        ),
      if (widget.onBranch != null)
        GlassPopupMenuItem(
          id: 'branch',
          label: l10n.branchFromHere,
          icon: Icons.account_tree_outlined,
        ),
      if (widget.showImageGen && !isGenerating)
        GlassPopupMenuItem(
          id: 'image',
          label: l10n.imageGeneration,
          icon: Icons.auto_awesome,
        ),
      if (widget.onDelete != null)
        GlassPopupMenuItem(
          id: 'delete',
          label: l10n.delete,
          icon: Icons.delete_outline,
          destructive: true,
        ),
    ];

    if (!hasCopy && !hasAlts && items.isEmpty && !isGenerating) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (hasAlts && widget.onAlternativeSelected != null) ...[
          _AlternativesNavigator(
            total: widget.message.alternatives!.length + 1,
            currentIndex: widget.message.alternativeIndex ??
                widget.message.alternatives!.length,
            onSelect: widget.onAlternativeSelected,
            textColor: widget.textColor,
          ),
          const SizedBox(width: 8),
        ],
        if (hasCopy) ...[
          _CopyButton(
            content: widget.answer,
            textColor: widget.textColor,
            iconSize: widget.iconSize,
          ),
          const SizedBox(width: 4),
        ],
        if (hasCopy)
          Offstage(
            offstage: true,
            child: _ReadAloudButton(
              key: _readAloudKey,
              content: widget.answer,
              textColor: widget.textColor,
              iconSize: widget.iconSize,
              message: widget.message,
            ),
          ),
        if (isGenerating && widget.onMessageUpdated != null) ...[
          ImageGenButton(
            message: widget.message,
            onMessageUpdated: widget.onMessageUpdated!,
            textColor: widget.textColor,
          ),
          const SizedBox(width: 4),
        ],
        if (items.isNotEmpty)
          GlassPopupMenuButton(
            tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
            menuWidth: 196,
            compact: true,
            preferAbove: widget.isLastAssistantMessage,
            offset: const Offset(0, 6),
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            items: items,
            onSelected: (id) {
              switch (id) {
                case 'readAloud':
                  _readAloudKey.currentState?.toggle();
                case 'share':
                  widget.onShareTranscript?.call();
                case 'regenerate':
                  widget.onRegenerate?.call();
                case 'edit':
                  widget.onEdit?.call();
                case 'branch':
                  widget.onBranch?.call();
                case 'delete':
                  widget.onDelete?.call();
                case 'image':
                  _generateImage();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.more_horiz_rounded,
                size: widget.iconSize + 4,
                color: iconColor,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _generateImage() async {
    if (widget.onMessageUpdated == null) return;
    final globalSettings = context.read<SettingsProvider>().settings;
    final chatProvider = context.read<ChatProvider>();
    final settings = chatProvider.settingsForImageGeneration(
      globalSettings,
      message: widget.message,
    );
    if (!settings.isImageGenReady) return;
    var prompt = (widget.message.imagePrompt != null &&
            widget.message.imagePrompt!.isNotEmpty)
        ? widget.message.imagePrompt!
        : widget.answer;
    if (prompt.trim().isEmpty) return;
    if (settings.imageGenReviewPrompt) {
      final edited = await showImagePromptReviewDialog(
        context,
        initialPrompt: prompt,
      );
      if (edited == null) return;
      if (!mounted) return;
      prompt = edited;
    }
    await chatProvider.generateImageForMessage(
      message: widget.message,
      baseSettings: globalSettings,
      prompt: prompt,
      settingsProvider: context.read<SettingsProvider>(),
    );
  }
}
