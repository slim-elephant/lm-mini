import 'package:flutter/material.dart';

/// Root navigator for dialogs when no [BuildContext] is available (e.g. from
/// [ChangeNotifier] code paths).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
