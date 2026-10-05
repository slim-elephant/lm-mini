import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../desktop/debug_log_buffer.dart';
import '../utils/client_platform.dart';
import '../utils/audio_session_busy_error.dart';
import '../utils/file_picker_path_error.dart';
import '../utils/google_font_load_error.dart';
import '../utils/localhost_connection_error.dart';
import '../utils/log_redaction.dart';
import '../utils/model_not_found_error.dart';
import '../utils/output_token_limit_error.dart';
import '../utils/comfyui_prompt_error.dart';
import '../utils/context_window_error.dart';
import '../utils/connect_host_error.dart';
import '../utils/firebase_firestore_error.dart';
import '../utils/firebase_storage_error.dart';
import '../utils/image_gen_unreachable_error.dart';
import '../utils/lms_mcp_error.dart';
import '../utils/server_unreachable_error.dart';
import '../utils/host_inference_error.dart';
import '../utils/lms_http_error.dart';

/// Captures uncaught errors and builds a plain-text log for support tickets.
class ErrorReportService {
  ErrorReportService._();
  static final ErrorReportService instance = ErrorReportService._();

  static const int maxLogChars = 80 * 1024;

  String? lastException;
  String? lastStack;
  DateTime? lastCapturedAt;

  /// Host / setup / transient errors that must not become Bug Fix tickets.
  static bool isIgnorable(Object? error) {
    return GoogleFontLoadError.matches(error) ||
        LocalhostConnectionError.matches(error) ||
        ServerUnreachableError.matches(error) ||
        AudioSessionBusyError.matches(error) ||
        ModelNotFoundError.matches(error) ||
        OutputTokenLimitError.matches(error) ||
        ComfyUiPromptError.matches(error) ||
        ContextWindowError.matches(error) ||
        ConnectHostError.matches(error) ||
        ImageGenUnreachableError.matches(error) ||
        FirebaseStorageError.matches(error) ||
        FirebaseFirestoreError.matches(error) ||
        FilePickerPathError.matches(error) ||
        LmsMcpError.matches(error) ||
        HostInferenceError.matches(error) ||
        DroppedRequestBodyError.matches(error);
  }

  void capture(
    Object error,
    StackTrace? stack, {
    String source = 'uncaught',
  }) {
    if (isIgnorable(error)) {
      debugPrint('⚠️ [$source] $error');
      return;
    }
    lastException = error.toString();
    lastStack = stack?.toString();
    lastCapturedAt = DateTime.now().toUtc();
    debugPrint('❌ [$source] $error');
    if (stack != null) debugPrint(stack.toString());
  }

  void captureFlutter(FlutterErrorDetails details) {
    if (isIgnorable(details.exception)) {
      debugPrint('⚠️ [flutter] ${details.exceptionAsString()}');
      return;
    }
    lastException = details.exceptionAsString();
    lastStack = details.stack?.toString();
    lastCapturedAt = DateTime.now().toUtc();
    if (details.silent) return;
    debugPrint('❌ [flutter] ${details.exceptionAsString()}');
  }

  /// Short title for a Bug Fix support ticket (max 100 chars).
  static String suggestedTitle(String error) {
    var s = error.trim();
    if (s.startsWith('Exception: ')) s = s.substring(11);
    final nl = s.indexOf('\n');
    if (nl > 0) s = s.substring(0, nl).trim();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    if (s.isEmpty) s = 'App error';
    if (!s.toLowerCase().startsWith('error')) {
      s = 'Error: $s';
    }
    if (s.length > 100) {
      s = '${s.substring(0, 99).trimRight()}…';
    }
    return s;
  }

