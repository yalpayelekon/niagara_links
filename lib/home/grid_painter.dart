// lib/home/grid_painter.dart
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

class GridPainter extends CustomPainter {
  final Color lineColor;
  final double gridSize;
  final double lineWidth;
  final Matrix4 transform;

  GridPainter({
    this.lineColor = Colors.grey,
    this.gridSize = 50.0,
    this.lineWidth = 0.5,
    required this.transform,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = lineColor.withOpacity(0.3)
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    // Get the transformation parameters
    double scale = _getScaleFromTransform(transform);

    // Get the visible area in canvas coordinates
    Offset topLeft = _transformOffset(Offset.zero, transform);
    Offset bottomRight =
        _transformOffset(Offset(size.width, size.height), transform);

    // Adjust grid size based on zoom level
    double effectiveGridSize = gridSize;
    if (scale < 0.5) {
      effectiveGridSize = gridSize * 2;
    } else if (scale > 1.5) {
      effectiveGridSize = gridSize / 2;
    }

    // Calculate grid start and end points, ensuring we cover the entire visible area
    double startX = (topLeft.dx ~/ effectiveGridSize) * effectiveGridSize;
    double endX = bottomRight.dx + effectiveGridSize;
    double startY = (topLeft.dy ~/ effectiveGridSize) * effectiveGridSize;
    double endY = bottomRight.dy + effectiveGridSize;

    // Draw vertical grid lines
    for (double x = startX; x <= endX; x += effectiveGridSize) {
      canvas.drawLine(
        Offset(x, topLeft.dy),
        Offset(x, bottomRight.dy),
        paint,
      );
    }

    // Draw horizontal grid lines
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
        oldDelegate.lineColor != lineColor;
  }
}
