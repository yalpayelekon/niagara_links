// lib/logic/logic_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'logic_manager.dart';
import 'logic_models.dart';
import 'logic_item_widget.dart';
import 'logic_connection_painter.dart';

// Custom intents for undo/redo actions
class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class LogicScreen extends StatefulWidget {
  const LogicScreen({super.key});

  @override
  State<LogicScreen> createState() => _LogicScreenState();
}

class _LogicScreenState extends State<LogicScreen> {
  final LogicManager _logicManager = LogicManager();

  // Item positions
  final Map<String, Offset> _itemPositions = {};

  // Keys for widgets
  final Map<String, GlobalKey> _itemKeys = {};

  PortDragInfo? _currentDraggedPort;
  Offset? _tempLineEndPoint;
  Offset? _dragStartPosition; // Track starting position for move commands

  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _interactiveViewerChildKey = GlobalKey();

  final double _canvasWidth = 1500.0;
  final double _canvasHeight = 1000.0;

  @override
  void initState() {
    super.initState();
    _transformationController.value = Matrix4.identity();
    _initializeLogicComponents();
  }

  void _initializeLogicComponents() {
    // Create initial logic items
    final andGate = LogicItem(
      id: 'AND Gate',
      operationType: LogicOperationType.and,
    );
    _logicManager.addItem(andGate);
    _itemPositions[andGate.id] = const Offset(100, 100);
    _itemKeys[andGate.id] = GlobalKey();

    final orGate = LogicItem(
      id: 'OR Gate',
      operationType: LogicOperationType.or,
    );
    _logicManager.addItem(orGate);
    _itemPositions[orGate.id] = const Offset(100, 250);
    _itemKeys[orGate.id] = GlobalKey();

    final xorGate = LogicItem(
      id: 'XOR Gate',
      operationType: LogicOperationType.xor,
    );
    _logicManager.addItem(xorGate);
    _itemPositions[xorGate.id] = const Offset(400, 175);
    _itemKeys[xorGate.id] = GlobalKey();

    final notGate = LogicItem(
      id: 'NOT Gate',
      operationType: LogicOperationType.not,
    );
    _logicManager.addItem(notGate);
    _itemPositions[notGate.id] = const Offset(400, 350);
    _itemKeys[notGate.id] = GlobalKey();

    final inputA = LogicItem(
      id: 'Input A',
      operationType: LogicOperationType.input,
    );
    _logicManager.addItem(inputA);
    _itemPositions[inputA.id] = const Offset(100, 400);
    _itemKeys[inputA.id] = GlobalKey();

    final inputB = LogicItem(
      id: 'Input B',
      operationType: LogicOperationType.input,
    );
    _logicManager.addItem(inputB);
    _itemPositions[inputB.id] = const Offset(100, 500);
    _itemKeys[inputB.id] = GlobalKey();

    // Set some initial values
    inputA.ports[0].value = true; // Set Input A to true
    _logicManager.recalculateAll();
  }

  void _handleValueChanged(String itemId, int portIndex, bool newValue) {
    setState(() {
      LogicItem? item = _logicManager.findItemById(itemId);
      if (item != null && portIndex < item.ports.length) {
        _logicManager.updatePortValue(itemId, portIndex, newValue);
      }
    });
  }

  void _handlePortDragStarted(PortDragInfo portInfo) {
    setState(() {
      _currentDraggedPort = portInfo;
    });
  }

