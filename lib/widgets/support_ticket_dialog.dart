import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lm_mini_premium/lm_mini_premium.dart';

import '../l10n/app_localizations.dart';
import '../models/feature_request.dart';
import '../screens/feature_request_detail_screen.dart';
import '../services/error_report_service.dart';
import '../services/feature_attachment_service.dart';
import '../services/feature_request_service.dart';
import '../utils/app_navigator.dart';
import '../utils/localhost_connection_error.dart';
import 'attachment_picker.dart';

/// Opens the Support / Feature Requests submit dialog, optionally prefilled
/// from an error (Bug Fix + attached log file).
class SupportTicketFlow {
  static DateTime? _lastUncaughtPrompt;
  static final Set<String> _inFlightErrorFingerprints = {};

  /// Show the ticket form. Returns true if a ticket was submitted.
  static Future<bool> open(
    BuildContext context, {
    FeatureRequestService? service,
    String? initialTitle,
    String? initialDescription,
    FeatureCategory initialCategory = FeatureCategory.newFeature,
    List<File> initialFiles = const [],
    VoidCallback? onSubmitted,
    bool fromError = false,
    String? errorFingerprint,
  }) async {
    if (!PremiumConfig.firebaseReady) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.supportUnavailable)),
        );
      }
      return false;
    }

    final ticketService = service ?? FeatureRequestService();
    final result = await showDialog<Object>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SupportTicketDialog(
        service: ticketService,
        initialTitle: initialTitle,
        initialDescription: initialDescription,
        initialCategory: initialCategory,
        initialFiles: initialFiles,
        fromError: fromError,
        errorFingerprint: errorFingerprint,
      ),
    );

    if (result is DuplicateOpenBugException) {
      if (context.mounted) {
        await _showExistingTicket(context, ticketService, result.existing);
      }
      return false;
    }
    if (result == true) {
      onSubmitted?.call();
      return true;
    }
    return false;
  }

  /// Write an error log and open a Bug Fix ticket with it attached.
  static Future<bool> openFromError(
    BuildContext context, {
    required String error,
    String? detail,
    String? stack,
    FeatureRequestService? service,
  }) async {
    final blob = [error, detail, stack].whereType<String>().join('\n');
    if (LocalhostConnectionError.matches(blob)) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.localhostConnectionHelp)),
        );
      }
      return false;
    }
    if (ErrorReportService.isIgnorable(blob)) {
      return false;
    }

    final svc = service ?? FeatureRequestService();
    final fingerprint = ErrorReportService.errorFingerprint(error);
    final title = ErrorReportService.suggestedTitle(error);

    if (fingerprint.isNotEmpty &&
        !_inFlightErrorFingerprints.add(fingerprint)) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.supportTicketAlreadySending)),
        );
      }
      return false;
    }

    try {
      FeatureRequest? existing;
      try {
        existing = await svc.findOpenDuplicateBug(
          fingerprint: fingerprint,
          title: title,
        );
      } catch (e) {
        debugPrint('⚠️ Duplicate bug check failed: $e');
      }

      if (!context.mounted) return false;

      if (existing != null) {
        _inFlightErrorFingerprints.remove(fingerprint);
        await _showExistingTicket(context, svc, existing);
        return false;
      }

      File? logFile;
      try {
        logFile = await ErrorReportService.instance.writeLogFile(
          error: error,
          detail: detail,
          stack: stack,
        );
      } catch (e) {
        debugPrint('⚠️ Could not write error log: $e');
      }

      if (!context.mounted) return false;
      final l10n = AppLocalizations.of(context);
      return open(
        context,
        service: svc,
        initialTitle: title,
        initialDescription: l10n.supportTicketPrefillDescription,
        initialCategory: FeatureCategory.bugFix,
        initialFiles: logFile != null ? [logFile] : const [],
        fromError: true,
        errorFingerprint: fingerprint,
      );
    } finally {
      _inFlightErrorFingerprints.remove(fingerprint);
    }
  }

  static Future<void> _showExistingTicket(
    BuildContext context,
    FeatureRequestService service,
    FeatureRequest existing,
  ) async {
    final l10n = AppLocalizations.of(context);
    final view = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.supportTicketAlreadyOpen),
        content: Text(
          existing.title,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.ok),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.supportTicketViewExisting),
          ),
        ],
      ),
    );
    if (view == true && context.mounted) {
      await _openTicketDetail(context, service, existing);
    }
  }

  static Future<void> _openTicketDetail(
    BuildContext context,
    FeatureRequestService service,
    FeatureRequest request,
  ) async {
    final userId = await service.getCurrentUserId();
    final isAdmin = await service.isAdmin;
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeatureRequestDetailScreen(
          request: request,
          currentUserId: userId,
          isAdmin: isAdmin,
          service: service,
        ),
      ),
    );
  }

  /// After an uncaught platform error in release builds, offer a snackbar
  /// so the user can file a ticket without a visible banner.
  static void scheduleUncaughtPrompt() {
    if (kDebugMode) return;
    final now = DateTime.now();
    if (_lastUncaughtPrompt != null &&
        now.difference(_lastUncaughtPrompt!) < const Duration(seconds: 30)) {
      return;
    }
    _lastUncaughtPrompt = now;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx == null) return;
      final last = ErrorReportService.instance.lastException;
      if (ErrorReportService.isIgnorable(last)) return;
      final l10n = AppLocalizations.of(ctx);
      final messenger = ScaffoldMessenger.maybeOf(ctx);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l10n.uncaughtErrorSnack),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: l10n.reportToSupport,
            onPressed: () {
              final error =
                  ErrorReportService.instance.lastException ?? 'Uncaught error';
              openFromError(
                ctx,
                error: error,
                stack: ErrorReportService.instance.lastStack,
              );
            },
          ),
        ),
      );
    });
  }
}

