import 'package:cloud_firestore/cloud_firestore.dart';

/// A media attachment (photo or short video) uploaded to Firebase Storage
/// and referenced from a [FeatureRequest] or [FeatureComment].
///
/// Limits enforced client-side and in `storage.rules`:
///   - Photos (image/*) : max 10 MB
///   - Videos (video/*) : max 200 MB
///   - Max 3 attachments per request or per comment.
class FeatureAttachment {
  /// Public download URL (already including the alt=media token).
  /// Empty for error logs so the file is not fetchable without Storage auth.
  final String url;

  /// Firebase Storage object path. Used for deletion. Optional because
  /// older legacy attachments may not have it persisted.
  final String? storagePath;

  /// MIME type as reported on upload (e.g. `image/jpeg`, `video/mp4`).
  final String contentType;

  /// File size in bytes (for display only).
  final int? sizeBytes;

  /// True if this attachment is a video.
  bool get isVideo => contentType.startsWith('video/');

  /// True if this attachment is an image.
  bool get isImage => contentType.startsWith('image/');

  /// True if this attachment is a text error log (or similar).
  bool get isLog {
    if (contentType.startsWith('text/')) return true;
    final path = (storagePath ?? url).toLowerCase();
    return path.endsWith('.log') || path.endsWith('.txt');
  }

  const FeatureAttachment({
    required this.url,
    required this.contentType,
    this.storagePath,
    this.sizeBytes,
  });

  Map<String, dynamic> toMap() => {
        if (url.isNotEmpty) 'url': url,
        if (storagePath != null) 'storagePath': storagePath,
        'contentType': contentType,
        if (sizeBytes != null) 'sizeBytes': sizeBytes,
      };

  /// Photos/videos for everyone; error logs only when [isAdmin] is true.
  static List<FeatureAttachment> visibleForViewer(
    List<FeatureAttachment> attachments, {
    required bool isAdmin,
  }) {
    if (isAdmin) return attachments;
    return attachments.where((a) => !a.isLog).toList(growable: false);
  }

  factory FeatureAttachment.fromMap(Map<String, dynamic> map) {
    return FeatureAttachment(
      url: (map['url'] ?? '') as String,
      storagePath: map['storagePath'] as String?,
      contentType: (map['contentType'] ?? 'application/octet-stream') as String,
      sizeBytes: (map['sizeBytes'] as num?)?.toInt(),
    );
  }

  static List<FeatureAttachment> listFromAny(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => FeatureAttachment.fromMap(e.cast<String, dynamic>()))
        .toList(growable: false);
  }
}

enum FeatureCategory {
  uiUx('UI/UX'),
  newFeature('New Feature'),
  improvement('Improvement'),
  bugFix('Bug Fix'),
  other('Other');

  final String displayName;
  const FeatureCategory(this.displayName);

  static FeatureCategory fromString(String value) {
    return FeatureCategory.values.firstWhere(
      (e) => e.name == value || e.displayName == value,
      orElse: () => FeatureCategory.other,
    );
  }
}

enum FeatureStatus {
  pending('Pending', 0xFFFFA726),
  underReview('Under Review', 0xFF42A5F5),
  planned('Planned', 0xFF7E57C2),
  inProgress('In Progress', 0xFF26A69A),
  testing('Testing', 0xFFEC407A),
  completed('Completed', 0xFF66BB6A),
  declined('Declined', 0xFFEF5350);

  final String displayName;
  final int colorValue;
  const FeatureStatus(this.displayName, this.colorValue);

  static FeatureStatus fromString(String value) {
    return FeatureStatus.values.firstWhere(
      (e) => e.name == value || e.displayName == value,
      orElse: () => FeatureStatus.pending,
    );
  }
}

/// Represents a comment on a feature request
class FeatureComment {
  final String id;
  final String requestId;
  final String userId;
  final String? authorName;
  final String content;
  final bool isAdmin;
  final bool isModerator;
  final bool isPremium;
  final DateTime createdAt;
  final List<FeatureAttachment> attachments;

  /// `ios`, `android`, or `other` — captured at post time.
  final String? platform;
  final String? appVersion;

  FeatureComment({
    required this.id,
    required this.requestId,
    required this.userId,
    this.authorName,
    required this.content,
    required this.isAdmin,
    this.isModerator = false,
    this.isPremium = false,
    required this.createdAt,
    this.attachments = const [],
    this.platform,
    this.appVersion,
  });

