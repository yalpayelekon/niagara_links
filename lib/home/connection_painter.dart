// connection_painter.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/component.dart';
import '../models/connection.dart';
import '../models/port.dart';
import '../models/port_type.dart';
import 'component_widget.dart';
import 'manager.dart';

class ConnectionPainter extends CustomPainter {
  final FlowManager flowManager;
  final Map<String, Offset> componentPositions;
  final Map<String, GlobalKey> componentKeys;
  final Map<String, double> componentWidths; // Add this
  final SlotDragInfo? tempLineStartInfo;
  final Offset? tempLineEndPoint;

  static const double rowVerticalOffset = 28.0; // Title section height
  static const double rowHeight = 36.0; // Height of each port row
  static const double itemPadding = 8.0; // Padding around the item

  ConnectionPainter({
    required this.flowManager,
    required this.componentPositions,
    required this.componentKeys,
    required this.componentWidths, // Add this
    this.tempLineStartInfo,
    this.tempLineEndPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint propertyPaint = Paint()
      ..color = Colors.indigo
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint actionPaint = Paint()
      ..color = Colors.amber.shade700
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint topicPaint = Paint()
      ..color = Colors.green.shade700
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint tempLinePaint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final connection in flowManager.connections) {
      _drawConnection(
          canvas, connection, propertyPaint, actionPaint, topicPaint);
    }

    if (tempLineStartInfo != null && tempLineEndPoint != null) {
      _drawTempLine(
          canvas, tempLineStartInfo!, tempLineEndPoint!, tempLinePaint);
    }
  }

  void _drawConnection(Canvas canvas, Connection connection,
      Paint propertyPaint, Paint actionPaint, Paint topicPaint) {
    final Component? fromComponent =
        flowManager.findComponentById(connection.fromComponentId);
    final Component? toComponent =
        flowManager.findComponentById(connection.toComponentId);

    if (fromComponent == null || toComponent == null) return;

    final Offset? fromPosition = componentPositions[connection.fromComponentId];
    final Offset? toPosition = componentPositions[connection.toComponentId];

    if (fromPosition == null || toPosition == null) return;

    Slot? fromSlot = fromComponent.getSlotByIndex(connection.fromPortIndex);
    Slot? toSlot = toComponent.getSlotByIndex(connection.toPortIndex);

    if (fromSlot == null || toSlot == null) return;

    Paint paint;
    if (fromSlot is Property && toSlot is Property) {
      paint = propertyPaint;
    } else if (fromSlot is Action || toSlot is Action) {
      paint = actionPaint;
    } else if (fromSlot is Topic || toSlot is Topic) {
      paint = topicPaint;
    } else {
      paint = propertyPaint; // default
    }

    bool isFromOutput = false;
    if (fromSlot is Property) {
      isFromOutput = !fromSlot.isInput;
    } else if (fromSlot is Action) {
      isFromOutput = false; // Actions are always inputs
    } else if (fromSlot is Topic) {
      isFromOutput = true; // Topics are always outputs
    }

    bool isToOutput = false;
    if (toSlot is Property) {
      isToOutput = !toSlot.isInput;
    } else if (toSlot is Action) {
      isToOutput = false; // Actions are always inputs
    } else if (toSlot is Topic) {
      isToOutput = true; // Topics are always outputs
    }

    int fromRowIndex =
        _calculateRowIndex(fromComponent, connection.fromPortIndex);
    int toRowIndex = _calculateRowIndex(toComponent, connection.toPortIndex);

    final fromSlotPos = _calculateSlotPosition(
        fromPosition, fromRowIndex, isFromOutput, fromComponent.id);

    final toSlotPos = _calculateSlotPosition(
        toPosition, toRowIndex, isToOutput, toComponent.id);

    _drawArrowLine(canvas, fromSlotPos, toSlotPos, paint);

    if (fromSlot is Property) {
      _drawTransferredValue(canvas, fromSlotPos, toSlotPos, fromSlot);
    } else if (fromSlot is Topic && fromSlot.lastEvent != null) {
      _drawTransferredTopicEvent(canvas, fromSlotPos, toSlotPos, fromSlot);
    }
  }

  int _calculateRowIndex(Component component, int slotIndex) {
    Slot? slot = component.getSlotByIndex(slotIndex);
    if (slot == null) return 0;

    int propertiesBeforeIndex = 0;
    for (var prop in component.properties) {
      if (prop.index == slotIndex) break;
      propertiesBeforeIndex++;
    }

    int actionsBeforeIndex = 0;
    for (var action in component.actions) {
      if (action.index == slotIndex) break;
      actionsBeforeIndex++;
    }

    int topicsBeforeIndex = 0;
    for (var topic in component.topics) {
      if (topic.index == slotIndex) break;
      topicsBeforeIndex++;
    }

    int rowIndex = 0;

    if (component.properties.isNotEmpty &&
        component.properties.contains(slot)) {
      rowIndex = propertiesBeforeIndex;
      if (component.actions.isNotEmpty || component.topics.isNotEmpty) {
        rowIndex += 1; // Add 1 for the section header
      }
    } else if (component.actions.isNotEmpty &&
        component.actions.contains(slot)) {
      rowIndex = component.properties.length + actionsBeforeIndex;
      if (component.properties.isNotEmpty) {
        rowIndex += 1; // Add 1 for the section header
      }
      if (component.topics.isNotEmpty) {
        rowIndex += 1; // Add 1 for the section header
      }
    } else if (component.topics.isNotEmpty && component.topics.contains(slot)) {
      rowIndex = component.properties.length +
          component.actions.length +
          topicsBeforeIndex;
      if (component.properties.isNotEmpty) {
        rowIndex += 1; // Add 1 for the section header
      }
      if (component.actions.isNotEmpty) {
        rowIndex += 1; // Add 1 for the section header
      }
    }

    return rowIndex;
  }

