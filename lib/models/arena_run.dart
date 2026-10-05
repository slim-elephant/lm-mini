/// A persisted Arena run — the unit saved to the user's private history.
library;

import 'arena_models.dart';

class ArenaRun {
  final String id;
  final DateTime createdAt;
  final ArenaMode mode;

  /// Representative prompt (the free-form prompt for compare, or the prompt-set
  /// name for benchmark).
  final String promptLabel;

  /// Benchmark prompt-set id + version (null for compare).
  final String? promptSetId;
  final int? promptSetVersion;

  final List<ArenaContestantResult> results;
  final String? winnerId;
  final String? userPickId;

  // Device snapshot for history display + later aggregation.
  final String platform;
  final String deviceName;
  final String deviceClass;
  final String chip;
  final double ramGb;
  final String appVersion;

  const ArenaRun({
    required this.id,
    required this.createdAt,
    required this.mode,
    required this.promptLabel,
    required this.results,
    required this.platform,
    required this.deviceName,
    required this.deviceClass,
    required this.chip,
    required this.ramGb,
    required this.appVersion,
    this.promptSetId,
    this.promptSetVersion,
    this.winnerId,
    this.userPickId,
  });

  int get contestantCount => results.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'mode': mode.name,
        'promptLabel': promptLabel,
        'promptSetId': promptSetId,
        'promptSetVersion': promptSetVersion,
        'results': results.map((r) => r.toJson()).toList(),
        'winnerId': winnerId,
        'userPickId': userPickId,
        'platform': platform,
        'deviceName': deviceName,
        'deviceClass': deviceClass,
        'chip': chip,
        'ramGb': ramGb,
        'appVersion': appVersion,
      };

  factory ArenaRun.fromJson(Map<String, dynamic> json) => ArenaRun(
        id: json['id'] as String,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        mode: ArenaMode.values.firstWhere(
          (m) => m.name == json['mode'],
          orElse: () => ArenaMode.compare,
        ),
        promptLabel: json['promptLabel'] as String? ?? '',
        promptSetId: json['promptSetId'] as String?,
        promptSetVersion: (json['promptSetVersion'] as num?)?.toInt(),
        results: (json['results'] as List?)
                ?.map((r) => ArenaContestantResult.fromJson(
                    (r as Map).cast<String, dynamic>()))
                .toList() ??
            [],
        winnerId: json['winnerId'] as String?,
        userPickId: json['userPickId'] as String?,
        platform: json['platform'] as String? ?? 'unknown',
        deviceName: json['deviceName'] as String? ?? 'Unknown device',
        deviceClass: json['deviceClass'] as String? ?? '',
        chip: json['chip'] as String? ?? '',
        ramGb: (json['ramGb'] as num?)?.toDouble() ?? 0,
        appVersion: json['appVersion'] as String? ?? '',
      );
}