  factory FeatureComment.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FeatureComment(
      id: doc.id,
      requestId: data['requestId'] ?? '',
      userId: data['userId'] ?? '',
      authorName: data['authorName'],
      content: data['content'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      isModerator: data['isModerator'] ?? false,
      isPremium: data['isPremium'] ?? false,
      createdAt: _parseDateTime(data['createdAt']),
      attachments: FeatureAttachment.listFromAny(data['attachments']),
      platform: data['platform'] as String?,
      appVersion: data['appVersion'] as String?,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requestId': requestId,
      'userId': userId,
      'authorName': authorName,
      'content': content,
      'isAdmin': isAdmin,
      'isModerator': isModerator,
      'isPremium': isPremium,
      'createdAt': Timestamp.fromDate(createdAt),
      if (platform != null) 'platform': platform,
      if (appVersion != null) 'appVersion': appVersion,
      if (attachments.isNotEmpty)
        'attachments': attachments.map((a) => a.toMap()).toList(),
    };
  }
}

class FeatureRequest {
  final String id;
  final String userId;
  final String? submitterName;
  final String title;
  final String description;
  final FeatureCategory category;
  final FeatureStatus status;
  final int voteCount;
  final List<String> voterIds;
  final String? adminReply;
  final int commentCount;
  final bool isPremium;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<FeatureAttachment> attachments;

  /// `ios`, `android`, or `other` — captured at submit time.
  final String? platform;
  final String? appVersion;

  /// Normalized error key for Bug Fix tickets filed from in-app error UI.
  final String? errorFingerprint;

  FeatureRequest({
    required this.id,
    required this.userId,
    this.submitterName,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.voteCount,
    required this.voterIds,
    this.adminReply,
    this.commentCount = 0,
    this.isPremium = false,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const [],
    this.platform,
    this.appVersion,
    this.errorFingerprint,
  });

  factory FeatureRequest.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FeatureRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      submitterName: data['submitterName'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: FeatureCategory.fromString(data['category'] ?? 'other'),
      status: FeatureStatus.fromString(data['status'] ?? 'pending'),
      voteCount: data['voteCount'] ?? 0,
      voterIds: List<String>.from(data['voterIds'] ?? []),
      adminReply: data['adminReply'],
      commentCount: data['commentCount'] ?? 0,
      isPremium: data['isPremium'] ?? false,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      attachments: FeatureAttachment.listFromAny(data['attachments']),
      platform: data['platform'] as String?,
      appVersion: data['appVersion'] as String?,
      errorFingerprint: data['errorFingerprint'] as String?,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'submitterName': submitterName,
      'title': title,
      'description': description,
      'category': category.name,
      'status': status.name,
      'voteCount': voteCount,
      'voterIds': voterIds,
      'adminReply': adminReply,
      'commentCount': commentCount,
      'isPremium': isPremium,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (platform != null) 'platform': platform,
      if (appVersion != null) 'appVersion': appVersion,
      if (errorFingerprint != null && errorFingerprint!.isNotEmpty)
        'errorFingerprint': errorFingerprint,
      if (attachments.isNotEmpty)
        'attachments': attachments.map((a) => a.toMap()).toList(),
    };
  }

  FeatureRequest copyWith({
    String? id,
    String? userId,
    String? submitterName,
    String? title,
    String? description,
    FeatureCategory? category,
    FeatureStatus? status,
    int? voteCount,
    List<String>? voterIds,
    String? adminReply,
    int? commentCount,
    bool? isPremium,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<FeatureAttachment>? attachments,
    String? platform,
    String? appVersion,
    String? errorFingerprint,
  }) {
    return FeatureRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      submitterName: submitterName ?? this.submitterName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      voteCount: voteCount ?? this.voteCount,
      voterIds: voterIds ?? this.voterIds,
      adminReply: adminReply ?? this.adminReply,
      commentCount: commentCount ?? this.commentCount,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
      platform: platform ?? this.platform,
      appVersion: appVersion ?? this.appVersion,
      errorFingerprint: errorFingerprint ?? this.errorFingerprint,
    );
  }

  bool hasVoted(String visitorId) => voterIds.contains(visitorId);
}