  void _drawTempLine(
      Canvas canvas, SlotDragInfo startInfo, Offset endPoint, Paint paint) {
    final Component? fromComponent =
        flowManager.findComponentById(startInfo.componentId);
    if (fromComponent == null) return;

    final Offset? fromPosition = componentPositions[startInfo.componentId];
    if (fromPosition == null) return;

    Slot? fromSlot = fromComponent.getSlotByIndex(startInfo.slotIndex);
    if (fromSlot == null) return;

    bool isOutput = false;
    if (fromSlot is Property) {
      isOutput = !fromSlot.isInput;
    } else if (fromSlot is Topic) {
      isOutput = true; // Topics are always outputs
    }

    int rowIndex = _calculateRowIndex(fromComponent, startInfo.slotIndex);

    final fromSlotPos = _calculateSlotPosition(
        fromPosition, rowIndex, isOutput, fromComponent.id);

    _drawDashedLine(canvas, fromSlotPos, endPoint, paint);
  }

  Offset _calculateSlotPosition(
      Offset itemPosition, int rowIndex, bool isRightSide, String componentId) {
    final double itemWidth = componentWidths[componentId] ?? 160.0;
    final double totalWidth = itemWidth + (itemPadding * 2);

    final double portX = isRightSide
        ? itemPosition.dx + totalWidth // Right side for outputs
        : itemPosition.dx; // Left side for inputs

    final double portY = itemPosition.dy +
        itemPadding +
        rowVerticalOffset +
        (rowIndex * rowHeight) +
        (rowHeight / 2);

    return Offset(portX, portY);
  }

  void _drawArrowLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);

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

    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double distance = sqrt(dx * dx + dy * dy);

    final int dashCount = (distance / (dashWidth + dashSpace)).floor();
    if (dashCount <= 0) return;

    final double stepX = dx / dashCount;
    final double stepY = dy / dashCount;

    final Paint backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = paint.strokeWidth + 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = paint.strokeCap;

    canvas.drawLine(start, end, backgroundPaint);

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
      Canvas canvas, Offset start, Offset end, Property property) {
    final Offset midpoint = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    final Paint backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    Color? borderColor;
    String? displayValue;

    switch (property.type.type) {
      case PortType.BOOLEAN:
        borderColor = (property.value as bool)
            ? Colors.green.withOpacity(0.6)
            : Colors.red.withOpacity(0.6);
        displayValue = (property.value as bool) ? 'T' : 'F';
        break;
      case PortType.NUMERIC:
        borderColor = Colors.teal.withOpacity(0.6);
        num value = property.value as num;
        displayValue = value.toStringAsFixed(1);
        break;
      case PortType.STRING:
        borderColor = Colors.orange.withOpacity(0.6);
        displayValue =
            '"${(property.value as String).length > 3 ? '${(property.value as String).substring(0, 3)}...' : property.value as String}"';
        break;
      case PortType.ANY:
        borderColor = Colors.purple.withOpacity(0.6);
        if (property.value == null) {
          displayValue = 'null';
        } else if (property.value is bool) {
          displayValue = (property.value as bool) ? 'T' : 'F';
        } else if (property.value is num) {
          displayValue = (property.value as num).toStringAsFixed(1);
        } else {
          displayValue = '${property.value}';
        }
        break;
    }

    final Paint borderPaint = Paint()
      ..color = borderColor!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double bubbleRadius = 14.0;
    canvas.drawCircle(midpoint, bubbleRadius, backgroundPaint);
    canvas.drawCircle(midpoint, bubbleRadius, borderPaint);

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
    textPainter.paint(
      canvas,
      Offset(
        midpoint.dx - textPainter.width / 2,
        midpoint.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawTransferredTopicEvent(
      Canvas canvas, Offset start, Offset end, Topic topic) {
    final Offset midpoint = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    final Paint backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    Color borderColor = Colors.green.withOpacity(0.6);
    String displayValue = _formatEventValue(topic.lastEvent);

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double bubbleSize = 20.0;
    final Rect bubbleRect = Rect.fromCenter(
      center: midpoint,
      width: bubbleSize,
      height: bubbleSize,
    );
    canvas.drawRect(bubbleRect, backgroundPaint);
    canvas.drawRect(bubbleRect, borderPaint);

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

    textPainter.paint(
      canvas,
      Offset(
        midpoint.dx - textPainter.width / 2,
        midpoint.dy - textPainter.height / 2,
      ),
    );
  }

  String _formatEventValue(dynamic value) {
    if (value == null) return "null";
    if (value is bool) return value ? "T" : "F";
    if (value is num) return value.toStringAsFixed(1);
    if (value is String) {
      return '"${value.length > 3 ? '${value.substring(0, 3)}...' : value}"';
    }
    return value.toString();
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) {
    return true; // Simplifying - always repaint on state changes
  }
}
