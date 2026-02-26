import 'package:flutter/material.dart';

class UrbanFixLogo extends StatelessWidget {
  final double size;

  const UrbanFixLogo({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final halfWidth = size.width / 2;
    final halfHeight = size.height / 2;
    // Add a small gap between quadrants
    final gap = size.width * 0.05; 

    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Top Left: Blue
    paint.color = const Color(0xFF4285F4); // Google Blue-ish
    // Draw a shape roughly standard
    Path tlPath = Path()
      ..moveTo(center.dx - gap, center.dy - gap)
      ..lineTo(0, center.dy - gap)
      ..lineTo(0, 0) // Top left corner
      ..lineTo(center.dx - gap, 0)
      ..close();
    // Actually, looking at the image, they are soft rounded shapes.
    // Let's use rounded rects for simplicity to get the "feel".
    
    // Top Left (Blue)
    paint.color = const Color(0xFF3B82F6);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, halfWidth - gap, halfHeight - gap),
        topLeft: Radius.circular(size.width * 0.1),
        bottomRight: Radius.circular(size.width * 0.05),
      ),
      paint,
    );

    // Top Right (Green)
    paint.color = const Color(0xFF10B981);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(halfWidth + gap, 0, halfWidth - gap, halfHeight - gap),
        topRight: Radius.circular(size.width * 0.3), // More rounded
        bottomLeft: Radius.circular(size.width * 0.05),
      ),
      paint,
    );

    // Bottom Right (Red)
    paint.color = const Color(0xFFEF4444);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(halfWidth + gap, halfHeight + gap, halfWidth - gap, halfHeight - gap),
        bottomRight: Radius.circular(size.width * 0.1),
        topLeft: Radius.circular(size.width * 0.05),
      ),
      paint,
    );
    
    // Bottom Left (Grey/White)
    paint.color = const Color(0xFF9CA3AF);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, halfHeight + gap, halfWidth - gap, halfHeight - gap),
        bottomLeft: Radius.circular(size.width * 0.1),
        topRight: Radius.circular(size.width * 0.05),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
