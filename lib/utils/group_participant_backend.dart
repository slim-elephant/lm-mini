import '../models/local_model_spec.dart';
import '../services/local_model_catalog.dart';
import '../services/local_model_download_service.dart';

/// Resolve which backend a group-chat participant should use.
///
/// Stored [providerKind] wins. If it was never written (legacy / add-persona),
/// infer from the persona default, a bound cloud provider, or the model id
/// against on-device / LM Studio catalogs — not "whatever Settings is on now".
abstract final class GroupParticipantBackend {
  static const knownKinds = <String>{
    'lmStudio',
    'lmMiniDesktop',
    'onDeviceGguf',
    'onDeviceMlx',
    'cloud',
    'omlx',
    'ollama',
    'jan',
    'unsloth',
    'appleIntelligence',
  };

  static bool isKnown(String? kind) =>
      kind != null && kind.isNotEmpty && knownKinds.contains(kind);

  static LocalModelSpec? localSpec(String id) {
    if (id.isEmpty) return null;
    final catalog = LocalModelCatalog.byId(id);
    if (catalog != null) return catalog;
    for (final entry in LocalModelDownloadService.instance.readyEntries) {
      if (entry.spec.id == id) return entry.spec;
    }
    return null;
  }

  static bool isLocalMlxId(String id) =>
      localSpec(id)?.engine == LocalEngine.mlx;

  static bool isLocalGgufId(String id) =>
      localSpec(id)?.engine == LocalEngine.fllama;

  static String resolve({
    String? storedKind,
    String? personaKind,
    String? cloudProviderKind,
    String? modelId,
    String? globalKind,
    bool Function(String id)? isLocalMlx,
    bool Function(String id)? isLocalGguf,
    bool Function(String id)? isLmStudioModel,
  }) {
    if (isKnown(storedKind)) return storedKind!;
    if (isKnown(personaKind)) return personaKind!;
    if (isKnown(cloudProviderKind)) return cloudProviderKind!;

    final id = (modelId ?? '').trim();
    if (id.isNotEmpty) {
      if (isLocalMlx?.call(id) == true) return 'onDeviceMlx';
      if (isLocalGguf?.call(id) == true) return 'onDeviceGguf';
      if (isLmStudioModel?.call(id) == true) return 'lmStudio';
    }

    if (isKnown(globalKind)) return globalKind!;
    return 'lmStudio';
  }
}
