import '../pro/admin/admin_ids.dart';

/// Firebase UIDs with app-wide admin privileges.
///
/// The UID list lives in the private overlay ([ProAdminIds.appAdmins]); it is
/// empty in the public build. Keep it in sync with the `isAppAdmin()` list in
/// [firestore.rules] and [storage.rules].
abstract final class AppAdminConfig {
  static const List<String> adminUserIds = ProAdminIds.appAdmins;

  static bool isAdmin(String? userId) =>
      userId != null && adminUserIds.contains(userId);
}