  /// Stable key so the same crash (different port / IP / path) maps to one
  /// open bug ticket per user.
  static String errorFingerprint(String error) {
    var s = error.trim().toLowerCase();
    final nl = s.indexOf('\n');
    if (nl > 0) s = s.substring(0, nl);
    s = s.replaceFirst(RegExp(r'^error:\s*'), '');
    s = s.replaceFirst(RegExp(r'^exception:\s*'), '');
    s = s.replaceAll(RegExp(r'\b\d{1,3}(?:\.\d{1,3}){3}\b'), '<ip>');
    s = s.replaceAll(RegExp(r'\bport\s*=\s*\d+\b'), 'port=<n>');
    s = s.replaceAll(RegExp(r':\d{2,5}\b'), ':<port>');
    s = s.replaceAll(RegExp(r'\berrno\s*=\s*-?\d+\b'), 'errno=<n>');
    s = s.replaceAll(RegExp(r'\b0x[0-9a-f]+\b'), '<hex>');
    s = s.replaceAll(RegExp(r'/users/[^/\s]+'), '/users/<u>');
    s = s.replaceAll(RegExp(r'c:\\users\\[^\\\s]+'), r'c:\users\<u>');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.length > 220) s = s.substring(0, 220);
    return s;
  }

  /// Match a stored ticket to [incomingFingerprint] from a new error report.
  static bool looksLikeSameOpenBug({
    required String incomingFingerprint,
    String? storedFingerprint,
    required String ticketTitle,
    String? incomingTitle,
  }) {
    if (incomingFingerprint.isEmpty) return false;
    final stored = storedFingerprint?.trim();
    if (stored != null && stored.isNotEmpty) {
      return stored == incomingFingerprint;
    }
    if (errorFingerprint(ticketTitle) == incomingFingerprint) return true;
    final reported = incomingTitle?.trim();
    if (reported == null || reported.isEmpty) return false;
    return titlesLookLikeSameError(ticketTitle, reported);
  }

  static bool titlesLookLikeSameError(String a, String b) {
    final ta = a.trim();
    final tb = b.trim();
    if (ta.isEmpty || tb.isEmpty) return false;
    if (ta == tb) return true;
    if (errorFingerprint(ta) == errorFingerprint(tb)) return true;
    String clip(String s) => s.replaceAll('…', '').replaceAll('...', '').trim();
    final sa = clip(ta);
    final sb = clip(tb);
    if (sa.length < 24 || sb.length < 24) return false;
    return sa.startsWith(sb) || sb.startsWith(sa);
  }

  static String buildLogBody({
    required String error,
    String? detail,
    String? stack,
    List<String> recentLogs = const [],
    String platform = 'unknown',
    String appVersion = 'unknown',
    DateTime? time,
  }) {
    final header = StringBuffer()
      ..writeln('LM Mini error log')
      ..writeln('Time: ${(time ?? DateTime.now()).toUtc().toIso8601String()}')
      ..writeln('Platform: $platform')
      ..writeln('App version: $appVersion')
      ..writeln()
      ..writeln('--- Error ---')
      ..writeln(redactLogSecrets(error));

    final trimmedDetail = detail?.trim();
    if (trimmedDetail != null &&
        trimmedDetail.isNotEmpty &&
        trimmedDetail != error.trim()) {
      header
        ..writeln()
        ..writeln('--- Detail ---')
        ..writeln(redactLogSecrets(trimmedDetail));
    }

    final trimmedStack = stack?.trim();
    if (trimmedStack != null && trimmedStack.isNotEmpty) {
      header
        ..writeln()
        ..writeln('--- Stack ---')
        ..writeln(redactLogSecrets(trimmedStack));
    }

    header.writeln();
    header.writeln('--- Recent logs ---');
    final headerText = header.toString();
    final remaining = maxLogChars - headerText.length;
    if (remaining <= 32 || recentLogs.isEmpty) {
      if (recentLogs.isEmpty) {
        header.writeln('(none)');
      }
      var text = header.toString();
      if (text.length > maxLogChars) {
        text = '${text.substring(0, maxLogChars)}\n[truncated]';
      }
      return redactLogSecrets(text);
    }

    final logBlock = recentLogs.map(redactLogSecrets).join('\n');
    if (logBlock.length <= remaining) {
      return redactLogSecrets('$headerText$logBlock\n');
    }
    final sliced = logBlock.substring(logBlock.length - remaining);
    return redactLogSecrets('$headerText[truncated older logs]\n$sliced\n');
  }

  Future<File> writeLogFile({
    required String error,
    String? detail,
    String? stack,
    Directory? directory,
  }) async {
    final meta = await ClientPlatform.supportMetadata();
    final body = buildLogBody(
      error: error,
      detail: detail,
      stack: stack ?? lastStack,
      recentLogs: DebugLogBuffer.instance.lines,
      platform: meta['platform'] ?? ClientPlatform.storageKey,
      appVersion: meta['appVersion'] ?? 'unknown',
    );
    final dir = directory ?? await getTemporaryDirectory();
    final stamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File('${dir.path}/lm-mini-error-$stamp.log');
    await file.writeAsString(body);
    return file;
  }
}