class _SupportTicketDialog extends StatefulWidget {
  final FeatureRequestService service;
  final String? initialTitle;
  final String? initialDescription;
  final FeatureCategory initialCategory;
  final List<File> initialFiles;
  final bool fromError;
  final String? errorFingerprint;

  const _SupportTicketDialog({
    required this.service,
    this.initialTitle,
    this.initialDescription,
    this.initialCategory = FeatureCategory.newFeature,
    this.initialFiles = const [],
    this.fromError = false,
    this.errorFingerprint,
  });

  @override
  State<_SupportTicketDialog> createState() => _SupportTicketDialogState();
}

class _SupportTicketDialogState extends State<_SupportTicketDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _nameController;
  late FeatureCategory _category;
  late List<File> _attachments;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialDescription ?? '');
    _nameController = TextEditingController();
    _category = widget.initialCategory;
    _attachments = List<File>.from(widget.initialFiles);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fillTitleAndDescription)),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      List<FeatureAttachment> uploaded = const [];
      if (_attachments.isNotEmpty) {
        uploaded = await FeatureAttachmentService.instance.upload(
          files: _attachments,
          folder: 'request_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      await widget.service.submitRequest(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        submitterName:
            _nameController.text.trim().isEmpty ? null : _nameController.text,
        attachments: uploaded,
        errorFingerprint: widget.fromError ? widget.errorFingerprint : null,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final thanks = widget.fromError
          ? l10n.supportTicketSubmitted
          : l10n.featureRequestSubmitted;
      Navigator.pop(context, true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(thanks),
          backgroundColor: Colors.green,
        ),
      );
    } on DuplicateOpenBugException catch (e) {
      if (!mounted) return;
      Navigator.pop(context, e);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        widget.fromError ? l10n.supportTicketTitle : l10n.submitFeatureRequest,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.titleRequired,
                hintText: l10n.titleHint,
                border: const OutlineInputBorder(),
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.descriptionRequired,
                hintText: l10n.descriptionHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FeatureCategory>(
              value: _category,
              decoration: InputDecoration(
                labelText: l10n.category,
                border: const OutlineInputBorder(),
              ),
              items: FeatureCategory.values
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat.displayName),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.yourNameOptional,
                hintText: l10n.leaveBlankAnonymous,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            AttachmentPicker(
              files: _attachments,
              onChanged: (next) => setState(() => _attachments = next),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.submit),
        ),
      ],
    );
  }
}
