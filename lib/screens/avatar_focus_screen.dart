import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/persona_avatar.dart';

/// Face crop result for circular bubble avatars.
class AvatarFocusResult {
  final double x;
  final double y;
  final double scale;

  const AvatarFocusResult({
    required this.x,
    required this.y,
    this.scale = 1.0,
  });

  Alignment get alignment => Alignment(x, y);
}

/// Pan + pinch-zoom face into a circle that matches chat bubble geometry.
class AvatarFocusScreen extends StatefulWidget {
  final String imagePath;
  final Alignment initialAlignment;
  final double initialScale;

  const AvatarFocusScreen({
    super.key,
    required this.imagePath,
    this.initialAlignment = const Alignment(0, -0.28),
    this.initialScale = 1.35,
  });

  static Future<AvatarFocusResult?> open(
    BuildContext context, {
    required String imagePath,
    Alignment initialAlignment = const Alignment(0, -0.28),
    double initialScale = 1.35,
  }) {
    return Navigator.push<AvatarFocusResult>(
      context,
      MaterialPageRoute(
        builder: (_) => AvatarFocusScreen(
          imagePath: imagePath,
          initialAlignment: initialAlignment,
          initialScale: initialScale,
        ),
      ),
    );
  }

  @override
  State<AvatarFocusScreen> createState() => _AvatarFocusScreenState();
}

class _AvatarFocusScreenState extends State<AvatarFocusScreen> {
  static const double _minScale = 1.0;
  static const double _maxScale = 3.5;

  late Alignment _alignment;
  late double _scale;
  double? _baseScale;
  Offset? _lastFocal;

  @override
  void initState() {
    super.initState();
    _alignment = widget.initialAlignment;
    _scale = widget.initialScale.clamp(_minScale, _maxScale);
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = _scale;
    _lastFocal = details.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details, double viewportSize) {
    final nextScale =
        ((_baseScale ?? _scale) * details.scale).clamp(_minScale, _maxScale);

    // Pan from focal-point delta (works for 1-finger drag and 2-finger move).
    var nextAlign = _alignment;
    if (_lastFocal != null && viewportSize > 0) {
      final delta = details.focalPoint - _lastFocal!;
      // Higher zoom → smaller alignment steps feel natural.
      final sensitivity = 2.2 / (nextScale * viewportSize / 2);
      nextAlign = Alignment(
        (_alignment.x - delta.dx * sensitivity).clamp(-1.0, 1.0),
        (_alignment.y - delta.dy * sensitivity).clamp(-1.0, 1.0),
      );
    }

    setState(() {
      _scale = nextScale;
      _alignment = nextAlign;
      _lastFocal = details.focalPoint;
    });
  }

  void _bumpScale(double delta) {
    setState(() {
      _scale = (_scale + delta).clamp(_minScale, _maxScale);
    });
  }

  AvatarFocusResult get _result => AvatarFocusResult(
        x: _alignment.x,
        y: _alignment.y,
        scale: _scale,
      );

  @override
  Widget build(BuildContext context) {
    final file = File(widget.imagePath);
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Choose face for bubbles'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _result),
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Large circle uses the same PersonaAvatar geometry as bubbles.
                final viewport = math.min(
                  constraints.maxWidth * 0.78,
                  constraints.maxHeight * 0.62,
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Dim backdrop of full image
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.28,
                        child: Image.file(
                          file,
                          fit: BoxFit.cover,
                          alignment: _alignment,
                        ),
                      ),
                    ),
                    Center(
                      child: GestureDetector(
                        onScaleStart: _onScaleStart,
                        onScaleUpdate: (d) => _onScaleUpdate(d, viewport),
                        child: Container(
                          width: viewport,
                          height: viewport,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.92),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: PersonaAvatar(
                            imagePath: widget.imagePath,
                            radius: viewport / 2,
                            alignment: _alignment,
                            scale: _scale,
                            backgroundColor: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 16,
                      child: Text(
                        'Pinch to zoom · drag to move the face.\nWhat you see in the circle is the chat bubble.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 14,
                          height: 1.35,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomPad * 0.15),
              child: Row(
                children: [
                  _ZoomChip(
                    icon: Icons.remove_rounded,
                    onTap: () => _bumpScale(-0.2),
                  ),
                  const SizedBox(width: 8),
                  _ZoomChip(
                    icon: Icons.add_rounded,
                    onTap: () => _bumpScale(0.2),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Bubble preview',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Same widget + params as the large circle (just smaller).
                  PersonaAvatar(
                    imagePath: widget.imagePath,
                    radius: 28,
                    alignment: _alignment,
                    scale: _scale,
                    backgroundColor: Colors.grey.shade900,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomChip({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
