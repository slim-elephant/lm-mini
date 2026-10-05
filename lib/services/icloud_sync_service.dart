import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_kit/cloud_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import 'database_service.dart';

class ICloudSyncService {
  static final ICloudSyncService _instance = ICloudSyncService._internal();
  factory ICloudSyncService() => _instance;
  ICloudSyncService._internal();

  final CloudKit _cloudKit = CloudKit('iCloud.net.neuro9.lmmini');
  final DatabaseService _db = DatabaseService();

  // Separate locks so an in-progress syncUp does not silently cancel a
  // syncDown (and vice-versa). Previously a single `_isSyncing` flag meant
  // the periodic 60s syncDown was usually skipped whenever the 3-second
  // post-edit syncUp was still finishing — so new conversations created on
  // another device never appeared until the user quit and relaunched.
  bool _isSyncingUp = false;
  bool _isSyncingDown = false;
  Timer? _syncUpTimer;

  void scheduleSyncUp() {
    _syncUpTimer?.cancel();
    _syncUpTimer = Timer(const Duration(seconds: 3), () {
      syncUp();
    });
  }

  /// Drop a debounce armed before send so a 3s timer cannot fire mid-stream.
  void cancelPendingSyncUp() {
    _syncUpTimer?.cancel();
    _syncUpTimer = null;
  }

  Future<bool> get isEnabled async {
    if (!Platform.isIOS) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('icloud_sync_enabled') ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('icloud_sync_enabled', enabled);
    if (enabled) {
      await syncUp();
      await syncDown();
    }
  }

  /// Safely saves to CloudKit by deleting the existing key first if it exists.
  Future<void> _safeSave(String key, String value) async {
    try {
      await _cloudKit.save(key, value);
    } catch (e) {
      if (e.toString().contains('already exists')) {
        await _cloudKit.delete(key);
        await _cloudKit.save(key, value);
      } else {
        rethrow;
      }
    }
  }

  /// Pushes local database state up to iCloud CloudKit.
  Future<void> syncUp() async {
    if (!await isEnabled) return;
    if (_isSyncingUp) return;
    _isSyncingUp = true;
    debugPrint('☁️ iCloud Sync: Starting syncUp() to CloudKit...');

    try {
      final status = await _cloudKit.getAccountStatus();
      if (status != CloudKitAccountStatus.available) {
        debugPrint('☁️ iCloud Sync: Account not available, aborting syncUp.');
        return;
      }

      final allConvos = await _db.getAllConversations();
      int convosSynced = 0;
      int messagesSynced = 0;

      for (var convo in allConvos) {
        await _safeSave('convo_${convo.id}', jsonEncode(convo.toJson()));
        convosSynced++;

        final messages = await _db.getMessagesForConversation(convo.id);
        if (messages.isNotEmpty) {
          final messagesJson =
              jsonEncode(messages.map((m) => m.toJson()).toList());
          await _safeSave('msgs_${convo.id}', messagesJson);
          messagesSynced += messages.length;
        }
      }
      debugPrint(
          '☁️ iCloud Sync: Successfully synced up (pushed $convosSynced conversations, $messagesSynced messages).');
    } catch (e) {
      debugPrint('☁️ iCloud Sync: syncUp error - $e');
    } finally {
      _isSyncingUp = false;
    }
  }

  /// Pulls remote CloudKit state down into local SQLite.
  /// (Performs UPSERT logic to merge remote data)
  Future<bool> syncDown() async {
    if (!await isEnabled) return false;
    if (_isSyncingDown) return false;
    _isSyncingDown = true;
    bool hasChanges = false;
    debugPrint('☁️ iCloud Sync: Starting syncDown() from CloudKit...');

    try {
      final status = await _cloudKit.getAccountStatus();
      if (status != CloudKitAccountStatus.available) {
        debugPrint(
            '☁️ iCloud Sync: Account not available ($status), aborting syncDown.');
        return false;
      }

      final allRecords = await _cloudKit.getAll();
      if (allRecords == null || allRecords.isEmpty) {
        debugPrint('☁️ iCloud Sync: No records found on iCloud container.');
        return false;
      }

      final existingConvos = await _db.getAllConversations();
      final localConvoIds = existingConvos.map((c) => c.id).toSet();

      int convosAdded = 0;
      int convosUpdated = 0;
      int messagesAdded = 0;
      int messagesUpdated = 0;

      for (var entry in allRecords.entries) {
        final key = entry.key;
        final value = entry.value;

        if (key.startsWith('convo_')) {
          try {
            final map = jsonDecode(value);
            final convo = ChatConversation.fromJson(map);
            if (!localConvoIds.contains(convo.id)) {
              await _db.insertConversation(convo);
              hasChanges = true;
              convosAdded++;
            } else {
              // Update if remote is newer
              final local = existingConvos.firstWhere((c) => c.id == convo.id);
              if (convo.updatedAt.isAfter(local.updatedAt)) {
                await _db.updateConversation(convo);
                hasChanges = true;
                convosUpdated++;
              }
            }
          } catch (e) {
            debugPrint(
                '☁️ iCloud Sync: Failed to parse remote convo ($key): $e');
          }
        }
      }

      // Now sync messages for these conversations
      for (var entry in allRecords.entries) {
        if (entry.key.startsWith('msgs_')) {
          try {
            final convoId = entry.key.replaceFirst('msgs_', '');
            final List<dynamic> list = jsonDecode(entry.value);

            final localMessages = await _db.getMessagesForConversation(convoId);
            final localMessageIds = localMessages.map((m) => m.id).toSet();

            for (var item in list) {
              final msg = ChatMessage.fromJson(item as Map<String, dynamic>);
              if (!localMessageIds.contains(msg.id)) {
                await _db.insertMessage(msg, convoId);
                hasChanges = true;
                messagesAdded++;
              } else {
                // If message supports updating (like edits or status), we update it.
                final local = localMessages.firstWhere((m) => m.id == msg.id);
                final localImgPaths =
                    local.generatedImagePaths?.join(',') ?? '';
                final msgImgPaths = msg.generatedImagePaths?.join(',') ?? '';

                // Prefer local image paths if cloud is missing them
                // e.g. image generated locally after cloud sync up
                var mergedMsg = msg;
                if (msgImgPaths.isEmpty && localImgPaths.isNotEmpty) {
                  mergedMsg = msg.copyWith(
                    generatedImagePaths: local.generatedImagePaths,
                    generatedImagePath: local.generatedImagePath,
                  );
                }

                final mergedImgPaths =
                    mergedMsg.generatedImagePaths?.join(',') ?? '';
                if (local.content != mergedMsg.content ||
                    localImgPaths != mergedImgPaths) {
                  // Only update if there's actually new valid content or changes from cloud
                  // Wait, if it only differs by image, and mergedMsg adopted local image, it wouldn't update.
                  await _db.updateMessage(mergedMsg);
                  hasChanges = true;
                  messagesUpdated++;
                }
              }
            }
          } catch (e) {
            debugPrint(
                '☁️ iCloud Sync: Failed to parse remote msgs (${entry.key}): $e');
          }
        }
      }

      if (hasChanges) {
        debugPrint(
            '☁️ iCloud Sync: Completed successfully. Added $convosAdded convos, updated $convosUpdated. Added $messagesAdded msgs, updated $messagesUpdated.');
      } else {
        debugPrint(
            '☁️ iCloud Sync: Completed successfully. No new changes detected.');
      }
      return hasChanges;
    } catch (e) {
      debugPrint('☁️ iCloud Sync: syncDown error: $e');
      return false;
    } finally {
      _isSyncingDown = false;
    }
  }
}
