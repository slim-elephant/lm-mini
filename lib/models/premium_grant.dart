import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin-granted complimentary premium stored in Firestore.
class PremiumGrant {
  final String grantId;
  final DateTime expiresAt;
  final DateTime grantedAt;
  final String grantedBy;
  final String durationLabel;
  final String? reason;
  final bool bannerAcknowledged;
  final bool notificationSent;

  const PremiumGrant({
    required this.grantId,
    required this.expiresAt,
    required this.grantedAt,
    required this.grantedBy,
    required this.durationLabel,
    this.reason,
    this.bannerAcknowledged = false,
    this.notificationSent = false,
  });

  bool get isActive => DateTime.now().isBefore(expiresAt);

  Duration get remaining => expiresAt.difference(DateTime.now());

  factory PremiumGrant.fromFirestore(Map<String, dynamic> data) {
    return PremiumGrant(
      grantId: (data['grantId'] ?? '') as String,
      expiresAt: _parseDateTime(data['expiresAt']) ?? DateTime.now(),
      grantedAt: _parseDateTime(data['grantedAt']) ?? DateTime.now(),
      grantedBy: (data['grantedBy'] ?? '') as String,
      durationLabel: (data['durationLabel'] ?? '') as String,
      reason: (data['reason'] as String?)?.trim().isEmpty == true
          ? null
          : data['reason'] as String?,
      bannerAcknowledged: data['bannerAcknowledged'] == true,
      notificationSent: data['notificationSent'] == true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'grantId': grantId,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'grantedAt': Timestamp.fromDate(grantedAt),
      'grantedBy': grantedBy,
      'durationLabel': durationLabel,
      if (reason != null && reason!.isNotEmpty) 'reason': reason,
      'bannerAcknowledged': bannerAcknowledged,
      'notificationSent': notificationSent,
    };
  }

  PremiumGrant copyWith({
    bool? bannerAcknowledged,
    bool? notificationSent,
  }) {
    return PremiumGrant(
      grantId: grantId,
      expiresAt: expiresAt,
      grantedAt: grantedAt,
      grantedBy: grantedBy,
      durationLabel: durationLabel,
      reason: reason,
      bannerAcknowledged: bannerAcknowledged ?? this.bannerAcknowledged,
      notificationSent: notificationSent ?? this.notificationSent,
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
