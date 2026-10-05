// LM-MINI-PRO-STUB
import 'package:flutter/material.dart';

/// Pass-through: public builds never lock, even when restored settings say
/// App Lock was enabled.
class AppLockGate extends StatelessWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
