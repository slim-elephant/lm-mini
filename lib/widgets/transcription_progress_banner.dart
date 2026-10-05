import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transcription_job.dart';
import '../providers/chat_provider.dart';
import '../services/transcription_service.dart';

/// Shows live transcription progress above the chat message list.
class TranscriptionProgressBanner extends StatelessWidget {
  const TranscriptionProgressBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TranscriptionService.instance,
      builder: (context, _) {
        final chat = context.watch<ChatProvider>();
        final job = TranscriptionService.instance.activeJob;
        if (job == null ||
            job.status != TranscriptionJobStatus.running ||
            job.conversationId != chat.currentConversation?.id) {
          return const SizedBox.shrink();
        }
        final cs = Theme.of(context).colorScheme;
        return Material(
          color: cs.primaryContainer.withValues(alpha: 0.35),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        job.progressLabel ?? 'Transcribing…',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text('${(job.progress * 100).round()}%'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: job.progress),
              ],
            ),
          ),
        );
      },
    );
  }
}
