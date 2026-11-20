import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A folder picked through the native iOS picker, still readable until
/// [MlxFolderImport.copyInto] or [MlxFolderImport.release] ends its access.
class PickedMlxFolder {
  final String token;
  final String name;
  final String? configJson;

  const PickedMlxFolder(this.token, this.name, this.configJson);
}

/// iOS MLX folder picker (ios/Runner/MlxFolderImport.swift). file_picker
/// returns a bare path for a picked folder, which iOS won't let the app read.
class MlxFolderImport {
  MlxFolderImport._();

  static const _channel = MethodChannel('lm_mini/mlx_folder_import');

  /// Null when the user cancels.
  static Future<PickedMlxFolder?> pick() async {
    final r = await _channel.invokeMapMethod<String, dynamic>('pick');
    if (r == null) return null;
    return PickedMlxFolder(
      r['token'] as String,
      r['name'] as String,
      r['config'] as String?,
    );
  }

  /// Copies the folder's model files into a fresh staging folder in the app
  /// and returns its path. The caller deletes it when done.
  static Future<String> copyInto(PickedMlxFolder folder) async {
    final tmp = await getTemporaryDirectory();
    final stage = p.join(
      tmp.path,
      'mlx-import',
      DateTime.now().microsecondsSinceEpoch.toString(),
      folder.name,
    );
    await _channel.invokeMethod<int>(
      'copy',
      {'token': folder.token, 'dest': stage},
    );
    return stage;
  }

  static Future<void> release(PickedMlxFolder folder) =>
      _channel.invokeMethod('release', {'token': folder.token});

  /// Removes the staging folder made by [copyInto].
  static Future<void> deleteStage(String stage) async {
    final batch = Directory(p.dirname(stage));
    if (await batch.exists()) await batch.delete(recursive: true);
  }
}