  void _handlePortDragAccepted(PortDragInfo targetPortInfo) {
    if (_currentDraggedPort != null) {
      LogicItem? sourceItem =
          _logicManager.findItemById(_currentDraggedPort!.itemId);
      LogicItem? targetItem = _logicManager.findItemById(targetPortInfo.itemId);

      if (sourceItem != null &&
          targetItem != null &&
          _currentDraggedPort!.portIndex < sourceItem.ports.length &&
          targetPortInfo.portIndex < targetItem.ports.length) {
        // Check if source is output and target is input
        bool sourceIsOutput =
            !sourceItem.ports[_currentDraggedPort!.portIndex].isInput;
        bool targetIsInput = targetItem.ports[targetPortInfo.portIndex].isInput;

        if (sourceIsOutput && targetIsInput) {
          // Check if the connection already exists
          bool connectionExists = _logicManager.connections.any((connection) =>
              connection.fromItemId == _currentDraggedPort!.itemId &&
              connection.fromPortIndex == _currentDraggedPort!.portIndex &&
              connection.toItemId == targetPortInfo.itemId &&
              connection.toPortIndex == targetPortInfo.portIndex);

          if (!connectionExists) {
            setState(() {
              _logicManager.createConnection(
                _currentDraggedPort!.itemId,
                _currentDraggedPort!.portIndex,
                targetPortInfo.itemId,
                targetPortInfo.portIndex,
              );
            });
          }
        } else if (!targetIsInput && sourceIsOutput) {
          // Cannot connect output to output
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot connect output to output')));
        } else if (targetIsInput && !sourceIsOutput) {
          // Cannot connect input to input
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot connect input to input')));
        }
      }
    }

    setState(() {
      _currentDraggedPort = null;
      _tempLineEndPoint = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logic Gate Editor'),
        actions: [
          // Add node button
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddItemDialog,
            tooltip: 'Add Logic Gate',
          ),
        ],
      ),
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
            foregroundPainter: LogicConnectionPainter(
              logicManager: _logicManager,
              itemPositions: _itemPositions,
              itemKeys: _itemKeys,
              tempLineStartInfo: _currentDraggedPort,
              tempLineEndPoint: _tempLineEndPoint,
            ),
            child: SizedBox(
              width: _canvasWidth,
              height: _canvasHeight,
              child: Stack(
                children: _logicManager.items.map((item) {
                  return Positioned(
                    left: _itemPositions[item.id]?.dx ?? 0,
                    top: _itemPositions[item.id]?.dy ?? 0,
                    child: Draggable<String>(
                      data: item.id,
                      feedback: Material(
                        elevation: 5.0,
                        color: Colors.transparent,
                        child: LogicItemWidget(
                          item: item,
                          widgetKey: _itemKeys[item.id] ?? GlobalKey(),
                          position: _itemPositions[item.id] ?? Offset.zero,
                          onValueChanged: _handleValueChanged,
                          onPortDragStarted: _handlePortDragStarted,
                          onPortDragAccepted: _handlePortDragAccepted,
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: LogicItemWidget(
                          item: item,
                          widgetKey: GlobalKey(),
                          position: _itemPositions[item.id] ?? Offset.zero,
                          onValueChanged: _handleValueChanged,
                          onPortDragStarted: _handlePortDragStarted,
                          onPortDragAccepted: _handlePortDragAccepted,
                        ),
                      ),
                      onDragStarted: () {
                        // Store the original position when drag starts
                        _dragStartPosition = _itemPositions[item.id];
                      },
                      onDragEnd: (details) {
                        final RenderBox? viewerChildRenderBox =
                            _interactiveViewerChildKey.currentContext
                                ?.findRenderObject() as RenderBox?;

                        if (viewerChildRenderBox != null) {
                          final Offset localOffset = viewerChildRenderBox
                              .globalToLocal(details.offset);

                          setState(() {
                            _itemPositions[item.id] = localOffset;
                          });
                        }
                      },
                      child: GestureDetector(
                        onSecondaryTapDown: (details) {
                          _showContextMenu(
                              context, details.globalPosition, item);
                        },
                        child: LogicItemWidget(
                          item: item,
                          widgetKey: _itemKeys[item.id] ?? GlobalKey(),
                          position: _itemPositions[item.id] ?? Offset.zero,
                          onValueChanged: _handleValueChanged,
                          onPortDragStarted: _handlePortDragStarted,
                          onPortDragAccepted: _handlePortDragAccepted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _transformationController.value = Matrix4.identity();
          });
        },
        tooltip: 'Reset View',
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }

  void _showAddItemDialog() {
    String newItemName = 'New Gate';
    LogicOperationType selectedOperationType = LogicOperationType.and;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Logic Gate'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Gate Name',
                    ),
                    onChanged: (value) {
                      newItemName = value.isNotEmpty ? value : 'New Gate';
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<LogicOperationType>(
                    value: selectedOperationType,
                    decoration: const InputDecoration(
                      labelText: 'Gate Type',
                    ),
                    items: LogicOperationType.values.map((type) {
                      String label;
                      switch (type) {
                        case LogicOperationType.and:
                          label = 'AND Gate';
                          break;
                        case LogicOperationType.or:
                          label = 'OR Gate';
                          break;
                        case LogicOperationType.xor:
                          label = 'XOR Gate';
                          break;
                        // Continuing lib/logic/logic_screen.dart

                        case LogicOperationType.not:
                          label = 'NOT Gate';
                          break;
                        case LogicOperationType.input:
                          label = 'Input';
                          break;
                      }

                      return DropdownMenuItem<LogicOperationType>(
                        value: type,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (LogicOperationType? value) {
                      if (value != null) {
                        setState(() {
                          selectedOperationType = value;
                        });
                      }
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addNewItem(newItemName, selectedOperationType);
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addNewItem(String name, LogicOperationType operationType) {
    final newItem = LogicItem(
      id: name,
      operationType: operationType,
    );

    final newPosition = const Offset(100, 100);
    final newKey = GlobalKey();

    setState(() {
      _logicManager.addItem(newItem);
      _itemPositions[newItem.id] = newPosition;
      _itemKeys[newItem.id] = newKey;

      // Calculate initial values for the new item
      newItem.calculate();
    });
  }

  void _showContextMenu(BuildContext context, Offset position, LogicItem item) {
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

  void _handleEditItem(BuildContext context, LogicItem item) {
    TextEditingController itemIdController =
        TextEditingController(text: item.id);
    LogicOperationType selectedOperationType = item.operationType;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Logic Gate'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: itemIdController,
                      decoration: const InputDecoration(
                        labelText: 'Gate Name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<LogicOperationType>(
                      value: selectedOperationType,
                      decoration: const InputDecoration(
                        labelText: 'Gate Type',
                      ),
                      items: LogicOperationType.values.map((type) {
                        String label;
                        switch (type) {
                          case LogicOperationType.and:
                            label = 'AND Gate';
                            break;
                          case LogicOperationType.or:
                            label = 'OR Gate';
                            break;
                          case LogicOperationType.xor:
                            label = 'XOR Gate';
                            break;
                          case LogicOperationType.not:
                            label = 'NOT Gate';
                            break;
                          case LogicOperationType.input:
                            label = 'Input';
                            break;
                        }

                        return DropdownMenuItem<LogicOperationType>(
                          value: type,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (LogicOperationType? value) {
                        if (value != null) {
                          setState(() {
                            selectedOperationType = value;
                          });
                        }
                      },
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
                    // Apply changes and close dialog
                    final oldName = item.id;
                    final newName = itemIdController.text;

                    this.setState(() {
                      // Update name
                      if (oldName != newName) {
                        // Update position and key entries with new name
                        if (_itemPositions.containsKey(oldName)) {
                          final position = _itemPositions[oldName];
                          _itemPositions.remove(oldName);
                          _itemPositions[newName] = position!;
                        }

                        if (_itemKeys.containsKey(oldName)) {
                          final key = _itemKeys[oldName];
                          _itemKeys.remove(oldName);
                          _itemKeys[newName] = key!;
                        }

                        item.id = newName;
                      }

                      // Update operation type if different
                      if (item.operationType != selectedOperationType) {
                        item.updateOperationType(selectedOperationType);
                      }

                      _logicManager.recalculateAll();
                    });

                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleCopyItem(LogicItem item) {
    // Create a new item with the same operation type
    final newItem = LogicItem(
      id: '${item.id} (Copy)',
      operationType: item.operationType,
    );

    // Copy values from original ports
    for (int i = 0; i < item.ports.length && i < newItem.ports.length; i++) {
      if (item.ports[i].isInput) {
        newItem.ports[i].value = item.ports[i].value;
      }
    }

    // Position the copy slightly offset from the original
    final newPosition = Offset(
      (_itemPositions[item.id]?.dx ?? 0) + 20,
      (_itemPositions[item.id]?.dy ?? 0) + 20,
    );

    // Create a new key for the copied item
    final newKey = GlobalKey();

    setState(() {
      _logicManager.addItem(newItem);
      _itemPositions[newItem.id] = newPosition;
      _itemKeys[newItem.id] = newKey;
    });
  }

  void _handleDeleteItem(LogicItem item) {
    setState(() {
      // Find and remove all connections related to this item before removing the item
      List<LogicConnection> connectionsToRemove = [];
      for (var connection in _logicManager.connections) {
        if (connection.fromItemId == item.id ||
            connection.toItemId == item.id) {
          connectionsToRemove.add(connection);
        }
      }

      for (var connection in connectionsToRemove) {
        _logicManager.removeConnection(
          connection.fromItemId,
          connection.fromPortIndex,
          connection.toItemId,
          connection.toPortIndex,
        );
      }

      _logicManager.removeItem(item.id);
      _itemPositions.remove(item.id);
      _itemKeys.remove(item.id);
    });
  }
}
