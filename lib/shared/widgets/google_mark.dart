import 'package:flutter/material.dart';

class GoogleMark extends StatelessWidget {
  final double size;

  const GoogleMark({
    super.key,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleMarkPainter(),
      ),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.16;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    paint.color = _blue;
    canvas.drawArc(rect, -0.05, 1.05, false, paint);
    paint.color = _green;
    canvas.drawArc(rect, 1.0, 1.25, false, paint);
    paint.color = _yellow;
    canvas.drawArc(rect, 2.25, 0.9, false, paint);
    paint.color = _red;
    canvas.drawArc(rect, 3.15, 1.55, false, paint);

    paint.color = _blue;
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.52),
      Offset(size.width * 0.88, size.height * 0.52),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.88, size.height * 0.52),
      Offset(size.width * 0.77, size.height * 0.68),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
