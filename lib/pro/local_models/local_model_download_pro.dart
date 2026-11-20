// LM-MINI-PRO-STUB
part of '../../services/local_model_download_service.dart';

/// Public-build stub: custom Hugging Face downloads are part of LM Mini Pro.
/// The Local Models screen never calls this in the public build; GGUF and
/// MLX import and the free catalog keep working.
extension ProLocalModelImports on LocalModelDownloadService {
  Future<LocalModelSpec> addCustomFromHuggingFace(String input) async {
    throw UnsupportedError('Available in the official LM Mini app.');
  }
}
