import 'package:flutter/material.dart';
import 'dart:math'; // For Random

// Data class for a draggable item
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
    this.numberOfRows = _DraggableInteractiveLinesExampleState
        .defaultNumberOfRows, // Using static const from state
  });
}

// Data class for a connection between two items, now specifying rows
class ItemConnection {
  final String fromItemId;
  final int fromItemRowIndex;
  final String toItemId;
  final int toItemRowIndex;

  ItemConnection({
    required this.fromItemId,
    required this.fromItemRowIndex,
    required this.toItemId,
    required this.toItemRowIndex,
  });
}

// Added: Data class to track drag operation from port
class PortDragInfo {
  final String itemId;
  final int rowIndex;

  PortDragInfo(this.itemId, this.rowIndex);
}

class DraggableInteractiveLinesExample extends StatefulWidget {
  const DraggableInteractiveLinesExample({super.key});

  @override
  State<DraggableInteractiveLinesExample> createState() =>
      _DraggableInteractiveLinesExampleState();
}

class _DraggableInteractiveLinesExampleState
    extends State<DraggableInteractiveLinesExample> {
  // Layout constants for items
  static const double itemExternalPadding = 8.0;
  static const double itemTitleSectionHeight =
      28.0; // Height for item.id Text + internal spacing
  static const double rowHeight = 22.0; // Height of each row/port
  static const int defaultNumberOfRows = 5;
  static const double rowAreaWidth =
      130.0; // Width of the box containing rows/ports

  final Random _random = Random();

  // List of draggable items
  late List<DraggableItem> _items;

  // List of connections between items by their IDs and row indices
  late List<ItemConnection> _connections;

  // Added: Track current port being dragged
  PortDragInfo? _currentDraggedPort;

  // Added: Track temporary line while dragging
  Offset? _tempLineEndPoint;

  @override
  void initState() {
    super.initState();
    _items = [
      DraggableItem(
        id: 'Router X1',
        position: const Offset(100, 80),
        color: Colors.lightBlue[100]!,
      ),
      DraggableItem(
        id: 'Switch Y2',
        position: const Offset(400, 120),
        color: Colors.tealAccent[100]!,
      ),
      DraggableItem(
        id: 'Server Z3',
        position: const Offset(150, 350),
        color: Colors.purpleAccent[100]!,
        numberOfRows: 8,
      ), // Example with different row count
      DraggableItem(
        id: 'Firewall A4',
        position: const Offset(500, 400),
        color: Colors.orangeAccent[100]!,
      ),
    ];
    _connections = _generateRandomConnections(_items);
    _transformationController.value = Matrix4.identity();
  }

  List<ItemConnection> _generateRandomConnections(
    List<DraggableItem> currentItems,
  ) {
    if (currentItems.length < 2) return [];
    final List<ItemConnection> newConnections = [];
    final int numberOfConnections =
        currentItems.length + _random.nextInt(3); // Create N to N+2 connections

    for (int i = 0; i < numberOfConnections; i++) {
      DraggableItem fromItem =
          currentItems[_random.nextInt(currentItems.length)];
      DraggableItem toItem = currentItems[_random.nextInt(currentItems.length)];

      // Ensure fromItem and toItem are different
      while (toItem.id == fromItem.id) {
        toItem = currentItems[_random.nextInt(currentItems.length)];
      }

      newConnections.add(
        ItemConnection(
          fromItemId: fromItem.id,
          fromItemRowIndex: _random.nextInt(fromItem.numberOfRows),
          toItemId: toItem.id,
          toItemRowIndex: _random.nextInt(toItem.numberOfRows),
        ),
      );
    }
    return newConnections;
  }

  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _interactiveViewerChildKey = GlobalKey();

  final double _canvasWidth = 1500.0;
  final double _canvasHeight = 1000.0;

  DraggableItem? _findItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  // Added: Create a new connection between ports
  void _createConnection(PortDragInfo source, PortDragInfo target) {
    // Don't create connection if source and target are the same port
    if (source.itemId == target.itemId && source.rowIndex == target.rowIndex) {
      return;
    }

    // Check if this connection already exists
    bool connectionExists = _connections.any((connection) =>
        connection.fromItemId == source.itemId &&
        connection.fromItemRowIndex == source.rowIndex &&
        connection.toItemId == target.itemId &&
        connection.toItemRowIndex == target.rowIndex);

    if (!connectionExists) {
      setState(() {
        _connections.add(
          ItemConnection(
            fromItemId: source.itemId,
            fromItemRowIndex: source.rowIndex,
            toItemId: target.itemId,
            toItemRowIndex: target.rowIndex,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enhanced Draggable Lines')),
      body: InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: EdgeInsets.all(_canvasWidth / 1.5),
        minScale: 0.1,
        maxScale: 3.0,
        child: GestureDetector(
          // Added: Handle port dragging on the canvas
          onPanUpdate: (details) {
            if (_currentDraggedPort != null) {
              setState(() {
                final RenderBox? viewerChildRenderBox =
                    _interactiveViewerChildKey.currentContext
                        ?.findRenderObject() as RenderBox?;
                if (viewerChildRenderBox != null) {
                  _tempLineEndPoint = viewerChildRenderBox
                      .globalToLocal(details.globalPosition);
                }
              });
            }
          },
          onPanEnd: (details) {
            setState(() {
              _tempLineEndPoint = null;
              _currentDraggedPort = null;
            });
          },
          child: CustomPaint(
            key: _interactiveViewerChildKey,
            foregroundPainter: LineConnectionPainter(
              items: _items,
              connections: _connections,
              findItemByIdCallback: _findItemById,
              rowHeight: rowHeight,
              itemExternalPadding: itemExternalPadding,
              itemTitleSectionHeight: itemTitleSectionHeight,
              // Added: Temporary line info
              tempLineStartInfo: _currentDraggedPort,
              tempLineEndPoint: _tempLineEndPoint,
            ),
            child: SizedBox(
              width: _canvasWidth,
              height: _canvasHeight,
              child: Stack(
                children: _items.map((item) {
                  return Positioned(
                    left: item.position.dx,
                    top: item.position.dy,
                    child: Draggable<String>(
                      data: item.id,
                      feedback: Material(
                        elevation: 5.0,
                        color: Colors.transparent,
                        child: _buildItemWidget(item, isFeedback: true),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _buildItemWidget(item),
                      ),
                      onDragEnd: (details) {
                        final RenderBox? viewerChildRenderBox =
                            _interactiveViewerChildKey.currentContext
                                ?.findRenderObject() as RenderBox?;

                        if (viewerChildRenderBox != null) {
                          final Offset localOffset = viewerChildRenderBox
                              .globalToLocal(details.offset);
                          setState(() {
                            final draggedItem = _findItemById(item.id);
                            if (draggedItem != null) {
                              draggedItem.position = localOffset;
                            }
                          });
                        }
                      },
                      child: _buildItemWidget(item),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              mini: true,
              onPressed: () {
                setState(() {
                  _connections = _generateRandomConnections(_items);
                });
              },
              tooltip: 'Randomize Connections',
              child: const Icon(Icons.shuffle),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              mini: true,
              onPressed: () {
                setState(() {
                  _connections.clear(); // Clear all connections
                });
              },
              tooltip: 'Clear All Connections',
              child: const Icon(Icons.clear_all),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  _transformationController.value = Matrix4.identity();
                });
              },
              tooltip: 'Reset View',
              child: const Icon(Icons.center_focus_strong),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemWidget(DraggableItem item, {bool isFeedback = false}) {
    final double actualRowsContainerHeight = item.numberOfRows * rowHeight;

    return Container(
      key: isFeedback ? null : item.widgetKey,
      padding: const EdgeInsets.all(itemExternalPadding),
      decoration: BoxDecoration(
        color: isFeedback ? item.color.withOpacity(0.85) : item.color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: isFeedback
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(2, 3),
                ),
              ],
        border: Border.all(
          color: Colors.black.withOpacity(0.6),
          width: isFeedback ? 1.0 : 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: itemTitleSectionHeight -
                4, // Adjust for internal spacing/padding of title
            constraints: BoxConstraints(
              maxWidth: rowAreaWidth + 20,
            ), // Ensure title doesn't overflow too much
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(
              bottom: 4.0,
            ), // Space between title and rows area
            child: Text(
              item.id,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: rowAreaWidth,
            height: actualRowsContainerHeight,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black.withOpacity(0.25)),
              color: Colors.white.withOpacity(isFeedback ? 0.3 : 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.builder(
              // Use ListView for potential scrolling if many rows
              itemCount: item.numberOfRows,
              physics:
                  const NeverScrollableScrollPhysics(), // Disable scrolling for fixed rows
              itemBuilder: (context, index) {
                // Create a port drag target
                return DragTarget<PortDragInfo>(
                  onAccept: (draggedPortInfo) {
                    // Create a connection from dragged port to this port
                    _createConnection(
                        draggedPortInfo, PortDragInfo(item.id, index));
                  },
                  builder: (context, candidateData, rejectedData) {
                    // Changed: Wrap the port container with a draggable
                    return LongPressDraggable<PortDragInfo>(
                      data: PortDragInfo(item.id, index),
                      // Show port row as feedback
                      feedback: Material(
                        elevation: 4.0,
                        color: Colors.transparent,
                        child: Container(
                          width: rowAreaWidth,
                          height: rowHeight,
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.indigo,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(3.0),
                          ),
                          child: Center(
                            child: Text(
                              'Port ${index + 1}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.indigo,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // When the drag starts, set the current dragged port
                      onDragStarted: () {
                        setState(() {
                          _currentDraggedPort = PortDragInfo(item.id, index);
                        });
                      },
                      onDragEnd: (details) {
                        setState(() {
                          _currentDraggedPort = null;
                          _tempLineEndPoint = null;
                        });
                      },
                      onDraggableCanceled: (velocity, offset) {
                        setState(() {
                          _currentDraggedPort = null;
                          _tempLineEndPoint = null;
                        });
                      },
                      child: Container(
                        height: rowHeight,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        decoration: BoxDecoration(
                          color: (candidateData.isNotEmpty)
                              ? Colors.lightBlue.withOpacity(
                                  0.3) // Highlight when a port is dragged over
                              : null,
                          border: (index < item.numberOfRows - 1)
                              ? Border(
                                  bottom: BorderSide(
                                    color: Colors.black.withOpacity(0.15),
                                    width: 1.0,
                                  ),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.drag_indicator,
                              size: 12,
                              color: Colors.indigo.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Port ${index + 1}',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: Colors.black.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
          fromX += (_DraggableInteractiveLinesExampleState.rowAreaWidth +
                  2 * itemExternalPadding) /
              2; // Fallback
        }

        double toX = toItem.position.dx;
        final toContext = toItem.widgetKey.currentContext;
        if (toContext != null && toContext.findRenderObject() != null) {
          final toRenderBox = toContext.findRenderObject() as RenderBox;
          toX += toRenderBox.size.width / 2;
        } else {
          toX += (_DraggableInteractiveLinesExampleState.rowAreaWidth +
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
          fromX += (_DraggableInteractiveLinesExampleState.rowAreaWidth +
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

/*
// To run this example, use a main.dart file like this:

import 'package:flutter/material.dart';
// Make sure the code above is in a file, e.g., 'enhanced_draggable_lines_screen.dart'
// import 'enhanced_draggable_lines_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Enhanced Draggable Lines Demo',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
        useMaterial3: true,
      ),
      home: const DraggableInteractiveLinesExample(), 
    );
  }
}
*/
