import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/chat_conversation.dart';
import '../models/group_chat_participant.dart';
import '../utils/image_picker_helper.dart';
import '../utils/persona_appearance.dart';
import '../utils/chat_title.dart';
import 'glass_popup_menu.dart';

class ConversationListItem extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(String) onRename;
  final VoidCallback? onMoveToFolder;
  final VoidCallback? onLongPress;
  final bool isBranch;
  final bool hasUnread;
  final bool isGenerating;
  final bool hasActiveCall;
  final String? globalAssistantAvatar;
  /// Used to show Persona avatar/color on 1:1 chats in the list.
  final AppSettings? appSettings;
  /// Narrow master pane (iPad/macOS split view) — tighter layout.
  final bool compact;
  /// Last assistant message preview (non-persona chats).
  final String? lastAssistantPreview;
  /// Generated chat title, or the parent's title when this row is a branch
  /// whose stored name is the first words of a message.
  final String listTitle;
  /// Multi-select mode: same row content + leading checkbox; no swipe/menu.
  final bool selectionMode;
  final bool isSelected;
  /// Subtle open feedback while the conversation is being loaded after tap.
  final bool isOpening;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
    this.onMoveToFolder,
    this.onLongPress,
    this.isBranch = false,
    this.hasUnread = false,
    this.isGenerating = false,
    this.hasActiveCall = false,
    this.globalAssistantAvatar,
    this.appSettings,
    this.compact = false,
    this.lastAssistantPreview,
    this.listTitle = '',
    this.selectionMode = false,
    this.isSelected = false,
    this.isOpening = false,
  });

  PersonaAppearance? get _personaLook {
    final settings = appSettings;
    if (settings == null) return null;
    return PersonaAppearance.resolve(
      settings: settings,
      conversationSettings: conversation.settings,
    );
  }

  /// Resolve the assistant avatar for this conversation.
  /// Per-chat override > persona > global setting > null (use fallback icon).
  String? get _assistantAvatar {
    final perChat = conversation.settings['assistantAvatar'] as String?;
    if (perChat != null && perChat.isNotEmpty) return perChat;
    final personaAvatar = _personaLook?.avatarPath;
    if (personaAvatar != null && personaAvatar.isNotEmpty) return personaAvatar;
    return globalAssistantAvatar;
  }

  Color? get _personaAccent {
    final c = _personaLook?.color;
    return c != null ? Color(c) : null;
  }

  bool get _isGroupChat => conversation.settings['isGroupChat'] == true;

  String? get _personaName {
    final settings = appSettings;
    if (settings == null) return null;
    final persona = PersonaAppearance.boundPersona(
      settings: settings,
      conversationSettings: conversation.settings,
    );
    final name = persona?.name.trim();
    if (name == null || name.isEmpty) return null;
    return name;
  }

  /// Primary line: persona name when bound, otherwise the generated title.
  String get _titleText {
    final persona = _personaName;
    if (persona != null && persona.isNotEmpty) return persona;
    if (listTitle.isNotEmpty) return listTitle;
    return 'New Chat';
  }

  String? get _groupParticipantNames {
    if (!_isGroupChat) return null;
    final raw = conversation.settings['participants'];
    if (raw is! List || raw.isEmpty) return null;
    final names = <String>[];
    for (final item in raw) {
      try {
        final p = item is GroupChatParticipant
            ? item
            : GroupChatParticipant.fromJson(
                Map<String, dynamic>.from(item as Map),
              );
        final n = p.displayName.trim();
        if (n.isNotEmpty) names.add(n);
      } catch (_) {
        if (item is Map && item['displayName'] != null) {
          final n = item['displayName'].toString().trim();
          if (n.isNotEmpty) names.add(n);
        }
      }
    }
    if (names.isEmpty) return null;
    return names.join(', ');
  }

  /// Secondary line: participants for groups, chat title for persona chats,
  /// else last AI preview. A chat with nothing to preview reads "New chat".
  String get _subtitleText {
    final fallback = 'New chat';
    if (_isGroupChat) {
      if (_groupParticipantNames != null) return _groupParticipantNames!;
      final preview = ChatTitle.displayLabel(lastAssistantPreview ?? '');
      return preview.isEmpty ? fallback : preview;
    }
    if (_personaName != null) {
      final t = listTitle;
      if (t.isEmpty || t == _personaName) {
        final preview = ChatTitle.homeSnippet(lastAssistantPreview ?? '');
        return preview.isEmpty ? fallback : preview;
      }
      return t;
    }
    final preview = ChatTitle.homeSnippet(lastAssistantPreview ?? '');
    if (preview.isNotEmpty) return preview;
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitle = _subtitleText;

    final row = Padding(
      padding: EdgeInsets.only(left: isBranch ? 16.0 : 0.0),
      child: InkWell(
        onTap: onTap,
        onLongPress: selectionMode ? null : onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            // Multi-select checkbox mode OR active conversation in split view.
            color: isSelected
                ? cs.primaryContainer.withValues(
                    alpha: selectionMode ? 0.35 : (isDark ? 0.45 : 0.55),
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 18,
              compact ? 12 : 16,
              compact ? 8 : 14,
              compact ? 12 : 16,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (selectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTap(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(width: compact ? 4 : 6),
                ],
                // Avatar — larger, centered in the row (padding tightened so
                // overall item height stays about the same).
                _buildAvatar(context, cs, isDark),
                SizedBox(width: compact ? 12 : 16),
                // Title + subtitle (persona name / last AI message)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isBranch) ...[
                            Icon(
                              Icons.alt_route,
                              size: 14,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              _titleText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: compact ? 15.5 : 16.5,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                height: 1.25,
                                letterSpacing: -0.1,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (hasActiveCall)
                        Text(
                          'In call',
                          style: GoogleFonts.poppins(
                            color: Colors.green.shade400,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        )
                      else if (isGenerating)
                        Text(
                          'Generating...',
                          style: GoogleFonts.poppins(
                            color: cs.primary,
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        )
                      else if (subtitle != null)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.62),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            height: 1.35,
                            letterSpacing: 0,
                          ),
                        ),
                    ],
                  ),
                ),
                // Timestamp on right side (hidden in compact split-view panes)
                if (!compact)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: isOpening
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                            ),
                          )
                        : Text(
                            _formatDateTime(conversation.updatedAt),
                            style: GoogleFonts.poppins(
                              color:
                                  cs.onSurfaceVariant.withValues(alpha: 0.45),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0,
                            ),
                          ),
                  )
                else if (isOpening)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.4,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                // Menu (hidden in selection mode)
                if (!selectionMode)
                  GlassPopupMenuButton(
                    tooltip:
                        MaterialLocalizations.of(context).moreButtonTooltip,
                    menuWidth: 210,
                    offset: const Offset(0, 6),
                    items: [
                      GlassPopupMenuItem(
                        id: 'rename',
                        label: l10n.rename,
                        icon: Icons.drive_file_rename_outline_rounded,
                      ),
                      if (onMoveToFolder != null)
                        GlassPopupMenuItem(
                          id: 'move',
                          label: l10n.moveToFolderPopup,
                          icon: Icons.folder_outlined,
                        ),
                      GlassPopupMenuItem(
                        id: 'delete',
                        label: l10n.delete,
                        icon: Icons.delete_outline_rounded,
                        destructive: true,
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'rename') {
                        onRename(conversation.title);
                      } else if (value == 'move' && onMoveToFolder != null) {
                        onMoveToFolder!();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 22,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selectionMode)
          row
        else
          Slidable(
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.32,
              children: [
                CustomSlidableAction(
                  onPressed: (_) => onRename(conversation.title),
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.edit_outlined,
                        color: Colors.white, size: 20),
                  ),
                ),
                CustomSlidableAction(
                  onPressed: (_) => onDelete(),
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            child: row,
          ),
        // Fading separator line
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 24),
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: cs.onSurface.withOpacity(0.12),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context, ColorScheme cs, bool isDark) {
    final radius = isBranch ? 20.0 : 26.0;
    final avatarPath = _assistantAvatar;
    final accent = _personaAccent;
    final fallbackBg = accent ??
        (isBranch
            ? cs.secondaryContainer
            : isDark
                ? cs.primaryContainer.withOpacity(0.6)
                : cs.primaryContainer);

    // Group chat: stacked participant avatars
    if (_isGroupChat) {
      return _buildGroupAvatar(cs, radius);
    }

    // Active call — green pulsing ring
    if (hasActiveCall) {
      return _AvatarContainer(
        radius: radius,
        ringColor: Colors.green,
        backgroundColor: avatarPath != null ? null : Colors.green,
        child: avatarPath != null
            ? _imageAvatar(avatarPath, radius)
            : Icon(Icons.phone_in_talk, size: radius - 4, color: Colors.white),
      );
    }

    // Generating — primary ring
    if (isGenerating) {
      return _AvatarContainer(
        radius: radius,
        ringColor: cs.primary,
        backgroundColor: avatarPath != null ? null : (accent ?? cs.primaryContainer),
        child: avatarPath != null
            ? _imageAvatar(avatarPath, radius)
            : Icon(Icons.auto_awesome,
                size: radius - 6,
                color: accent != null ? Colors.white : cs.onPrimaryContainer),
      );
    }

    // Unread — small badge dot
    if (hasUnread) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          _AvatarContainer(
            radius: radius,
            backgroundColor: avatarPath != null ? null : fallbackBg,
            child: avatarPath != null
                ? _imageAvatar(avatarPath, radius)
                : Icon(
                    isBranch ? Icons.alt_route : Icons.chat_bubble_outline,
                    size: radius - 6,
                    color: accent != null
                        ? Colors.white
                        : cs.onPrimaryContainer,
                  ),
          ),
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 1.5),
              ),
            ),
          ),
        ],
      );
    }

    // Default
    return _AvatarContainer(
      radius: radius,
      backgroundColor: avatarPath != null ? null : fallbackBg,
      child: avatarPath != null
          ? _imageAvatar(avatarPath, radius)
          : Icon(
              isBranch ? Icons.alt_route : Icons.chat_bubble_outline,
              size: radius - 6,
              color: accent != null
                  ? Colors.white
                  : (isBranch
                      ? cs.onSecondaryContainer
                      : cs.onPrimaryContainer),
            ),
    );
  }

  Widget _imageAvatar(String path, double radius) {
    final resolved = ImagePickerHelper.resolveImagePathSync(path);
    if (resolved == null) {
      return Icon(Icons.chat_bubble_outline, size: radius - 6);
    }
    return ClipOval(
      child: Image.file(
        File(resolved),
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.chat_bubble_outline, size: radius - 6),
      ),
    );
  }

  Widget _buildGroupAvatar(ColorScheme cs, double radius) {
    final participantsJson = conversation.settings['participants'] as List?;
    if (participantsJson == null || participantsJson.isEmpty) {
      return _AvatarContainer(
        radius: radius,
        backgroundColor: cs.primaryContainer,
        child: Icon(Icons.group, size: radius - 4, color: cs.onPrimaryContainer),
      );
    }

    final participants = participantsJson.take(3).toList();
    final miniRadius = radius * 0.55;
    final totalSize = radius * 2;

    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < participants.length && i < 3; i++)
            Positioned(
              left: i * (miniRadius * 0.9),
              top: i == 1 ? 0 : miniRadius * 0.4,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 1.5),
                ),
                child: Builder(
                  builder: (_) {
                    final raw = participants[i];
                    final p = raw is Map
                        ? Map<String, dynamic>.from(raw)
                        : <String, dynamic>{};
                    final avatarPath = p['avatarPath'] as String?;
                    final resolved = avatarPath != null
                        ? ImagePickerHelper.resolveImagePathSync(avatarPath)
                        : null;
                    final colorVal = PersonaAppearance.parseColor(p['color']);
                    final pColor =
                        colorVal != null ? Color(colorVal) : cs.primary;
                    final name = p['displayName'] as String? ?? '?';
                    return CircleAvatar(
                      radius: miniRadius,
                      backgroundColor: pColor.withOpacity(0.2),
                      backgroundImage: resolved != null
                          ? FileImage(File(resolved))
                          : null,
                      child: resolved == null
                          ? Text(
                              name[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: miniRadius * 0.7,
                                fontWeight: FontWeight.bold,
                                color: pColor,
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

}

/// Container for the leading avatar with optional colored ring.
class _AvatarContainer extends StatelessWidget {
  final double radius;
  final Widget child;
  final Color? backgroundColor;
  final Color? ringColor;

  const _AvatarContainer({
    required this.radius,
    required this.child,
    this.backgroundColor,
    this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.transparent,
      child: child,
    );

    if (ringColor == null) return avatar;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor!, width: 2),
      ),
      child: avatar,
    );
  }
}
