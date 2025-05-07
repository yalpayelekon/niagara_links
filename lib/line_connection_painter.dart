import 'dart:math';
import 'package:flutter/material.dart';
import 'package:niagara_links/draggable_item.dart';
import 'package:niagara_links/draggable_lines_screen.dart';
import 'package:niagara_links/models.dart';

class LineConnectionPainter extends CustomPainter {
  final List<DraggableItem> items;
  final List<ItemConnection> connections;
  final DraggableItem? Function(String id) findItemByIdCallback;
  final double rowHeight;
  final double itemExternalPadding;
  final double itemTitleSectionHeight;

  // Added: For drawing temporary line while dragging
  final PortDragInfo? tempLineStartInfo;
  final Offset? tempLineEndPoint;

  LineConnectionPainter({
    required this.items,
    required this.connections,
    required this.findItemByIdCallback,
    required this.rowHeight,
    required this.itemExternalPadding,
    required this.itemTitleSectionHeight,
    this.tempLineStartInfo,
    this.tempLineEndPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.indigo[700]!
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // Rounded ends for lines

    final arrowPaint = Paint()
      ..color = Colors.indigo[700]!
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    // Dashed line paint for the temporary line
    final dashedPaint = Paint()
      ..color = Colors.indigo[500]!
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw temp line background (slightly wider)
    final tempLineBackgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final connection in connections) {
      final DraggableItem? fromItem = findItemByIdCallback(
        connection.fromItemId,
      );
      final DraggableItem? toItem = findItemByIdCallback(connection.toItemId);

      if (fromItem != null && toItem != null) {
        // Calculate X coordinate (center of the DraggableItem)
        double fromX = fromItem.position.dx;
        final fromContext = fromItem.widgetKey.currentContext;
        if (fromContext != null && fromContext.findRenderObject() != null) {
          final fromRenderBox = fromContext.findRenderObject() as RenderBox;
          fromX += fromRenderBox.size.width / 2;
        } else {
          fromX += (DraggableInteractiveLinesExampleState.rowAreaWidth +
                  2 * itemExternalPadding) /
              2; // Fallback
        }

        double toX = toItem.position.dx;
        final toContext = toItem.widgetKey.currentContext;
        if (toContext != null && toContext.findRenderObject() != null) {
          final toRenderBox = toContext.findRenderObject() as RenderBox;
          toX += toRenderBox.size.width / 2;
        } else {
          toX += (DraggableInteractiveLinesExampleState.rowAreaWidth +
                  2 * itemExternalPadding) /
              2; // Fallback
        }

        // Calculate Y coordinate (center of the specific row)
        // Y position of the top of the rows area (within the DraggableItem)
        final double fromRowsAreaStartY =
            fromItem.position.dy + itemExternalPadding + itemTitleSectionHeight;
        final double fromConnectionY = fromRowsAreaStartY +
            (connection.fromItemRowIndex * rowHeight) +
            (rowHeight / 2);

        final double toRowsAreaStartY =
            toItem.position.dy + itemExternalPadding + itemTitleSectionHeight;
        final double toConnectionY = toRowsAreaStartY +
            (connection.toItemRowIndex * rowHeight) +
            (rowHeight / 2);

        Offset p1 = Offset(fromX, fromConnectionY);
        Offset p2 = Offset(toX, toConnectionY);

        canvas.drawLine(p1, p2, paint);

        // Draw a small circle at the connection point on the "to" item's row
        // to indicate directionality or endpoint more clearly.
        // canvas.drawCircle(p2, 4, arrowPaint);
        // Or draw an arrow head
        final double angle = atan2(p2.dy - p1.dy, p2.dx - p1.dx);
        const double arrowSize = 8;
        final Path path = Path();
        path.moveTo(
          p2.dx - arrowSize * cos(angle - pi / 7),
          p2.dy - arrowSize * sin(angle - pi / 7),
        );
        path.lineTo(p2.dx, p2.dy);
        path.lineTo(
          p2.dx - arrowSize * cos(angle + pi / 7),
          p2.dy - arrowSize * sin(angle + pi / 7),
        );
        // path.close(); // Not closing for an open arrowhead
        canvas.drawPath(
          path,
          paint..style = PaintingStyle.stroke,
        ); // Use stroke for arrowhead lines
      }
    }

    // Draw the temporary line while dragging
    if (tempLineStartInfo != null && tempLineEndPoint != null) {
      final DraggableItem? fromItem =
          findItemByIdCallback(tempLineStartInfo!.itemId);

      if (fromItem != null) {
        // Calculate start port position (similar to the logic above)
        double fromX = fromItem.position.dx;
        final fromContext = fromItem.widgetKey.currentContext;
        if (fromContext != null && fromContext.findRenderObject() != null) {
          final fromRenderBox = fromContext.findRenderObject() as RenderBox;
          fromX += fromRenderBox.size.width / 2;
        } else {
          fromX += (DraggableInteractiveLinesExampleState.rowAreaWidth +
                  2 * itemExternalPadding) /
              2;
        }

        final double fromRowsAreaStartY =
            fromItem.position.dy + itemExternalPadding + itemTitleSectionHeight;
        final double fromConnectionY = fromRowsAreaStartY +
            (tempLineStartInfo!.rowIndex * rowHeight) +
            (rowHeight / 2);

        Offset p1 = Offset(fromX, fromConnectionY);
        Offset p2 = tempLineEndPoint!;

        // Draw dashed temporary line
        _drawDashedLine(canvas, p1, p2, dashedPaint);
      }
    }
  }

  // Helper method to draw a dashed line
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 5;
    const double dashSpace = 3;

    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double distance = sqrt(dx * dx + dy * dy);

    final int dashCount = (distance / (dashWidth + dashSpace)).floor();

    if (dashCount <= 0) return; // Guard against division by zero

    final double stepX = dx / dashCount;
    final double stepY = dy / dashCount;

    // First draw a slightly wider white line as background for better visibility
    final Paint bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = paint.strokeWidth + 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, bgPaint);

    // Then draw the dashed line
    for (int i = 0; i < dashCount; i++) {
      final double startX =
          start.dx + i * (stepX + stepX * dashSpace / dashWidth);
      final double startY =
          start.dy + i * (stepY + stepY * dashSpace / dashWidth);

      final double endX = startX + stepX;
      final double endY = startY + stepY;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant LineConnectionPainter oldDelegate) {
    return true; // Simplifies, repaints on any state change.
    // For optimization, compare relevant fields.
  }
}
