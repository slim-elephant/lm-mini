// LM-MINI-PRO-STUB
import 'package:flutter/material.dart';

import '../../models/group_chat_participant.dart';

/// Open-source build: group chat setup is not included. Shows a short note
/// with a close action instead of the setup flow.
class GroupChatSetupScreen extends StatelessWidget {
  final String? folderId;
  final int? maxParticipants;

  /// When true, renders as a detail-pane panel (no route push/pop).
  final bool embedded;

  /// Called when the user dismisses setup in [embedded] mode.
  final VoidCallback? onDismiss;

  /// Called with the new conversation id after Start in [embedded] mode.
  final ValueChanged<String>? onCreated;

  const GroupChatSetupScreen({
    super.key,
    this.folderId,
    this.maxParticipants,
    this.embedded = false,
    this.onDismiss,
    this.onCreated,
  });

  void _close(BuildContext context) {
    final dismiss = onDismiss;
    if (dismiss != null) {
      dismiss();
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Group chat is available in the official LM Mini app.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _close(context),
              child: Text(MaterialLocalizations.of(context).closeButtonLabel),
            ),
          ],
        ),
      ),
    );
    if (embedded) return Material(type: MaterialType.transparency, child: body);
    return Scaffold(
      appBar: AppBar(
        leading: CloseButton(onPressed: () => _close(context)),
      ),
      body: SafeArea(child: body),
    );
  }
}

/// Open-source build: participant editing is not included.
Future<GroupChatParticipant?> showEditGroupParticipantSheet(
  BuildContext context, {
  required GroupChatParticipant participant,
}) async =>
    null;
