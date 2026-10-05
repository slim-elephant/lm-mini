import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_folder.dart';
import '../services/database_service.dart';
import '../services/home_sync_service.dart';
import '../services/home_sync_snapshot.dart';
import '../services/widget_data_service.dart';

class FolderProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<ChatFolder> _folders = [];
  bool _isLoading = false;
  String? _error;

  List<ChatFolder> get folders => _folders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _syncWidget() {
    // Best-effort fire-and-forget; widget UI is not in the critical path.
    WidgetDataService.updateTopFolders(_folders);
  }

  Future<void> loadFolders({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final previous = _folders;
      var next = await _databaseService.getAllFolders();
      _folders = next;
      if (await _mergeDuplicateNamedFolders()) {
        next = await _databaseService.getAllFolders();
        _folders = next;
      }
      if (silent && _sameFolderList(previous, _folders)) {
        return;
      }
      if (!silent) _isLoading = false;
      notifyListeners();
      _syncWidget();
    } catch (e) {
      _error = e.toString();
      if (!silent) _isLoading = false;
      notifyListeners();
    }
  }

  bool _sameFolderList(List<ChatFolder> a, List<ChatFolder> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
      if (a[i].name != b[i].name) return false;
      if (a[i].updatedAt.millisecondsSinceEpoch !=
          b[i].updatedAt.millisecondsSinceEpoch) {
        return false;
      }
    }
    return true;
  }

  Future<ChatFolder?> createFolder(String name, {String? color}) async {
    try {
      final key = name.trim().toLowerCase();
      for (final folder in _folders) {
        if (folder.name.trim().toLowerCase() == key) return folder;
      }

      final folder = ChatFolder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        color: color,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        conversationIds: [],
        sortOrder: _folders.length,
      );
      
      await _databaseService.insertFolder(folder);
      _folders.add(folder);
      notifyListeners();
      _syncWidget();
      HomeSyncService.instance.schedule();
      return folder;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateFolder(ChatFolder folder) async {
    try {
      final updatedFolder = folder.copyWith(updatedAt: DateTime.now());
      await _databaseService.updateFolder(updatedFolder);
      
      final index = _folders.indexWhere((f) => f.id == folder.id);
      if (index != -1) {
        _folders[index] = updatedFolder;
        notifyListeners();
        _syncWidget();
      }
      HomeSyncService.instance.schedule();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteFolder(String folderId) async {
    try {
      await _databaseService.deleteFolder(folderId);
      _folders.removeWhere((f) => f.id == folderId);
      notifyListeners();
      _syncWidget();
      unawaited(HomeSyncService.instance.rememberDeletedFolder(folderId));
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addConversationToFolder(String folderId, String conversationId) async {
    try {
      final folder = _folders.firstWhere((f) => f.id == folderId);
      if (!folder.conversationIds.contains(conversationId)) {
        final updatedFolder = folder.copyWith(
          conversationIds: [...folder.conversationIds, conversationId],
          updatedAt: DateTime.now(),
        );
        await updateFolder(updatedFolder);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeConversationFromFolder(String folderId, String conversationId) async {
    try {
      final folder = _folders.firstWhere((f) => f.id == folderId);
      final updatedFolder = folder.copyWith(
        conversationIds: folder.conversationIds.where((id) => id != conversationId).toList(),
        updatedAt: DateTime.now(),
      );
      await updateFolder(updatedFolder);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Collapse locally stored folders that share a name (phone + Home sync).
  /// Returns true when the database changed.
  Future<bool> _mergeDuplicateNamedFolders() async {
    if (_folders.length < 2) return false;
    final convos = await _databaseService.getAllConversations();
    final packed = [
      for (final conversation in convos)
        HomeSyncConversation(conversation: conversation, messages: const []),
    ];
    final collapsed = HomeSyncMerge.collapseNamedFolders(_folders, packed);
    if (collapsed.remap.isEmpty) return false;

    final previousById = {for (final folder in _folders) folder.id: folder};
    for (final folder in collapsed.folders) {
      final previous = previousById[folder.id];
      if (previous == null ||
          previous.updatedAt != folder.updatedAt ||
          previous.conversationIds.length != folder.conversationIds.length) {
        await _databaseService.updateFolder(folder);
      }
    }
    for (final entry in collapsed.remap.entries) {
      await _databaseService.reassignConversationsToFolder(
        entry.key,
        entry.value,
      );
      await _databaseService.deleteFolderRow(entry.key);
      unawaited(HomeSyncService.instance.rememberDeletedFolder(entry.key));
    }
    final previousFolderByConvo = {for (final c in convos) c.id: c.folderId};
    for (final item in collapsed.conversations) {
      if (previousFolderByConvo[item.conversation.id] !=
          item.conversation.folderId) {
        await _databaseService.updateConversation(item.conversation);
      }
    }
    return true;
  }

  Future<void> reorderFolders(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex--;
    final folder = _folders.removeAt(oldIndex);
    _folders.insert(newIndex, folder);

    // Update sort order for all folders
    for (int i = 0; i < _folders.length; i++) {
      _folders[i] = _folders[i].copyWith(sortOrder: i);
    }
    notifyListeners();

    try {
      await _databaseService.updateFolderSortOrders(_folders);
      HomeSyncService.instance.schedule();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
