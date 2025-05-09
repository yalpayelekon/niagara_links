// In lib/draggable_item.dart

import 'package:flutter/material.dart';
import 'package:niagara_links/simple_line_example/draggable_lines_screen.dart';

class DraggableItem {
  String id; // Changed from final to allow editing
  Offset position; // Top-left position of the item
  Color color; // Changed from final to allow editing
  final GlobalKey widgetKey =
      GlobalKey(); // Key to get the size of the rendered widget
  int numberOfRows; // Changed from final to allow editing

  DraggableItem({
    required this.id,
    required this.position,
    this.color = Colors.blue,
    this.numberOfRows = DraggableInteractiveLinesExampleState
        .defaultNumberOfRows, // Using static const from state
  });
}
