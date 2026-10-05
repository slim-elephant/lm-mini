import 'package:flutter/material.dart';

/// Small green dot shown when there are unread feature-request updates.
class UnreadDot extends StatelessWidget {
  final double size;

  const UnreadDot({super.key, this.size = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.greenAccent.shade400,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 1.5,
        ),
      ),
    );
  }
}

/// Overlays a green unread dot on a child widget (e.g. settings icon).
class UnreadDotOverlay extends StatelessWidget {
  final Widget child;
  final bool show;

  const UnreadDotOverlay({
    super.key,
    required this.child,
    required this.show,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        const Positioned(
          right: -2,
          top: -2,
          child: UnreadDot(size: 11),
        ),
      ],
    );
  }
}
