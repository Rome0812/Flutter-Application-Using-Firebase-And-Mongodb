import 'package:flutter/material.dart';
import 'dart:math';


class LoadingOverlay {
  static void show(BuildContext context, {String message = "Loading..."}) {
    showDialog(
      context: context,
      barrierDismissible: false, // prevent closing
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated sunburst loading icon
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: _AnimatedSunburst(),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
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

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

// Animated sunburst widget
class _AnimatedSunburst extends StatefulWidget {
  @override
  _AnimatedSunburstState createState() => _AnimatedSunburstState();
}

class _AnimatedSunburstState extends State<_AnimatedSunburst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * pi,
          child: CustomPaint(
            painter: SunburstPainter(),
          ),
        );
      },
    );
  }
}

// Custom painter for the sunburst loading icon
class SunburstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Draw 8 rays in a sunburst pattern
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (pi / 180); // Convert to radians
      final startPoint = Offset(
        center.dx + (radius - 4) * cos(angle),
        center.dy + (radius - 4) * sin(angle),
      );
      final endPoint = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
