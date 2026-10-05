import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../utils/google_font_load_error.dart';
import '../utils/localhost_connection_error.dart';
import '../utils/model_not_found_error.dart';
import '../utils/output_token_limit_error.dart';
import '../utils/comfyui_prompt_error.dart';
import '../utils/image_gen_unreachable_error.dart';
import '../utils/host_inference_error.dart';
import '../utils/lms_http_error.dart';
import '../utils/chat_image_payload.dart';
import '../utils/chat_image_compress.dart';
import '../services/error_report_service.dart';
import 'support_ticket_dialog.dart';

/// Short error strip that keeps the UI usable; long dumps open in a dialog.
class CompactErrorBanner extends StatelessWidget {
  final String error;
  final String? errorDetail;
  final VoidCallback onDismiss;
  final List<Widget> extraActions;
  final VoidCallback? onAdjustMaxTokens;
  final VoidCallback? onOpenImageSettings;
  final VoidCallback? onCompressAndResend;
  final int? largeImageBytes;

  const CompactErrorBanner({
    super.key,
    required this.error,
    this.errorDetail,
    required this.onDismiss,
    this.extraActions = const [],
    this.onAdjustMaxTokens,
    this.onOpenImageSettings,
    this.onCompressAndResend,
    this.largeImageBytes,
  });

  static const _summaryMaxChars = 140;

  String get _fullText {
    final detail = errorDetail?.trim();
    if (detail == null || detail.isEmpty) return error;
    if (error.contains(detail)) return error;
    return '$error\n\n$detail';
  }

  String get _summary {
    final full = _fullText.trim();
    var head = full;
    final brace = head.indexOf('{');
    final bracket = head.indexOf('[');
    final jsonAt = [brace, bracket].where((i) => i >= 0).fold<int>(
          -1,
          (a, b) => a < 0 ? b : (b < a ? b : a),
        );
    if (jsonAt > 24) {
      head = head.substring(0, jsonAt).trimRight();
    }
    final nl = head.indexOf('\n');
    if (nl > 0) head = head.substring(0, nl).trimRight();
    if (head.length > _summaryMaxChars) {
      return '${head.substring(0, _summaryMaxChars - 1).trimRight()}…';
    }
    return head.isEmpty ? error : head;
  }

  bool get _needsDetails => _fullText.trim().length > _summary.length + 8;

  static String formatForDialog(String text) {
    final brace = text.indexOf('{');
    final bracket = text.indexOf('[');
    final starts = <int>[
      if (brace >= 0) brace,
      if (bracket >= 0) bracket,
    ];
    if (starts.isEmpty) return text;
    starts.sort();
    final idx = starts.first;
    final prefix = text.substring(0, idx).trimRight();
    final jsonPart = text.substring(idx).trim();
    try {
      final decoded = jsonDecode(jsonPart);
      final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
      return prefix.isEmpty ? pretty : '$prefix\n\n$pretty';
    } catch (_) {
      return text;
    }
  }

  static Future<void> showDetailsDialog(
    BuildContext context, {
    required String fullText,
    bool allowSupportTicket = true,
  }) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatted = formatForDialog(fullText);
    final cs = Theme.of(context).colorScheme;
    final showTicket = allowSupportTicket &&
        !ErrorReportService.isIgnorable(fullText) &&
        !fullText.contains(ChatImageCompress.failedUserMessage);

