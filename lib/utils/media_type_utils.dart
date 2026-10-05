import 'dart:typed_data';

/// Video container extensions LM Mini knows how to play back.
const Set<String> kVideoFileExtensions = {
  '.mp4',
  '.webm',
  '.mov',
  '.m4v',
  '.mkv',
  '.avi',
};

/// Sniffs raw bytes via magic numbers and returns the appropriate file
/// extension (with leading dot).
///
/// Generated media from ComfyUI can be an image (PNG/JPEG/GIF/WebP) or a video
/// (MP4/WebM) depending on the workflow. We used to always write `.png`, which
/// made video output fail to decode as an image. Sniffing the bytes lets us
/// persist the true type so the UI can render it correctly.
///
/// Falls back to `.png` for unrecognized data to preserve prior behavior.
String mediaExtensionForBytes(Uint8List b) {
  if (b.length >= 12) {
    // PNG: 89 50 4E 47
    if (b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) {
      return '.png';
    }
    // JPEG: FF D8 FF
    if (b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
      return '.jpg';
    }
    // GIF: "GIF8"
    if (b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x38) {
      return '.gif';
    }
    // WebP: "RIFF"...."WEBP"
    if (b[0] == 0x52 &&
        b[1] == 0x49 &&
        b[2] == 0x46 &&
        b[3] == 0x46 &&
        b[8] == 0x57 &&
        b[9] == 0x45 &&
        b[10] == 0x42 &&
        b[11] == 0x50) {
      return '.webp';
    }
    // Matroska / WebM: 1A 45 DF A3
    if (b[0] == 0x1A && b[1] == 0x45 && b[2] == 0xDF && b[3] == 0xA3) {
      return '.webm';
    }
    // ISO Base Media (MP4/MOV): bytes 4..7 == "ftyp"
    if (b[4] == 0x66 && b[5] == 0x74 && b[6] == 0x79 && b[7] == 0x70) {
      return '.mp4';
    }
  }
  return '.png';
}

/// True when [path]'s extension is a known video container.
bool isVideoFilePath(String path) {
  final lower = path.toLowerCase();
  final dot = lower.lastIndexOf('.');
  if (dot < 0) return false;
  return kVideoFileExtensions.contains(lower.substring(dot));
}
