import 'package:flutter/material.dart';
import 'package:niagara_links/draggable_lines_screen.dart';

class DraggableItem {
  final String id;
  Offset position; // Top-left position of the item
  final Color color;
  final GlobalKey widgetKey =
      GlobalKey(); // Key to get the size of the rendered widget
  final int numberOfRows;

  DraggableItem({
    required this.id,
    required this.position,
    this.color = Colors.blue,
    this.numberOfRows = DraggableInteractiveLinesExampleState
        .defaultNumberOfRows, // Using static const from state
  });
}
