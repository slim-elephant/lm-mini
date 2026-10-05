import '../models/app_settings.dart';

/// Last-used chat model is stored per server slot so switching backends
/// does not keep another server's model id in [AppSettings.selectedModel].
class ServerModelMemory {
  ServerModelMemory._();

  static String keyFor(AppSettings settings) => key(
        providerKind: settings.activeProviderKind,
        isRemoteActive: settings.isRemoteActive,
        usbModeEnabled: settings.usbModeEnabled,
        serverUrl: settings.serverUrl,
      );

  /// Stable slot id. Remote backends share the relay URL, so they key by
  /// kind (`remote:lmMiniDesktop` vs `remote:lmStudio`), not URL.
  static String key({
    required String providerKind,
    required bool isRemoteActive,
    required bool usbModeEnabled,
    required String serverUrl,
  }) {
    if (providerKind == 'onDeviceGguf' ||
        providerKind == 'onDeviceMlx' ||
        providerKind == 'appleIntelligence') {
      return 'onDevice:$providerKind';
    }
    if (isRemoteActive) {
      final remoteKind = (providerKind == 'ollama' ||
              providerKind == 'omlx' ||
              providerKind == 'lmMiniDesktop')
          ? providerKind
          : 'lmStudio';
      return 'remote:$remoteKind';
    }
    if (usbModeEnabled) return 'usb:lmStudio';
    if (providerKind == 'ollama' ||
        providerKind == 'omlx' ||
        providerKind == 'jan' ||
        providerKind == 'unsloth' ||
        providerKind == 'cloud') {
      return 'cloud:$providerKind';
    }
    final url = serverUrl.trim();
    return 'local:${url.isEmpty ? 'lmStudio' : url}';
  }

  /// Prefer the remembered id when it is in the new catalog. Never keep a
  /// current id that belongs to another server's catalog.
  static String? pick({
    required String? remembered,
    required String? current,
    required Iterable<String> availableIds,
  }) {
    final ids = availableIds.toSet();
    if (ids.isEmpty) return remembered;
    if (remembered != null &&
        remembered.isNotEmpty &&
        ids.contains(remembered)) {
      return remembered;
    }
    if (current != null && current.isNotEmpty && ids.contains(current)) {
      return current;
    }
    return null;
  }
}
