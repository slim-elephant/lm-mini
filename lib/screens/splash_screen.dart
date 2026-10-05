import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';

/// A polished animated splash screen that shows the LM Mini branding
/// with a chat-bubble logo, animated sparkles, and a smooth transition
/// into the main app.
class SplashScreen extends StatefulWidget {
  /// Called when the splash animation finishes.
  final VoidCallback onFinished;

  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _sparkleController;
  late final AnimationController _fadeOutController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _textOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _sparkleOpacity;
  late final Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    // ── Logo entrance (0 → 1.6 s) ──────────────────────────────────────
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
      ),
    );

    // ── Sparkle loop ────────────────────────────────────────────────────
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _sparkleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sparkleController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // ── Fade-out transition ─────────────────────────────────────────────
    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeInCubic),
    );

    _start();
  }

  /// Map the persisted icon-theme preference to the splash gradient colors.
  /// Kept in one place so the dark / glass launcher icons feel like part of
  /// the app from the very first frame after the OS hands control over.
  List<Color> _gradientForIconTheme(String iconTheme) {
    switch (iconTheme) {
      case 'dark':
        return const [Color(0xFF1C1C2A), Color(0xFF0A0A10)];
      case 'glass':
        // Frosted neutral — cool slate that reads well behind a translucent
        // (system-tinted) icon.
        return const [Color(0xFF3F4A63), Color(0xFF1F2735)];
      case 'default':
      default:
        return const [Color(0xFF818CF8), Color(0xFF4F46E5)];
    }
  }

  Future<void> _start() async {
    // Start the logo entrance
    _logoController.forward();

    // Start sparkles after a short delay
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _sparkleController.repeat(reverse: true);

    // Hold for a moment, then fade out
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    await _fadeOutController.forward();
    if (!mounted) return;
    widget.onFinished();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _sparkleController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pick a gradient that mirrors the user's chosen launcher-icon theme so
    // the splash bg matches the home-screen icon they just tapped.
    final iconTheme = context
        .select<SettingsProvider, String>((p) => p.settings.iconTheme);
    final gradientColors = _gradientForIconTheme(iconTheme);
    return AnimatedBuilder(
      animation: Listenable.merge([
        _logoController,
        _sparkleController,
        _fadeOutController,
      ]),
      builder: (context, _) {
        return Opacity(
          opacity: _fadeOut.value,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
              ),
              child: Stack(
                children: [
                  // ── Neural dot grid background ─────────────────────────
                  const _NeuralDots(),

                // ── Main content ───────────────────────────────────────
                Center(
                  child: SlideTransition(
                    position: _logoSlide,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Chat-bubble logo
                        Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Bubble
                                const _ChatBubbleLogo(size: 140),

                                // Sparkles
                                Positioned(
                                  top: -14,
                                  right: -18,
                                  child: Opacity(
                                    opacity: _sparkleOpacity.value,
                                    child: _AnimatedSparkle(
                                      animation: _sparkleController,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: -30,
                                  child: Opacity(
                                    opacity: _sparkleOpacity.value * 0.6,
                                    child: _AnimatedSparkle(
                                      animation: _sparkleController,
                                      size: 10,
                                      phaseOffset: 0.3,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -8,
                                  left: -16,
                                  child: Opacity(
                                    opacity: _sparkleOpacity.value * 0.5,
                                    child: _AnimatedSparkle(
                                      animation: _sparkleController,
                                      size: 12,
                                      phaseOffset: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // "LM mini" text
                        Opacity(
                          opacity: _textOpacity.value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'LM',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'mini',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.85),
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Tagline
                        Opacity(
                          opacity: _taglineOpacity.value * 0.55,
                          child: Text(
                            AppLocalizations.of(context).splashTagline,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Bottom shimmer bar ─────────────────────────────────
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 80,
                  child: Opacity(
                    opacity: _taglineOpacity.value * 0.4,
                    child: _ShimmerBar(animation: _sparkleController),
                  ),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Sub-widgets
// ═══════════════════════════════════════════════════════════════════════════════

/// The main chat-bubble logo rendered as a widget.
class _ChatBubbleLogo extends StatelessWidget {
  final double size;
  const _ChatBubbleLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.1),
      painter: _ChatBubblePainter(),
    );
  }
}

class _ChatBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height * 0.85; // bubble portion
    const tailH = 0.18; // tail height as fraction

    // Shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF312E81).withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(_bubble(w, h, tailH, const Offset(0, 3)), shadowPaint);

    // Fill
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0xFFE0E7FF)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(_bubble(w, h, tailH), fillPaint);

    // Faint text lines
    final barPaint = Paint()..color = const Color(0xFF4F46E5).withOpacity(0.10);
    final barW = w * 0.55;
    final barH = h * 0.045;
    final barR = Radius.circular(barH / 2);
    final barX = w * 0.18;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barX, h * 0.28, barW * 0.6, barH), barR),
      barPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barX, h * 0.42, barW, barH), barR),
      barPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barX, h * 0.56, barW * 0.45, barH), barR),
      barPaint,
    );

    // "LM" text
    final tp = TextPainter(
      text: const TextSpan(
        text: 'LM',
        style: TextStyle(
          color: Color(0xFF4F46E5),
          fontSize: 52,
          fontWeight: FontWeight.w800,
          letterSpacing: -2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w / 2 - tp.width / 2, h * 0.32 - tp.height * 0.15));
  }

  Path _bubble(double w, double h, double tailFrac, [Offset d = Offset.zero]) {
    final r = w * 0.14; // corner radius
    final tailTip = Offset(w * 0.30 + d.dx, h * (1 + tailFrac) + d.dy);
    return Path()
      ..moveTo(r + d.dx, d.dy)
      ..lineTo(w - r + d.dx, d.dy)
      ..quadraticBezierTo(w + d.dx, d.dy, w + d.dx, r + d.dy)
      ..lineTo(w + d.dx, h - r + d.dy)
      ..quadraticBezierTo(w + d.dx, h + d.dy, w - r + d.dx, h + d.dy)
      ..lineTo(w * 0.42 + d.dx, h + d.dy)
      ..lineTo(tailTip.dx, tailTip.dy)
      ..lineTo(w * 0.36 + d.dx, h + d.dy)
      ..lineTo(r + d.dx, h + d.dy)
      ..quadraticBezierTo(d.dx, h + d.dy, d.dx, h - r + d.dy)
      ..lineTo(d.dx, r + d.dy)
      ..quadraticBezierTo(d.dx, d.dy, r + d.dx, d.dy)
      ..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// An AI sparkle (4-point star) that pulses with [animation].
class _AnimatedSparkle extends StatelessWidget {
  final Animation<double> animation;
  final double size;
  final double phaseOffset;

  const _AnimatedSparkle({
    required this.animation,
    required this.size,
    this.phaseOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = (animation.value + phaseOffset) % 1.0;
        final scale = 0.6 + 0.4 * math.sin(t * math.pi);
        return Transform.scale(
          scale: scale,
          child: CustomPaint(
            size: Size(size, size),
            painter: _SparklePainter(color: Colors.white),
          ),
        );
      },
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;
  _SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final cp = r * 0.18;

    final path = Path()
      ..moveTo(cx, cy - r)
      ..quadraticBezierTo(cx + cp, cy - cp, cx + r, cy)
      ..quadraticBezierTo(cx + cp, cy + cp, cx, cy + r)
      ..quadraticBezierTo(cx - cp, cy + cp, cx - r, cy)
      ..quadraticBezierTo(cx - cp, cy - cp, cx, cy - r)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.color != color;
}

/// Subtle dot-grid background suggesting a neural network.
class _NeuralDots extends StatelessWidget {
  const _NeuralDots();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _NeuralDotsPainter(),
    );
  }
}

class _NeuralDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.06);
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;

    final stepX = size.width / 6;
    final stepY = size.height / 8;

    final dots = <Offset>[];

    for (int col = 1; col <= 5; col++) {
      for (int row = 1; row <= 7; row++) {
        final x = col * stepX;
        final y = row * stepY;
        // Skip the center zone to leave room for the logo
        if ((x - size.width / 2).abs() < stepX * 1.2 &&
            (y - size.height / 2).abs() < stepY * 1.2) {
          continue;
        }
        dots.add(Offset(x, y));
        canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
      }
    }

    // Draw some connections between neighbouring dots
    for (int i = 0; i < dots.length; i++) {
      for (int j = i + 1; j < dots.length; j++) {
        final d = (dots[i] - dots[j]).distance;
        if (d < stepX * 1.6 && d > stepX * 0.8) {
          canvas.drawLine(dots[i], dots[j], linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A gentle horizontal shimmer that slides across the bottom of the screen.
class _ShimmerBar extends StatelessWidget {
  final Animation<double> animation;
  const _ShimmerBar({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Center(
          child: Container(
            width: 120,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: const [
                  Color(0x00FFFFFF),
                  Color(0x59FFFFFF),
                  Color(0x00FFFFFF),
                ],
                stops: [
                  (animation.value - 0.3).clamp(0.0, 1.0),
                  animation.value,
                  (animation.value + 0.3).clamp(0.0, 1.0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