    return showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.bug_report_outlined, color: cs.error, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.showDetails,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.55,
              ),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: SelectableText(
                    formatted,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      fontFamily: 'monospace',
                      color: isDark
                          ? cs.onSurface.withValues(alpha: 0.9)
                          : cs.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: formatted));
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(l10n.copied),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(l10n.copy),
            ),
            if (showTicket)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  SupportTicketFlow.openFromError(
                    context,
                    error: fullText,
                  );
                },
                child: Text(l10n.reportToSupport),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.dismiss),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLocalhostSetup = LocalhostConnectionError.matches(_fullText);
    final isFontLoad = GoogleFontLoadError.matches(_fullText);
    final isMissingModel = ModelNotFoundError.matches(_fullText);
    final isOutputTokens = OutputTokenLimitError.matches(_fullText);
    final comfy = ComfyUiPromptError.parse(_fullText);
    final isComfyUi = comfy != null;
    final unreachable = ImageGenUnreachableError.parse(_fullText);
    final isImageUnreachable = unreachable != null;
    final isGgmlCrash = HostInferenceError.isGgmlScheduler(_fullText);
    final isTerminated = HostInferenceError.isTerminated(_fullText);
    final isDroppedBody = DroppedRequestBodyError.matches(_fullText);
    final isCompressFailed = error == ChatImageCompress.failedUserMessage ||
        _fullText.contains(ChatImageCompress.failedUserMessage);
    final hugeImageBytes =
        isTerminated && largeImageBytes != null && largeImageBytes! > 0
            ? largeImageBytes
            : null;
    final hideSupport = isLocalhostSetup ||
        isFontLoad ||
        isMissingModel ||
        isOutputTokens ||
        isComfyUi ||
        isImageUnreachable ||
        isGgmlCrash ||
        isTerminated ||
        isDroppedBody ||
        isCompressFailed ||
        ErrorReportService.isIgnorable(_fullText);
    final summary = _summaryFor(
      l10n,
      isLocalhostSetup: isLocalhostSetup,
      isMissingModel: isMissingModel,
      isOutputTokens: isOutputTokens,
      isGgmlCrash: isGgmlCrash,
      isTerminated: isTerminated,
      isDroppedBody: isDroppedBody,
      isCompressFailed: isCompressFailed,
      hugeImageBytes: hugeImageBytes,
      isComfyUi: isComfyUi,
      comfy: comfy,
      isImageUnreachable: isImageUnreachable,
      unreachable: unreachable,
    );
    final needsDetails = !isLocalhostSetup &&
        !isMissingModel &&
        !isOutputTokens &&
        !isGgmlCrash &&
        !isTerminated &&
        !isDroppedBody &&
        !isCompressFailed &&
        !(isComfyUi && comfy.isCheckpointSetup) &&
        !isImageUnreachable &&
        _needsDetails;
    final bannerColor = isDark
        ? const Color(0xFF3D1A1A)
        : Theme.of(context).colorScheme.errorContainer;
    final textColor = isDark
        ? const Color(0xFFFFB4AB)
        : Theme.of(context).colorScheme.onErrorContainer;
    final showTokenAction =
        (isOutputTokens || isGgmlCrash) && onAdjustMaxTokens != null;
    final showImageSettingsAction =
        (isComfyUi || isImageUnreachable) && onOpenImageSettings != null;
    final showCompressAction =
        hugeImageBytes != null && onCompressAndResend != null;

    return Material(
      color: bannerColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.error_outline,
                color: textColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary,
                    maxLines: isLocalhostSetup ||
                            isOutputTokens ||
                            isGgmlCrash ||
                            isTerminated ||
                            isDroppedBody ||
                            isCompressFailed ||
                            isComfyUi ||
                            isImageUnreachable
                        ? 8
                        : 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  if (needsDetails) ...[
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () => showDetailsDialog(
                        context,
                        fullText: _fullText,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: textColor,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: Icon(
                        Icons.open_in_new_rounded,
                        size: 14,
                        color: textColor.withValues(alpha: 0.85),
                      ),
                      label: Text(l10n.showDetails),
                    ),
                  ],
                  if (extraActions.isNotEmpty ||
                      !hideSupport ||
                      showTokenAction ||
                      showCompressAction ||
                      showImageSettingsAction) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ...extraActions,
                        if (showImageSettingsAction)
                          TextButton.icon(
                            onPressed: onOpenImageSettings,
                            style: TextButton.styleFrom(
                              foregroundColor: textColor,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            icon: Icon(
                              Icons.image_outlined,
                              size: 14,
                              color: textColor.withValues(alpha: 0.85),
                            ),
                            label: Text(l10n.openImageSettings),
                          ),
                        if (showCompressAction)
                          TextButton.icon(
                            onPressed: onCompressAndResend,
                            style: TextButton.styleFrom(
                              foregroundColor: textColor,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            icon: Icon(
                              Icons.compress_rounded,
                              size: 14,
                              color: textColor.withValues(alpha: 0.85),
                            ),
                            label: Text(l10n.compressAndResendImages),
                          ),
                        if (showTokenAction)
                          TextButton.icon(
                            onPressed: onAdjustMaxTokens,
                            style: TextButton.styleFrom(
                              foregroundColor: textColor,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            icon: Icon(
                              Icons.tune_rounded,
                              size: 14,
                              color: textColor.withValues(alpha: 0.85),
                            ),
                            label: Text(l10n.adjustMaxTokens),
                          ),
                        if (!hideSupport)
                          TextButton.icon(
                            onPressed: () => SupportTicketFlow.openFromError(
                              context,
                              error: error,
                              detail: errorDetail,
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: textColor,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            icon: Icon(
                              Icons.support_agent,
                              size: 14,
                              color: textColor.withValues(alpha: 0.85),
                            ),
                            label: Text(l10n.reportToSupport),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: textColor, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDismiss,
              tooltip: l10n.dismiss,
            ),
          ],
        ),
      ),
    );
  }

  String _summaryFor(
    AppLocalizations l10n, {
    required bool isLocalhostSetup,
    required bool isMissingModel,
    required bool isOutputTokens,
    required bool isGgmlCrash,
    required bool isTerminated,
    required bool isDroppedBody,
    required bool isCompressFailed,
    required int? hugeImageBytes,
    required bool isComfyUi,
    required ComfyUiPromptError? comfy,
    required bool isImageUnreachable,
    required ImageGenUnreachableError? unreachable,
  }) {
    if (isLocalhostSetup) return l10n.localhostConnectionHelp;
    if (isMissingModel) return l10n.modelMissingBody;
    if (isOutputTokens) return l10n.outputTokensExhaustedBody;
    if (isGgmlCrash) return l10n.ggmlSchedulerCrashBody;
    if (hugeImageBytes != null) {
      return l10n.generationTerminatedHugeImageBody(
        ChatImagePayload.formatBytes(hugeImageBytes),
      );
    }
    if (isTerminated) return l10n.generationTerminatedBody;
    if (isDroppedBody) return l10n.droppedChatBodyHelp;
    if (isCompressFailed) return l10n.imageCompressFailed;
    if (isComfyUi && comfy != null) return _comfySummary(l10n, comfy);
    if (isImageUnreachable && unreachable != null) {
      switch (unreachable.kind) {
        case ImageGenUnreachableKind.noUrl:
          return l10n.imageGenUnreachableNoUrlBody;
        case ImageGenUnreachableKind.wrongServer:
        case ImageGenUnreachableKind.noImage:
          return unreachable.userMessage;
        case ImageGenUnreachableKind.down:
          return unreachable.url.trim().isEmpty
              ? l10n.imageGenUnreachableNoUrlBody
              : l10n.imageGenUnreachableBody(
                  unreachable.providerLabel,
                  unreachable.url,
                );
      }
    }
    return _summary;
  }

  static String _comfySummary(AppLocalizations l10n, ComfyUiPromptError comfy) {
    final name = comfy.checkpointName?.trim() ?? '';
    return switch (comfy.kind) {
      ComfyUiPromptErrorKind.noCheckpoints => l10n.comfyUiNoCheckpointsBody,
      ComfyUiPromptErrorKind.noCheckpointSelected =>
        l10n.comfyUiNoCheckpointSelectedBody,
      ComfyUiPromptErrorKind.unknownCheckpoint => name.isEmpty
          ? l10n.comfyUiWorkflowRejectedBody
          : l10n.comfyUiUnknownCheckpointBody(name),
      ComfyUiPromptErrorKind.diffusionOnly => l10n.comfyUiDiffusionOnlyBody,
      ComfyUiPromptErrorKind.workflowRejected =>
        l10n.comfyUiWorkflowRejectedBody,
    };
  }
}
