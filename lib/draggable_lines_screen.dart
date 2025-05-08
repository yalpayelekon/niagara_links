import 'package:flutter/material.dart';
import 'package:niagara_links/draggable_item.dart';
import 'package:niagara_links/line_connection_painter.dart';
import 'package:niagara_links/models.dart';

class DraggableInteractiveLinesExample extends StatefulWidget {
  const DraggableInteractiveLinesExample({super.key});

  @override
  State<DraggableInteractiveLinesExample> createState() =>
      DraggableInteractiveLinesExampleState();
}

class DraggableInteractiveLinesExampleState
    extends State<DraggableInteractiveLinesExample> {
  static const double itemExternalPadding = 8.0;
  static const double itemTitleSectionHeight =
      28.0; // Height for item.id Text + internal spacing
  static const double rowHeight = 22.0; // Height of each row/port
  static const int defaultNumberOfRows = 5;
  static const double rowAreaWidth =
      130.0; // Width of the box containing rows/ports

  late List<DraggableItem> _items;
  List<ItemConnection> _connections = [];
  PortDragInfo? _currentDraggedPort;
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
    _transformationController.value = Matrix4.identity();
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

  void _createConnection(PortDragInfo source, PortDragInfo target) {
    if (source.itemId == target.itemId && source.rowIndex == target.rowIndex) {
      return;
    }

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

    return GestureDetector(
      onSecondaryTapDown: isFeedback
          ? null
          : (details) {
              _showContextMenu(context, details.globalPosition, item);
            },
      child: Container(
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
                  return DragTarget<PortDragInfo>(
                    onAccept: (draggedPortInfo) {
                      _createConnection(
                          draggedPortInfo, PortDragInfo(item.id, index));
                    },
                    builder: (context, candidateData, rejectedData) {
                      return LongPressDraggable<PortDragInfo>(
                        data: PortDragInfo(item.id, index),
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
      ),
    );
  }

  void _showContextMenu(
      BuildContext context, Offset position, DraggableItem item) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'copy',
          child: Row(
            children: const [
              Icon(Icons.copy, size: 18),
              SizedBox(width: 8),
              Text('Copy'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: const [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: const [
              Icon(Icons.delete, size: 18),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;

      switch (value) {
        case 'copy':
          _handleCopyItem(item);
          break;
        case 'edit':
          _handleEditItem(context, item);
          break;
        case 'delete':
          _handleDeleteItem(item);
          break;
      }
    });
  }

  void _handleCopyItem(DraggableItem item) {
    setState(() {
      final newItem = DraggableItem(
        id: '${item.id} (Copy)',
        position: Offset(item.position.dx + 20, item.position.dy + 20),
        color: item.color,
        numberOfRows: item.numberOfRows,
      );

      _items.add(newItem);
    });
  }

  void _handleEditItem(BuildContext context, DraggableItem item) {
    TextEditingController itemIdController =
        TextEditingController(text: item.id);

    TextEditingController rowsController =
        TextEditingController(text: item.numberOfRows.toString());

    Color selectedColor = item.color;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: itemIdController,
                  decoration: const InputDecoration(
                    labelText: 'Item ID',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: rowsController,
                  decoration: const InputDecoration(
                    labelText: 'Number of Rows',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Color: '),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        // In a real app, you would show a color picker here
                        // For simplicity, we're just cycling through some predefined colors
                        setState(() {
                          if (selectedColor == Colors.lightBlue[100]) {
                            selectedColor = Colors.tealAccent[100]!;
                          } else if (selectedColor == Colors.tealAccent[100]) {
                            selectedColor = Colors.purpleAccent[100]!;
                          } else if (selectedColor ==
                              Colors.purpleAccent[100]) {
                            selectedColor = Colors.orangeAccent[100]!;
                          } else {
                            selectedColor = Colors.lightBlue[100]!;
                          }
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  item.id = itemIdController.text;
                  item.color = selectedColor;

                  int? parsedRows = int.tryParse(rowsController.text);
                  if (parsedRows != null && parsedRows > 0) {
                    item.numberOfRows = parsedRows;
                  }
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _handleDeleteItem(DraggableItem item) {
    setState(() {
      _items.removeWhere((i) => i.id == item.id);
      _connections.removeWhere(
        (connection) =>
            connection.fromItemId == item.id || connection.toItemId == item.id,
      );
    });
  }
}
