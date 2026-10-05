import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;

import '../l10n/app_localizations.dart';
import 'media_type_utils.dart';

enum MediaSaveOutcome { saved, cancelled, failed }

/// Saves a file Mini already has. Phones write it into Photos. Desktop
/// opens a save dialog. Neither path needs library-read permission.
class MediaGallery {
  static bool get savesToPhotos =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  static Future<MediaSaveOutcome> save(String path) async {
    final file = File(path);
    if (!await file.exists()) return MediaSaveOutcome.failed;
    try {
      if (savesToPhotos) {
        if (!await Gal.hasAccess()) {
          final granted = await Gal.requestAccess();
          if (!granted) return MediaSaveOutcome.failed;
        }
        if (isVideoFilePath(path)) {
          await Gal.putVideo(path);
        } else {
          await Gal.putImage(path);
        }
        return MediaSaveOutcome.saved;
      }
      final savedPath = await FilePicker.platform.saveFile(
        fileName: p.basename(path),
      );
      if (savedPath == null) return MediaSaveOutcome.cancelled;
      if (savedPath != path) {
        await file.copy(savedPath);
      }
      return MediaSaveOutcome.saved;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Save media failed: $e\n$st');
      }
      return MediaSaveOutcome.failed;
    }
  }
}

Future<void> saveMediaToGallery(BuildContext context, String path) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final result = await MediaGallery.save(path);
  if (!context.mounted) return;
  if (result == MediaSaveOutcome.cancelled) return;
  final savedToPhotos = MediaGallery.savesToPhotos;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        result == MediaSaveOutcome.saved
            ? (savedToPhotos ? l10n.savedToPhotos : l10n.saved)
            : l10n.couldNotSaveToPhotos,
      ),
    ),
  );
}
