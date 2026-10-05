import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-backed community roles for feature-request participants.
class CommunityUserProfile {
  final String userId;
  final bool isModerator;
  final bool isExperiencedUser;
  final DateTime? updatedAt;
  final String? updatedBy;

  const CommunityUserProfile({
    required this.userId,
    this.isModerator = false,
    this.isExperiencedUser = false,
    this.updatedAt,
    this.updatedBy,
  });

  factory CommunityUserProfile.fromFirestore(
    String userId,
    Map<String, dynamic> data,
  ) {
    return CommunityUserProfile(
      userId: userId,
      isModerator: data['isModerator'] == true,
      isExperiencedUser: data['isExperiencedUser'] == true,
      updatedAt: _parseDateTime(data['updatedAt']),
      updatedBy: data['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore({required String updatedBy}) {
    return {
      'isModerator': isModerator,
      'isExperiencedUser': isExperiencedUser,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  CommunityUserProfile copyWith({
    bool? isModerator,
    bool? isExperiencedUser,
  }) {
    return CommunityUserProfile(
      userId: userId,
      isModerator: isModerator ?? this.isModerator,
      isExperiencedUser: isExperiencedUser ?? this.isExperiencedUser,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
