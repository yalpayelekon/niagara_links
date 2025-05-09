import 'dart:math';
import 'package:flutter/material.dart';
import 'package:niagara_links/models/component.dart';
import 'package:niagara_links/models/connection.dart';
import 'package:niagara_links/models/enums.dart';
import 'package:niagara_links/models/port.dart';
import 'component_widget.dart';
import 'manager.dart';

class ConnectionPainter extends CustomPainter {
  final FlowManager flowManager;
  final Map<String, Offset> componentPositions;
  final Map<String, GlobalKey> componentKeys;
  final PortDragInfo? tempLineStartInfo;
  final Offset? tempLineEndPoint;

  static const double portVerticalOffset = 28.0; // Title section height
  static const double portHeight = 36.0; // Height of each port row
  static const double itemPadding = 8.0; // Padding around the item

  ConnectionPainter({
    required this.flowManager,
    required this.componentPositions,
    required this.componentKeys,
    this.tempLineStartInfo,
    this.tempLineEndPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Paint for permanent connections
    final Paint connectionPaint = Paint()
      ..color = Colors.indigo
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Paint for temporary drag line
    final Paint tempLinePaint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw all permanent connections
    for (final connection in flowManager.connections) {
      _drawConnection(canvas, connection, connectionPaint);
    }

    // Draw temporary line while dragging
    if (tempLineStartInfo != null && tempLineEndPoint != null) {
      _drawTempLine(
          canvas, tempLineStartInfo!, tempLineEndPoint!, tempLinePaint);
    }
  }

  void _drawConnection(Canvas canvas, Connection connection, Paint paint) {
    final Component? fromComponent =
        flowManager.findComponentById(connection.fromComponentId);
    final Component? toComponent =
        flowManager.findComponentById(connection.toComponentId);

    if (fromComponent == null || toComponent == null) return;

    final Offset? fromPosition = componentPositions[connection.fromComponentId];
    final Offset? toPosition = componentPositions[connection.toComponentId];

    if (fromPosition == null || toPosition == null) return;

    // Get port info from the items
    final fromPort = fromComponent.ports.length > connection.fromPortIndex
        ? fromComponent.ports[connection.fromPortIndex]
        : null;

    final toPort = toComponent.ports.length > connection.toPortIndex
        ? toComponent.ports[connection.toPortIndex]
        : null;

    if (fromPort == null || toPort == null) return;

    // Calculate port positions
    final fromPortPos = _calculatePortPosition(
        fromPosition, connection.fromPortIndex, !fromPort.isInput);

    final toPortPos = _calculatePortPosition(
        toPosition, connection.toPortIndex, !toPort.isInput);

    // Draw connection line with arrow
    _drawArrowLine(canvas, fromPortPos, toPortPos, paint);

    // Draw the value being transferred based on port type
    _drawTransferredValue(canvas, fromPortPos, toPortPos, fromPort);
  }

  void _drawTempLine(
      Canvas canvas, PortDragInfo startInfo, Offset endPoint, Paint paint) {
    final Component? fromComponent =
        flowManager.findComponentById(startInfo.componentId);
    if (fromComponent == null) return;

    final Offset? fromPosition = componentPositions[startInfo.componentId];
    if (fromPosition == null) return;

    final fromPort = fromComponent.ports.length > startInfo.portIndex
        ? fromComponent.ports[startInfo.portIndex]
        : null;

    if (fromPort == null) return;

    // Calculate port position
    final fromPortPos = _calculatePortPosition(fromPosition, fromPort.index,
        !fromPort.isInput // true for output (right side)
        );

    // Draw dashed line
    _drawDashedLine(canvas, fromPortPos, endPoint, paint);
  }

  Offset _calculatePortPosition(
      Offset itemPosition, int portIndex, bool isRightSide) {
    // Get the center X of the item (estimated width is 160 + padding*2)
    final double itemWidth = 160.0 + (itemPadding * 2);

    // X position depends on whether it's an input (left) or output (right) port
    final double portX = isRightSide
        ? itemPosition.dx + itemWidth // Right side for outputs
        : itemPosition.dx; // Left side for inputs

    // Y position is based on the port index
    final double portY = itemPosition.dy +
        itemPadding +
        portVerticalOffset +
        (portIndex * portHeight) +
        (portHeight / 2);

    return Offset(portX, portY);
  }

  void _drawArrowLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    // Draw the main line
    canvas.drawLine(start, end, paint);

    // Draw arrow at end
    final double arrowSize = 8.0;
    final double angle = atan2(end.dy - start.dy, end.dx - start.dx);

    final Path arrowPath = Path();
    arrowPath.moveTo(
      end.dx - arrowSize * cos(angle - pi / 7),
      end.dy - arrowSize * sin(angle - pi / 7),
    );
    arrowPath.lineTo(end.dx, end.dy);
    arrowPath.lineTo(
      end.dx - arrowSize * cos(angle + pi / 7),
      end.dy - arrowSize * sin(angle + pi / 7),
    );

    canvas.drawPath(arrowPath, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 5;
    const double dashSpace = 3;

    // Calculate dash count based on line length
    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double distance = sqrt(dx * dx + dy * dy);

    final int dashCount = (distance / (dashWidth + dashSpace)).floor();
    if (dashCount <= 0) return;

    final double stepX = dx / dashCount;
    final double stepY = dy / dashCount;

    // Draw background line for better visibility
    final Paint backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = paint.strokeWidth + 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = paint.strokeCap;

    canvas.drawLine(start, end, backgroundPaint);

    // Draw dashed line
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

  void _drawTransferredValue(
      Canvas canvas, Offset start, Offset end, Port port) {
    // Calculate midpoint of the line
    final Offset midpoint = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    // Create background for the value text
    final Paint backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    // Get color based on port type
    Color borderColor;
    String displayValue;

    switch (port.type) {
      case PortType.boolean:
        borderColor = (port.value as bool)
            ? Colors.green.withOpacity(0.6)
            : Colors.red.withOpacity(0.6);
        displayValue = (port.value as bool) ? 'T' : 'F';
        break;
      case PortType.number:
        borderColor = Colors.teal.withOpacity(0.6);
        num value = port.value as num;
        displayValue = value.toStringAsFixed(1);
        break;
      case PortType.string:
        borderColor = Colors.orange.withOpacity(0.6);
        displayValue =
            '"${(port.value as String).length > 3 ? '${(port.value as String).substring(0, 3)}...' : port.value as String}"';
        break;
      case PortType.any:
        borderColor = Colors.purple.withOpacity(0.6);
        if (port.value == null) {
          displayValue = 'null';
        } else if (port.value is bool) {
          displayValue = (port.value as bool) ? 'T' : 'F';
        } else if (port.value is num) {
          displayValue = (port.value as num).toStringAsFixed(1);
        } else {
          displayValue = '${port.value}';
        }
        break;
    }

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw value bubble
    final double bubbleRadius = 14.0;
    canvas.drawCircle(midpoint, bubbleRadius, backgroundPaint);
    canvas.drawCircle(midpoint, bubbleRadius, borderPaint);

    // Prepare text painter for value
    final textSpan = TextSpan(
      text: displayValue,
      style: TextStyle(
        color: borderColor,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Center text in the bubble
    textPainter.paint(
      canvas,
      Offset(
        midpoint.dx - textPainter.width / 2,
        midpoint.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) {
    return true; // Simplifying - always repaint on state changes
  }
}
