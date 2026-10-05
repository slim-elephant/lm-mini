import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/error_report_service.dart';
import '../utils/host_inference_error.dart';
import '../utils/lms_http_error.dart';
import '../utils/localhost_connection_error.dart';
import 'support_ticket_dialog.dart';

/// Compact fallback when a widget subtree throws during build.
class CrashErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const CrashErrorWidget({super.key, required this.details});

  Future<void> _report(BuildContext context) {
    return SupportTicketFlow.openFromError(
      context,
      error: details.exceptionAsString(),
      stack: details.stack?.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFFFFB4AB);
    final exceptionText = details.exceptionAsString();
    final isLocalhost = LocalhostConnectionError.matches(exceptionText);
    final hideSupport = isLocalhost ||
        ErrorReportService.isIgnorable(exceptionText);
    String reportLabel = 'Send to support';
    String title = 'Something went wrong';
    String body = exceptionText;
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (l10n != null) {
      reportLabel = l10n.reportToSupport;
      title = l10n.somethingWentWrong;
      if (isLocalhost) {
        body = l10n.localhostConnectionHelp;
      } else if (HostInferenceError.isGgmlScheduler(exceptionText)) {
        body = l10n.ggmlSchedulerCrashBody;
      } else if (HostInferenceError.isTerminated(exceptionText)) {
        body = l10n.generationTerminatedBody;
      } else if (DroppedRequestBodyError.matches(exceptionText)) {
        body = l10n.droppedChatBodyHelp;
      }
    } else if (isLocalhost) {
      body = LocalhostConnectionError.userMessage;
    } else if (HostInferenceError.isGgmlScheduler(exceptionText)) {
      body = HostInferenceError.ggmlUserMessage;
    } else if (HostInferenceError.isTerminated(exceptionText)) {
      body = HostInferenceError.terminatedUserMessage;
    } else if (DroppedRequestBodyError.matches(exceptionText)) {
      body = DroppedRequestBodyError.userMessage;
    }

    return Material(
      color: const Color(0xFF3D1A1A),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tight = constraints.maxHeight < 88;
            if (tight) {
              if (hideSupport) {
                return const Icon(
                  Icons.error_outline,
                  color: ink,
                  size: 20,
                );
              }
              return IconButton(
                onPressed: () => _report(context),
                icon: const Icon(Icons.support_agent, color: ink, size: 20),
                tooltip: reportLabel,
              );
            }
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: ink, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    maxLines: isLocalhost ? 8 : 5,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.85),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                  if (!hideSupport) ...[
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => _report(context),
                      icon: const Icon(Icons.support_agent, size: 18),
                      label: Text(reportLabel),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
