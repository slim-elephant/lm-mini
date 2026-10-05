import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../models/transcription_job.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/transcribe_config_dialog.dart';
import '../screens/transcription_settings_screen.dart';
import '../services/transcription_service.dart';

/// Shared entry for starting a transcription chat from menu, cards, or shortcuts.
class TranscriptionLauncher {
  TranscriptionLauncher._();

  static Future<void> openTranscribeFlow(BuildContext context) async {
    // Capture navigator/providers before any sheet/dialog pops invalidate
    // a transient route context (e.g. Attach File bottom sheet).
    final navigator = Navigator.of(context);
    final chatProvider = context.read<ChatProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    final result = await TranscribeConfigDialog.show(context);
    if (result == null) return;

    final launchContext = navigator.context;
    if (!launchContext.mounted) return;
    await startTranscriptionFromFile(
      launchContext,
      result.path,
      options: result.options,
      chatProvider: chatProvider,
      settingsProvider: settingsProvider,
    );
  }

  static Future<void> startTranscriptionFromFile(
    BuildContext context,
    String sourcePath, {
    TranscriptionOptions? options,
    ChatProvider? chatProvider,
    SettingsProvider? settingsProvider,
  }) async {
    final chat = chatProvider ?? context.read<ChatProvider>();
    final settings = settingsProvider ?? context.read<SettingsProvider>();
    final service = TranscriptionService.instance;

    if (!await service.ensureWhisperReady()) {
      if (!context.mounted) return;
      final goSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Whisper model required'),
          content: const Text(
            'Download the Whisper speech model in Settings → Transcription '
            'before transcribing audio files.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
      if (goSettings == true && context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TranscriptionSettingsScreen(),
          ),
        );
      }
      return;
    }

    final prefsLang =
        settings.settings.voiceSttLanguage.split('-').first.toLowerCase();
    final opts = options ??
        TranscriptionOptions(
          includeTimestamps: true,
          timestampGranularity: 'phrase',
          language: prefsLang,
        );

    final job = await service.createJob(
      sourcePath: sourcePath,
      options: opts,
    );

    // Keep the current chat; only create a conversation if none is open.
    final convId = await chat.ensureTranscriptionConversation(
      jobId: job.id,
      suggestedTitle: 'Transcription: ${job.title}',
    );
    if (convId == null || !context.mounted) return;

    await chat.upsertTranscriptionJobMeta(
      jobId: job.id,
      title: job.title,
      audioPath: job.storedAudioPath ?? job.sourceAudioPath,
      options: job.options.toJson(),
      status: 'running',
    );

    final jobWithConv = job.copyWith(conversationId: convId);
    unawaited(service.runJob(
      job: jobWithConv,
      onPlaceholdersReady: (userMsg, assistantMsg) async {
        await chat.appendMessagesToCurrent([userMsg, assistantMsg]);
      },
      onUpdateAssistant: (id, content) async {
        final existing = _findMessage(chat, id);
        if (existing == null) return;
        await chat.updateMessageInPlace(
          ChatMessage(
            id: existing.id,
            role: existing.role,
            content: content,
            timestamp: existing.timestamp,
          ),
        );
      },
      onComplete: (id, display, patch) async {
        final plain = patch['transcriptionPlainText']?.toString() ?? '';
        final srt = patch['transcriptionSrtText']?.toString();
        final title =
            patch['transcriptionTitle']?.toString() ?? jobWithConv.title;
        final jobId =
            patch['transcriptionJobId']?.toString() ?? jobWithConv.id;
        final status =
            patch['transcriptionStatus']?.toString() ?? 'complete';
        final audioPath = patch['transcriptionAudioPath']?.toString() ??
            jobWithConv.storedAudioPath ??
            jobWithConv.sourceAudioPath;
        final optionsRaw = patch['transcriptionOptions'];
        final options = optionsRaw is Map
            ? Map<String, dynamic>.from(optionsRaw)
            : jobWithConv.options.toJson();
        final durationMs =
            (patch['transcriptionDurationMs'] as num?)?.toInt();

        await chat.appendTranscriptionResult(
          jobId: jobId,
          title: title,
          plainText: plain,
          srtText: srt,
          audioPath: audioPath,
          options: options,
          durationMs: durationMs,
          status: status,
        );

        final userMsg = _findMessage(chat, '${jobId}_user');
        if (userMsg != null) {
          await chat.updateMessageInPlace(
            userMsg.copyWith(content: 'Audio: $title'),
          );
        }

        final existing = _findMessage(chat, id);
        if (existing == null) return;
        await chat.updateMessageInPlace(
          ChatMessage(
            id: existing.id,
            role: existing.role,
            content: display,
            timestamp: existing.timestamp,
          ),
        );
      },
    ));
  }

  static ChatMessage? _findMessage(ChatProvider chatProvider, String id) {
    for (final m in chatProvider.currentMessages) {
      if (m.id == id) return m;
    }
    return null;
  }
}
