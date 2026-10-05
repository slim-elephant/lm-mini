// LM-MINI-PRO-STUB
part of '../../services/local_model_download_service.dart';

/// Public-build stub: MLX folder import and custom Hugging Face downloads
/// are part of LM Mini Pro. The Local Models screen never calls these in
/// the public build; GGUF file import and the free catalog keep working.
extension ProLocalModelImports on LocalModelDownloadService {
  Future<LocalModelSpec> importMlxFromDirectory(
    String sourceDirPath, {
    String? displayName,
  }) async {
    throw UnsupportedError('Available in the official LM Mini app.');
  }

  Future<LocalModelSpec> addCustomFromHuggingFace(String input) async {
    throw UnsupportedError('Available in the official LM Mini app.');
  }
}
