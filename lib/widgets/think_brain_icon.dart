import 'package:flutter/material.dart';

/// Compact two-hemisphere brain for Think / reasoning controls.
class ThinkBrainIcon extends StatelessWidget {
  const ThinkBrainIcon({
    super.key,
    this.size = 24,
    this.color,
    this.filled = true,
  });

  final double size;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ??
        IconTheme.of(context).color ??
        DefaultTextStyle.of(context).style.color ??
        Colors.white;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BrainPainter(color: iconColor, filled: filled),
      ),
    );
  }
}

class _BrainPainter extends CustomPainter {
  _BrainPainter({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final dx = (size.width - s) / 2;
    final dy = (size.height - s) / 2;
    canvas.translate(dx, dy);
    canvas.scale(s / 24, s / 24);

    final outline = _outline();
    if (filled) {
      canvas.drawPath(
        outline,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      final groove = Paint()
        ..color = Color.lerp(color, Colors.black, 0.38)!.withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;
      canvas.drawPath(_sulci(), groove);
    } else {
      canvas.drawPath(
        outline,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true,
      );
      canvas.drawPath(
        _sulci(),
        Paint()
          ..color = color.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.15
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true,
      );
    }
  }

  Path _outline() {
    final p = Path();
    p.moveTo(12, 3.6);
    p.cubicTo(15.6, 3.2, 19.1, 4.8, 20.6, 7.6);
    p.cubicTo(22.2, 9.2, 22.6, 11.6, 21.7, 13.8);
    p.cubicTo(21.9, 15.7, 20.8, 17.6, 19.0, 18.6);
    p.cubicTo(18.2, 19.6, 16.8, 20.2, 15.4, 20.2);
    p.lineTo(13.35, 22.2);
    p.cubicTo(12.9, 22.55, 12.1, 22.55, 11.65, 22.2);
    p.lineTo(8.6, 20.2);
    p.cubicTo(7.2, 20.2, 5.8, 19.6, 5.0, 18.6);
    p.cubicTo(3.2, 17.6, 2.1, 15.7, 2.3, 13.8);
    p.cubicTo(1.4, 11.6, 1.8, 9.2, 3.4, 7.6);
    p.cubicTo(4.9, 4.8, 8.4, 3.2, 12, 3.6);
    p.close();
    return p;
  }

  Path _sulci() {
    final p = Path();
    // Longitudinal fissure
    p.moveTo(12.0, 5.4);
    p.cubicTo(11.2, 8.4, 12.8, 11.2, 12.0, 14.6);
    p.cubicTo(11.4, 16.6, 12.4, 18.0, 12.0, 19.6);
    // Left gyri
    p.moveTo(5.6, 8.2);
    p.cubicTo(7.4, 7.6, 8.6, 9.4, 7.8, 11.0);
    p.moveTo(4.8, 12.2);
    p.cubicTo(6.6, 11.6, 8.2, 13.4, 7.2, 15.2);
    p.moveTo(6.6, 16.6);
    p.cubicTo(8.0, 16.0, 9.4, 17.2, 8.8, 18.4);
    // Right gyri
    p.moveTo(18.4, 8.2);
    p.cubicTo(16.6, 7.6, 15.4, 9.4, 16.2, 11.0);
    p.moveTo(19.2, 12.2);
    p.cubicTo(17.4, 11.6, 15.8, 13.4, 16.8, 15.2);
    p.moveTo(17.4, 16.6);
    p.cubicTo(16.0, 16.0, 14.6, 17.2, 15.2, 18.4);
    return p;
  }

  @override
  bool shouldRepaint(covariant _BrainPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.filled != filled;
  }
}
