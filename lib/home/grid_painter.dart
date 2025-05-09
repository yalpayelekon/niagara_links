import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

class GridPainter extends CustomPainter {
  final Color lineColor;
  final Color backgroundColor;
  final double gridSize;
  final double lineWidth;
  final Matrix4 transform;

  GridPainter({
    this.lineColor = Colors.grey,
    this.backgroundColor = Colors.white, // Add background color option
    this.gridSize = 50.0,
    this.lineWidth = 0.5,
    required this.transform,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    final Paint paint = Paint()
      ..color = lineColor.withOpacity(0.3)
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    double scale = _getScaleFromTransform(transform);

    Offset topLeft = _transformOffset(Offset.zero, transform);
    Offset bottomRight =
        _transformOffset(Offset(size.width, size.height), transform);

    double effectiveGridSize = gridSize;
    if (scale < 0.5) {
      effectiveGridSize = gridSize * 2;
    } else if (scale > 1.5) {
      effectiveGridSize = gridSize / 2;
    }

    double startX = (topLeft.dx ~/ effectiveGridSize) * effectiveGridSize;
    double endX = bottomRight.dx + effectiveGridSize;
    double startY = (topLeft.dy ~/ effectiveGridSize) * effectiveGridSize;
    double endY = bottomRight.dy + effectiveGridSize;

    for (double x = startX; x <= endX; x += effectiveGridSize) {
      canvas.drawLine(
        Offset(x, topLeft.dy),
        Offset(x, bottomRight.dy),
        paint,
      );
    }

    for (double y = startY; y <= endY; y += effectiveGridSize) {
      canvas.drawLine(
        Offset(topLeft.dx, y),
        Offset(bottomRight.dx, y),
        paint,
      );
    }

    // Draw origin markers with more emphasis
    final Paint originPaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..strokeWidth = 2.0;

    // Draw x-axis
    canvas.drawLine(
      Offset(topLeft.dx, 0),
      Offset(bottomRight.dx, 0),
      originPaint,
    );

    // Draw y-axis
    canvas.drawLine(
      Offset(0, topLeft.dy),
      Offset(0, bottomRight.dy),
      originPaint,
    );
  }

  Offset _transformOffset(Offset offset, Matrix4 transform) {
    final Matrix4 inverseTransform = Matrix4.inverted(transform);
    final vector_math.Vector3 untransformed =
        inverseTransform.transform3(vector_math.Vector3(
      offset.dx,
      offset.dy,
      0.0,
    ));

    return Offset(untransformed.x, untransformed.y);
  }

  double _getScaleFromTransform(Matrix4 transform) {
    return transform.getMaxScaleOnAxis();
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.transform != transform ||
        oldDelegate.gridSize != gridSize ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
