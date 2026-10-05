import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Continuous purple rim: full top + sides fading down.
///
/// When [wrapBottomCorners] is true, the side strokes continue through the
/// bottom corner arcs and a short way along the bottom edge (status-bar style).
class ComposerShineBorder extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  /// Side fade completes at this fraction of total height (ignored when wrapping).
  final double fadeEnd;
  /// Curve the shine around the bottom corners instead of stopping mid-side.
  final bool wrapBottomCorners;

  const ComposerShineBorder({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.5,
    this.fadeEnd = 0.55,
    this.wrapBottomCorners = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 4 || size.height < 4) return;

    final r = radius.clamp(0.0, size.shortestSide / 2);
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    if (rect.width <= 0 || rect.height <= 0) return;

    // Top edge + both top corner arcs as one continuous path.
    final topPath = Path()
      ..moveTo(rect.left, rect.top + r)
      ..arcToPoint(
        Offset(rect.left + r, rect.top),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..lineTo(rect.right - r, rect.top)
      ..arcToPoint(
        Offset(rect.right, rect.top + r),
        radius: Radius.circular(r),
        clockwise: true,
      );

    final topGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = color.withValues(alpha: 0.40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    final topStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = color.withValues(alpha: 0.85);

    canvas.drawPath(topPath, topGlow);
    canvas.drawPath(topPath, topStroke);

    if (wrapBottomCorners) {
      _drawWrappedSide(canvas, rect: rect, radius: r, left: true);
      _drawWrappedSide(canvas, rect: rect, radius: r, left: false);
      return;
    }

    final minSide = rect.top + r + 1;
    final rawSide = rect.top + rect.height * fadeEnd;
    final sideStop = (rawSide < minSide ? minSide : rawSide)
        .clamp(minSide, rect.bottom);

    _drawFadingLine(
      canvas,
      from: Offset(rect.left, rect.top + r),
      to: Offset(rect.left, sideStop),
      beginAlpha: 0.85,
      endAlpha: 0.0,
    );
    _drawFadingLine(
      canvas,
      from: Offset(rect.right, rect.top + r),
      to: Offset(rect.right, sideStop),
      beginAlpha: 0.85,
      endAlpha: 0.0,
    );
  }

  void _drawWrappedSide(
    Canvas canvas, {
    required Rect rect,
    required double radius,
    required bool left,
  }) {
    final x = left ? rect.left : rect.right;
    final sideEnd = Offset(x, rect.bottom - radius);
    // Keep the vertical run bright so the corner curve stays readable.
    _drawFadingLine(
      canvas,
      from: Offset(x, rect.top + radius),
      to: sideEnd,
      beginAlpha: 0.85,
      endAlpha: 0.55,
    );

    // Bottom corner arc — outer quarter (screen y-down: left uses CCW, right CW).
    final corner = Path()..moveTo(sideEnd.dx, sideEnd.dy);
    if (left) {
      corner.arcToPoint(
        Offset(rect.left + radius, rect.bottom),
        radius: Radius.circular(radius),
        largeArc: false,
        clockwise: false,
      );
    } else {
      corner.arcToPoint(
        Offset(rect.right - radius, rect.bottom),
        radius: Radius.circular(radius),
        largeArc: false,
        clockwise: true,
      );
    }

    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = color.withValues(alpha: 0.48);
    final cornerGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = color.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawPath(corner, cornerGlow);
    canvas.drawPath(corner, cornerPaint);

    // Short bottom stub fading toward the center.
    final along = (rect.width * 0.22).clamp(12.0, 36.0);
    final bottomFrom = left
        ? Offset(rect.left + radius, rect.bottom)
        : Offset(rect.right - radius, rect.bottom);
    final bottomTo = left
        ? Offset(rect.left + radius + along, rect.bottom)
        : Offset(rect.right - radius - along, rect.bottom);
    _drawFadingLine(
      canvas,
      from: bottomFrom,
      to: bottomTo,
      beginAlpha: 0.42,
      endAlpha: 0.0,
    );
  }

  void _drawFadingLine(
    Canvas canvas, {
    required Offset from,
    required Offset to,
    required double beginAlpha,
    required double endAlpha,
  }) {
    if ((to - from).distance < 1) return;

    final shader = ui.Gradient.linear(
      from,
      to,
      [
        color.withValues(alpha: beginAlpha),
        color.withValues(alpha: endAlpha),
      ],
    );

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..shader = shader
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..shader = shader;

    canvas.drawLine(from, to, glow);
    canvas.drawLine(from, to, stroke);
  }

  @override
  bool shouldRepaint(covariant ComposerShineBorder oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.fadeEnd != fadeEnd ||
        oldDelegate.wrapBottomCorners != wrapBottomCorners;
  }
}
