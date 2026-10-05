import 'package:flutter/material.dart';

class AppIcon extends StatelessWidget {
  const AppIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1024,
      height: 1024,
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1),
        borderRadius: BorderRadius.circular(180),
      ),
      child: Stack(
        children: [
          // Neural network visualization
          Positioned.fill(
            child: CustomPaint(
              painter: NeuralNetworkPainter(),
            ),
          ),
          // Main text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'LM',
                      style: TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 120),
                Text(
                  'MINI',
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NeuralNetworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw nodes
    canvas.drawCircle(center + const Offset(-80, -80), 15, nodePaint);
    canvas.drawCircle(center + const Offset(80, -80), 15, nodePaint);
    canvas.drawCircle(center + const Offset(-80, 80), 15, nodePaint);
    canvas.drawCircle(center + const Offset(80, 80), 15, nodePaint);
    
    canvas.drawCircle(center + const Offset(-120, 0), 12, nodePaint);
    canvas.drawCircle(center + const Offset(120, 0), 12, nodePaint);
    canvas.drawCircle(center + const Offset(0, -120), 12, nodePaint);
    canvas.drawCircle(center + const Offset(0, 120), 12, nodePaint);

    // Draw connections
    canvas.drawLine(center, center + const Offset(-80, -80), paint);
    canvas.drawLine(center, center + const Offset(80, -80), paint);
    canvas.drawLine(center, center + const Offset(-80, 80), paint);
    canvas.drawLine(center, center + const Offset(80, 80), paint);
    
    canvas.drawLine(center + const Offset(-80, -80), center + const Offset(-120, 0), paint);
    canvas.drawLine(center + const Offset(80, -80), center + const Offset(120, 0), paint);
    canvas.drawLine(center + const Offset(-80, 80), center + const Offset(-120, 0), paint);
    canvas.drawLine(center + const Offset(80, 80), center + const Offset(120, 0), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
