import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/feature_request.dart';
import '../utils/firebase_auth_session.dart';

/// Uploads photo/video/log attachments for feature requests and comments to
/// Firebase Storage and returns persistable [FeatureAttachment] records.
///
/// Enforces the same client-side limits the storage rules require:
///   - Images (image/*) : up to 10 MB each.
///   - Videos (video/*) : up to 200 MB each.
///   - Logs (text/plain, .log / .txt) : up to 1 MB each.
///   - Up to 3 attachments per request or per comment (enforced at the
///     call site / picker, but `validate()` also re-checks).
class FeatureAttachmentService {
  FeatureAttachmentService._();
  static final FeatureAttachmentService instance = FeatureAttachmentService._();

  static const int maxAttachments = 3;
  static const int maxImageBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxVideoBytes = 200 * 1024 * 1024; // 200 MB
  static const int maxLogBytes = 1 * 1024 * 1024; // 1 MB

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Validate a list of locally-picked files before upload. Returns `null`
  /// when the selection is OK; otherwise returns a user-facing error.
  String? validate(List<File> files) {
    if (files.length > maxAttachments) {
      return 'You can attach up to $maxAttachments files.';
    }
    for (final f in files) {
      final isVideo = isVideoPath(f.path);
      final isImage = isImagePath(f.path);
      final isLog = isLogPath(f.path);
      if (!isVideo && !isImage && !isLog) {
        return 'Only photos, videos, and log files are supported (${p.basename(f.path)}).';
      }
      final size = f.lengthSync();
      if (isImage && size > maxImageBytes) {
        return 'Photos must be 10 MB or smaller (${p.basename(f.path)}).';
      }
      if (isVideo && size > maxVideoBytes) {
        return 'Videos must be 200 MB or smaller (${p.basename(f.path)}).';
      }
      if (isLog && size > maxLogBytes) {
        return 'Log files must be 1 MB or smaller (${p.basename(f.path)}).';
      }
    }
    return null;
  }

  /// Upload [files] under `feature_requests/{uid}/{folder}/`. The [folder]
  /// is typically the requestId for request attachments or a generated
  /// `comment_<ts>` for comment attachments (comment ids only exist after
  /// the comment doc is written, so we upload first and reference the URL).
  Future<List<FeatureAttachment>> upload({
    required List<File> files,
    required String folder,
    void Function(int index, double progress)? onProgress,
  }) async {
    if (files.isEmpty) return const [];
    final user = await FirebaseAuthSession.ensureUser();
    final uid = user?.uid;
    if (uid == null) {
      throw StateError('You must be signed in to upload attachments.');
    }
    final error = validate(files);
    if (error != null) throw StateError(error);

    final results = <FeatureAttachment>[];
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final ext = p.extension(file.path).toLowerCase();
      final isVideo = isVideoPath(file.path);
      final contentType = _contentTypeFor(file.path);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final safeFolder = folder.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
      final filename = '${ts}_$i$ext';
      final storagePath = 'feature_requests/$uid/$safeFolder/$filename';
      final ref = _storage.ref(storagePath);
      try {
        final snap = await FirebaseAuthSession.withFreshToken(() async {
          final task = ref.putFile(
            file,
            SettableMetadata(contentType: contentType),
          );
          task.snapshotEvents.listen((event) {
            if (onProgress != null && event.totalBytes > 0) {
              onProgress(i, event.bytesTransferred / event.totalBytes);
            }
          }, onError: (_) {});
          return task;
        });
        // Logs stay admin-only: skip a public download token so the URL is
        // never stored on the (widely readable) ticket document.
        final url = isLogPath(file.path) ? '' : await snap.ref.getDownloadURL();
        results.add(FeatureAttachment(
          url: url,
          storagePath: storagePath,
          contentType: contentType,
          sizeBytes: snap.totalBytes,
        ));
      } catch (e) {
        debugPrint('❌ Attachment upload failed for ${file.path}: $e');
        rethrow;
      }
      // Mark videos for download UI by adjusting later — flag for log.
      if (isVideo) {
        debugPrint('📹 Uploaded video attachment ($contentType)');
      }
    }
    return results;
  }

  /// Authenticated download of a log. Storage rules allow this for app
  /// admins only; the UI must not call this for anyone else.
  Future<String> downloadLogText(FeatureAttachment a) async {
    if (!a.isLog) {
      throw StateError('Attachment is not a log file.');
    }
    final path = a.storagePath;
    if (path == null || path.isEmpty) {
      throw StateError('Log is missing a storage path.');
    }
    final bytes = await FirebaseAuthSession.withFreshToken(
        () => _storage.ref(path).getData(maxLogBytes));
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Log file was empty.');
    }
    return utf8.decode(bytes);
  }

  /// Best-effort deletion of a stored attachment. Swallows errors so a
  /// missing object does not block deleting the parent doc.
  Future<void> deleteAttachment(FeatureAttachment a) async {
    final path = a.storagePath;
    if (path == null || path.isEmpty) return;
    try {
      await FirebaseAuthSession.withFreshToken(
          () => _storage.ref(path).delete());
    } catch (e) {
      debugPrint('⚠️ Failed to delete attachment $path: $e');
    }
  }

  static bool isImagePath(String path) {
    final ext = p.extension(path).toLowerCase();
    return const {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.heif'}
        .contains(ext);
  }

  static bool isVideoPath(String path) {
    final ext = p.extension(path).toLowerCase();
    return const {'.mp4', '.mov', '.m4v', '.webm', '.avi', '.mkv'}
        .contains(ext);
  }

  static bool isLogPath(String path) {
    final ext = p.extension(path).toLowerCase();
    return ext == '.log' || ext == '.txt';
  }

  String _contentTypeFor(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
      case '.heif':
        return 'image/heic';
      case '.mp4':
      case '.m4v':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.webm':
        return 'video/webm';
      case '.avi':
        return 'video/x-msvideo';
      case '.mkv':
        return 'video/x-matroska';
      case '.log':
      case '.txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
