// LM-MINI-PRO-STUB
import 'package:flutter/material.dart';

/// Public build: the admin user-management sheet (community roles and
/// complimentary premium grants) ships only in the official LM Mini app.
/// Its entry points are admin-gated, and the public build has no admins.
class AdminUserManageSheet extends StatelessWidget {
  final String userId;
  final String? displayName;

  const AdminUserManageSheet({
    super.key,
    required this.userId,
    this.displayName,
  });

  /// No-op in the public build.
  static Future<void> show(
    BuildContext context, {
    required String userId,
    String? displayName,
  }) async {}

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
