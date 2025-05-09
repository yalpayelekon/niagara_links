// lib/calculator_screen.dart

import 'package:flutter/material.dart';
import 'calculator_models.dart';
import 'calculator_connection.dart';
import 'calculator_item_widget.dart';
import 'calculator_connection_painter.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final CalculatorManager _calculatorManager = CalculatorManager();

  // Item positions
  final Map<String, Offset> _itemPositions = {};

  // Keys for widgets
  final Map<String, GlobalKey> _itemKeys = {};

  PortDragInfo? _currentDraggedPort;
  Offset? _tempLineEndPoint;

  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _interactiveViewerChildKey = GlobalKey();

  final double _canvasWidth = 1500.0;
  final double _canvasHeight = 1000.0;

  @override
  void initState() {
    super.initState();
    _transformationController.value = Matrix4.identity();
    _initializeCalculator();
  }

  void _initializeCalculator() {
    // Create initial calculator items
    final addItem = CalculatorItem(
      id: 'Add',
      operationType: OperationType.add,
    );
    _calculatorManager.addItem(addItem);
    _itemPositions[addItem.id] = const Offset(100, 100);
    _itemKeys[addItem.id] = GlobalKey();

    final subtractItem = CalculatorItem(
      id: 'Subtract',
      operationType: OperationType.subtract,
    );
    _calculatorManager.addItem(subtractItem);
    _itemPositions[subtractItem.id] = const Offset(100, 250);
    _itemKeys[subtractItem.id] = GlobalKey();

    final multiplyItem = CalculatorItem(
      id: 'Multiply',
      operationType: OperationType.multiply,
    );
    _calculatorManager.addItem(multiplyItem);
    _itemPositions[multiplyItem.id] = const Offset(400, 175);
    _itemKeys[multiplyItem.id] = GlobalKey();

    final divideItem = CalculatorItem(
      id: 'Divide',
      operationType: OperationType.divide,
    );
    _calculatorManager.addItem(divideItem);
    _itemPositions[divideItem.id] = const Offset(400, 350);
    _itemKeys[divideItem.id] = GlobalKey();

    final inputItem1 = CalculatorItem(
      id: 'Input 1',
      operationType: OperationType.input,
    );
    _calculatorManager.addItem(inputItem1);
    _itemPositions[inputItem1.id] = const Offset(100, 400);
    _itemKeys[inputItem1.id] = GlobalKey();

    // Set initial values for ports
    inputItem1.ports[0].value = 10.0;
    addItem.ports[0].value = 5.0;
    addItem.ports[1].value = 3.0;
    subtractItem.ports[0].value = 7.0;
    subtractItem.ports[1].value = 2.0;

    // Calculate initial values
    _calculatorManager.recalculateAll();
  }

  void _handleValueChanged(String itemId, int portIndex, double newValue) {
    setState(() {
      _calculatorManager.updatePortValue(itemId, portIndex, newValue);
    });
  }

  void _handlePortDragStarted(PortDragInfo portInfo) {
    setState(() {
      _currentDraggedPort = portInfo;
    });
  }

  void _handlePortDragAccepted(PortDragInfo targetPortInfo) {
    if (_currentDraggedPort != null) {
      CalculatorItem? sourceItem =
          _calculatorManager.findItemById(_currentDraggedPort!.itemId);
      CalculatorItem? targetItem =
          _calculatorManager.findItemById(targetPortInfo.itemId);

      if (sourceItem != null &&
          targetItem != null &&
          _currentDraggedPort!.portIndex < sourceItem.ports.length &&
          targetPortInfo.portIndex < targetItem.ports.length) {
        // Check if source is output and target is input
        bool sourceIsOutput =
            !sourceItem.ports[_currentDraggedPort!.portIndex].isInput;
        bool targetIsInput = targetItem.ports[targetPortInfo.portIndex].isInput;

        if (sourceIsOutput && targetIsInput) {
          setState(() {
            _calculatorManager.createConnection(
                _currentDraggedPort!.itemId,
                _currentDraggedPort!.portIndex,
                targetPortInfo.itemId,
                targetPortInfo.portIndex);
          });
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
        title: const Text('Math Flow Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddItemDialog,
            tooltip: 'Add Node',
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
            foregroundPainter: CalculatorConnectionPainter(
              calculatorManager: _calculatorManager,
              itemPositions: _itemPositions,
              itemKeys: _itemKeys,
              tempLineStartInfo: _currentDraggedPort,
              tempLineEndPoint: _tempLineEndPoint,
            ),
            child: SizedBox(
              width: _canvasWidth,
              height: _canvasHeight,
              child: Stack(
                children: _calculatorManager.items.map((item) {
                  return Positioned(
                    left: _itemPositions[item.id]?.dx ?? 0,
                    top: _itemPositions[item.id]?.dy ?? 0,
                    child: Draggable<String>(
                      data: item.id,
                      feedback: Material(
                        elevation: 5.0,
                        color: Colors.transparent,
                        child: CalculatorItemWidget(
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
                        child: CalculatorItemWidget(
                          item: item,
                          widgetKey: GlobalKey(),
                          position: _itemPositions[item.id] ?? Offset.zero,
                          onValueChanged: _handleValueChanged,
                          onPortDragStarted: _handlePortDragStarted,
                          onPortDragAccepted: _handlePortDragAccepted,
                        ),
                      ),
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
                        child: CalculatorItemWidget(
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
    );
  }

  void _showAddItemDialog() {
    String newItemName = 'New Node';
    OperationType selectedOperationType = OperationType.add;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Calculator Node'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Node Name',
                    ),
                    onChanged: (value) {
                      newItemName = value.isNotEmpty ? value : 'New Node';
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<OperationType>(
                    value: selectedOperationType,
                    decoration: const InputDecoration(
                      labelText: 'Operation Type',
                    ),
                    items: OperationType.values.map((type) {
                      String label;
                      switch (type) {
                        case OperationType.add:
                          label = 'Addition (+)';
                          break;
                        case OperationType.subtract:
                          label = 'Subtraction (-)';
                          break;
                        case OperationType.multiply:
                          label = 'Multiplication (×)';
                          break;
                        case OperationType.divide:
                          label = 'Division (÷)';
                          break;
                        case OperationType.input:
                          label = 'Input Value';
                          break;
                      }

                      return DropdownMenuItem<OperationType>(
                        value: type,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (OperationType? value) {
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

  void _addNewItem(String name, OperationType operationType) {
    final newItem = CalculatorItem(
      id: name,
      operationType: operationType,
    );
    _calculatorManager.addItem(newItem);
    _itemPositions[newItem.id] = const Offset(100, 100);
    _itemKeys[newItem.id] = GlobalKey();
  }

  void _showContextMenu(
      BuildContext context, Offset position, CalculatorItem item) {
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

  void _handleCopyItem(CalculatorItem item) {
    setState(() {
      // Create a new item with the same operation type
      final newItem = CalculatorItem(
        id: '${item.id} (Copy)',
        operationType: item.operationType,
      );

      // Copy values from original ports
      for (int i = 0; i < item.ports.length && i < newItem.ports.length; i++) {
        if (item.ports[i].isInput) {
          newItem.ports[i].value = item.ports[i].value;
        }
      }

      // Add the new item to the calculator manager
      _calculatorManager.addItem(newItem);

      // Position the copy slightly offset from the original
      _itemPositions[newItem.id] = Offset(
        (_itemPositions[item.id]?.dx ?? 0) + 20,
        (_itemPositions[item.id]?.dy ?? 0) + 20,
      );

      // Create a new key for the copied item
      _itemKeys[newItem.id] = GlobalKey();

      // Calculate initial values for the new item
      newItem.calculate();
    });
  }

  void _handleEditItem(BuildContext context, CalculatorItem item) {
    TextEditingController itemIdController =
        TextEditingController(text: item.id);
    OperationType selectedOperationType = item.operationType;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Calculator Node'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: itemIdController,
                      decoration: const InputDecoration(
                        labelText: 'Node Name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<OperationType>(
                      value: selectedOperationType,
                      decoration: const InputDecoration(
                        labelText: 'Operation Type',
                      ),
                      items: OperationType.values.map((type) {
                        String label;
                        switch (type) {
                          case OperationType.add:
                            label = 'Addition (+)';
                            break;
                          case OperationType.subtract:
                            label = 'Subtraction (-)';
                            break;
                          case OperationType.multiply:
                            label = 'Multiplication (×)';
                            break;
                          case OperationType.divide:
                            label = 'Division (÷)';
                            break;
                          case OperationType.input:
                            label = 'Input Value';
                            break;
                        }

                        return DropdownMenuItem<OperationType>(
                          value: type,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (OperationType? value) {
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
                    this.setState(() {
                      // Store current port values before changing type
                      Map<int, double> oldValues = {};
                      for (var port in item.ports) {
                        oldValues[port.index] = port.value;
                      }

                      // Update item properties
                      item.id = itemIdController.text;

                      // Change operation type if different
                      if (item.operationType != selectedOperationType) {
                        item.updateOperationType(selectedOperationType);

                        // Copy over old values where possible
                        for (var port in item.ports) {
                          if (port.isInput &&
                              oldValues.containsKey(port.index)) {
                            port.value = oldValues[port.index]!;
                          }
                        }
                      }

                      _calculatorManager.recalculateAll();
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

  void _handleDeleteItem(CalculatorItem item) {
    setState(() {
      _calculatorManager.removeItem(item.id);

      _itemPositions.remove(item.id);
      _itemKeys.remove(item.id);
    });
  }
}
