/// A curated TTS voice pack listed in the community / Pro voice catalog.
///
/// Pack binaries stay on the original [downloadUrl] (usually a GitHub Release).
/// This document is metadata only — published by admins after a successful
/// download + preview in the admin import tool.
class VoiceCatalogEntry {
  final String id;
  final String name;
  final String engine; // 'vits' | 'kokoro'
  final String language; // BCP-47-ish: en, de, es, fr, ru, zh, …
  final String? locale; // e.g. en_US
  final String downloadUrl;
  final int? sizeBytes;
  final bool isPro;
  final bool published;
  final String? previewNote;
  final DateTime? createdAt;
  final String? createdBy;

  const VoiceCatalogEntry({
    required this.id,
    required this.name,
    required this.engine,
    required this.language,
    this.locale,
    required this.downloadUrl,
    this.sizeBytes,
    this.isPro = true,
    this.published = true,
    this.previewNote,
    this.createdAt,
    this.createdBy,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'engine': engine,
        'language': language,
        if (locale != null) 'locale': locale,
        'downloadUrl': downloadUrl,
        if (sizeBytes != null) 'sizeBytes': sizeBytes,
        'isPro': isPro,
        'published': published,
        if (previewNote != null) 'previewNote': previewNote,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (createdBy != null) 'createdBy': createdBy,
      };

  factory VoiceCatalogEntry.fromJson(Map<String, dynamic> json) {
    return VoiceCatalogEntry(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Voice',
      engine: json['engine'] as String? ?? 'vits',
      language: json['language'] as String? ?? 'en',
      locale: json['locale'] as String?,
      downloadUrl: json['downloadUrl'] as String? ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
      isPro: json['isPro'] as bool? ?? true,
      published: json['published'] as bool? ?? true,
      previewNote: json['previewNote'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      createdBy: json['createdBy'] as String?,
    );
  }
}
