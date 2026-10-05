import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

import '../services/macos_media_permissions.dart';
import 'file_picker_helper.dart';
import 'file_picker_path_error.dart';

class ImagePickerHelper {
  /// Android gallery picks use the system photo picker, which does not
  /// need READ_MEDIA_IMAGES or READ_MEDIA_VIDEO.
  static void useSystemPhotoPicker() {
    if (kIsWeb || !Platform.isAndroid) return;
    final impl = ImagePickerPlatform.instance;
    if (impl is ImagePickerAndroid) {
      impl.useAndroidPhotoPicker = true;
    }
  }

  /// Drop the focused text field before a system picker. An open keyboard
  /// on iOS often cancels PHPicker and Flutter then restores focus, which
  /// scrolls the form back to the field and drops the chosen image.
  static Future<void> dismissKeyboardForPicker() async {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || !focus.hasFocus) return;
    focus.unfocus();
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  static Future<File?> pickFromGallery(BuildContext context) async {
    await dismissKeyboardForPicker();
    if (!context.mounted) return null;
    try {
      final picker = ImagePicker();
      XFile? picked;
      try {
        picked = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 90,
          requestFullMetadata: false,
        );
      } on PlatformException catch (e, st) {
        if (kDebugMode) {
          print('Photo library image pick error: $e\n$st');
        }
        if (e.code == 'invalid_image') {
          if (!context.mounted) return null;
          _showSnack(context,
              'This photo could not be loaded. Try choosing it from Files instead.');
          final fallback = await pickMultipleFromFiles(context);
          return fallback.isEmpty ? null : fallback.first;
        }
        rethrow;
      }
      if (picked == null) return null;
      return _copyToPermanentLocation(picked.path);
    } catch (e, st) {
      if (kDebugMode) {
        print('Image pick error: $e\n$st');
      }
      if (!context.mounted) return null;
      _showSnack(context, 'Could not open gallery.');
      return null;
    }
  }

  /// Pick one or more images from the photo library.
  ///
  /// [limit] must be `null` (unlimited) or ≥ 2 — [ImagePicker.pickMultipleMedia]
  /// rejects `limit: 1`. For a single image use [pickFromGallery].
  static Future<List<File>> pickMultipleFromGallery(
    BuildContext context, {
    int? limit,
  }) async {
    await dismissKeyboardForPicker();
    if (!context.mounted) return const [];
    if (limit != null && limit < 2) {
      final one = await pickFromGallery(context);
      return one == null ? const [] : [one];
    }
    try {
      final picker = ImagePicker();
      List<XFile> picked;
      try {
        picked = await picker.pickMultipleMedia(
          limit: limit,
          imageQuality: 90,
          requestFullMetadata: false,
        );
      } on PlatformException catch (e, st) {
        if (kDebugMode) {
          print('Photo library image pick error: $e\n$st');
        }
        if (e.code == 'invalid_image') {
          if (!context.mounted) return const [];
          _showSnack(context,
              'This photo could not be loaded. Try choosing it from Files instead.');
          final fallback = await pickMultipleFromFiles(context);
          return limit == null || fallback.length <= limit
              ? fallback
              : fallback.sublist(0, limit);
        }
        rethrow;
      }
      if (picked.isEmpty) return const [];

      final files = <File>[];
      for (final file in picked) {
        files.add(await _copyToPermanentLocation(file.path));
      }
      return files;
    } catch (e, st) {
      if (kDebugMode) {
        print('Image pick error: $e\n$st');
      }
      if (!context.mounted) return const [];
      _showSnack(context, 'Could not open gallery.');
      return const [];
    }
  }

  static Future<File?> captureFromCamera(BuildContext context) async {
    await dismissKeyboardForPicker();
    if (!context.mounted) return null;
    try {
      // Prefer native TCC on macOS; permission_handler has no macOS impl.
      final granted = await CameraCapturePermissions.ensureForCamera();
      if (!context.mounted) return null;
      if (!granted) {
        if (!kIsWeb && Platform.isMacOS) {
          await _showCameraPermissionDialog(context);
        } else {
          final status = await Permission.camera.status;
          if (!context.mounted) return null;
          if (status.isPermanentlyDenied) {
            await _showCameraPermissionDialog(context);
          } else {
            _showSnack(
                context, 'Camera permission is required to take photos.');
          }
        }
        return null;
      }

      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return null;

      return _copyToPermanentLocation(file.path);
    } catch (e, st) {
      if (kDebugMode) {
        print('Camera capture error: $e\n$st');
      }
      if (!context.mounted) return null;
      _showSnack(context, 'Could not open camera.');
      return null;
    }
  }

  /// Pick an image from the Files app (iOS) / file manager (Android)
  /// using the system document picker instead of the photo library.
  static Future<File?> pickFromFiles(BuildContext context) async {
    final files = await pickMultipleFromFiles(context);
    return files.isEmpty ? null : files.first;
  }

  /// Pick one or more images via the system file / document picker.
  static Future<List<File>> pickMultipleFromFiles(BuildContext context) async {
    await dismissKeyboardForPicker();
    if (!context.mounted) return const [];
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'webp',
          'heic',
          'heif',
          'bmp',
          'tiff',
        ],
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return const [];

      final files = <File>[];
      for (final pickedFile in result.files) {
        final source = await FilePickerHelper.resolveLocalPath(pickedFile);
        if (source == null) continue;
        files.add(await _copyToPermanentLocation(source));
      }
      if (files.isEmpty && context.mounted) {
        _showSnack(context, FilePickerPathError.userMessage);
      }
      return files;
    } catch (e, st) {
      if (kDebugMode) {
        print('File picker image error: $e\n$st');
      }
      if (!context.mounted) return const [];
      _showSnack(
        context,
        FilePickerPathError.matches(e)
            ? FilePickerPathError.userMessage
            : 'Could not open file picker.',
      );
      return const [];
    }
  }

  static Future<void> _showCameraPermissionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Camera Permission Needed'),
        content: Text(
          !kIsWeb && Platform.isMacOS
              ? 'Please allow camera access to take photos.\n\nGo to System Settings → Privacy & Security → Camera and enable access for LM Mini.'
              : 'Please allow camera access to take photos.\n\nGo to Settings > Privacy > Camera and enable access for this app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Copy image to permanent location and return a **relative** path
  /// (e.g. `images/1234567890.jpg`). This avoids iOS sandbox UUID changes
  /// between app updates breaking stored absolute paths.
  static Future<String> copyToPermanentLocation(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final extension = path.extension(sourcePath).isEmpty
        ? '.jpg'
        : path.extension(sourcePath);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
    final relativePath = 'images/$fileName';
    final permanentPath = path.join(appDir.path, relativePath);
    final permanentDir = Directory(path.dirname(permanentPath));
    if (!await permanentDir.exists()) {
      await permanentDir.create(recursive: true);
    }
    await File(sourcePath).copy(permanentPath);
    return relativePath;
  }

  /// Resolve a stored image path (relative or legacy absolute) to an
  /// absolute file path. Returns null if the file doesn't exist.
  static Future<String?> resolveImagePath(String? storedPath) async {
    if (storedPath == null || storedPath.isEmpty) return null;

    // Already absolute — check if file exists as-is
    if (path.isAbsolute(storedPath)) {
      if (await File(storedPath).exists()) return storedPath;
      // Try extracting the relative portion after "Documents/"
      const docsMarker = '/Documents/';
      final idx = storedPath.indexOf(docsMarker);
      if (idx != -1) {
        final relative = storedPath.substring(idx + docsMarker.length);
        final appDir = await getApplicationDocumentsDirectory();
        final resolved = path.join(appDir.path, relative);
        if (await File(resolved).exists()) return resolved;
      }
      return null;
    }

    // Relative path — resolve against current docs dir
    final appDir = await getApplicationDocumentsDirectory();
    final resolved = path.join(appDir.path, storedPath);
    if (await File(resolved).exists()) return resolved;
    return null;
  }

  /// Synchronous resolve (for use in build methods). Requires the docs
  /// directory path to have been cached first via [cacheDocsDir].
  static String? resolveImagePathSync(String? storedPath) {
    if (storedPath == null || storedPath.isEmpty || _cachedDocsDir == null)
      return null;

    if (path.isAbsolute(storedPath)) {
      if (File(storedPath).existsSync()) return storedPath;
      const docsMarker = '/Documents/';
      final idx = storedPath.indexOf(docsMarker);
      if (idx != -1) {
        final relative = storedPath.substring(idx + docsMarker.length);
        final resolved = path.join(_cachedDocsDir!, relative);
        if (File(resolved).existsSync()) return resolved;
      }
      return null;
    }

    final resolved = path.join(_cachedDocsDir!, storedPath);
    if (File(resolved).existsSync()) return resolved;
    return null;
  }

  static String? _cachedDocsDir;

  /// Cache the documents directory path on startup for sync resolution.
  static Future<void> cacheDocsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cachedDocsDir = appDir.path;
  }

  /// Convert a potentially absolute legacy path to a relative one.
  /// Returns the path unchanged if already relative.
  static String? toRelativePath(String? storedPath) {
    if (storedPath == null || storedPath.isEmpty) return storedPath;
    if (!path.isAbsolute(storedPath)) return storedPath;
    const docsMarker = '/Documents/';
    final idx = storedPath.indexOf(docsMarker);
    if (idx != -1) {
      return storedPath.substring(idx + docsMarker.length);
    }
    return storedPath;
  }

  /// Photo the Android activity dropped when the camera screen destroyed it.
  /// Empty on iOS and when the picker already delivered the file.
  static Future<List<File>> recoverLostImages() async {
    if (kIsWeb || !Platform.isAndroid) return const [];
    try {
      final response = await ImagePicker().retrieveLostData();
      if (response.isEmpty || response.type == RetrieveType.video) {
        return const [];
      }
      final picked = <XFile>[
        ...?response.files,
        if (response.file != null &&
            (response.files == null ||
                response.files!.every((f) => f.path != response.file!.path)))
          response.file!,
      ];
      if (picked.isEmpty) return const [];
      const imageExts = {
        '.png',
        '.jpg',
        '.jpeg',
        '.gif',
        '.webp',
        '.heic',
        '.bmp',
        '',
      };
      final files = <File>[];
      for (final item in picked) {
        final ext = path.extension(item.path).toLowerCase();
        if (!imageExts.contains(ext)) continue;
        files.add(await _copyToPermanentLocation(item.path));
      }
      return files;
    } catch (e) {
      if (kDebugMode) {
        print('Lost camera image recovery failed: $e');
      }
      return const [];
    }
  }

  // Keep old private method as wrapper for backward compat within this file
  static Future<File> _copyToPermanentLocation(String sourcePath) async {
    final relativePath = await copyToPermanentLocation(sourcePath);
    final appDir = await getApplicationDocumentsDirectory();
    return File(path.join(appDir.path, relativePath));
  }
}
