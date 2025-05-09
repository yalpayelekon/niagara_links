// lib/home/flow_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'manager.dart';
import 'component_widget.dart';
import 'connection_painter.dart';
import 'command.dart';

// Custom intents for undo/redo actions
class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class FlowScreen extends StatefulWidget {
  const FlowScreen({super.key});

  @override
  State<FlowScreen> createState() => _FlowScreenState();
}

class _FlowScreenState extends State<FlowScreen> {
  final FlowManager _flowManager = FlowManager();
  final CommandHistory _commandHistory = CommandHistory();

  // Item positions
  final Map<String, Offset> _componentPositions = {};

  // Keys for widgets
  final Map<String, GlobalKey> _componentKeys = {};

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
    _initializeComponents();
  }

  void _initializeComponents() {
    // Add some starter components of various types

    // Boolean input
    final boolInput = Component(
      id: 'Boolean Input',
      type: ComponentType.booleanInput,
    );
    _flowManager.addComponent(boolInput);
    _componentPositions[boolInput.id] = const Offset(100, 100);
    _componentKeys[boolInput.id] = GlobalKey();

    // Number inputs
    final num1Input = Component(
      id: 'Number 1',
      type: ComponentType.numberInput,
    );
    _flowManager.addComponent(num1Input);
    _componentPositions[num1Input.id] = const Offset(100, 200);
    _componentKeys[num1Input.id] = GlobalKey();

    final num2Input = Component(
      id: 'Number 2',
      type: ComponentType.numberInput,
    );
    _flowManager.addComponent(num2Input);
    _componentPositions[num2Input.id] = const Offset(100, 300);
    _componentKeys[num2Input.id] = GlobalKey();

    // String input
    final stringInput = Component(
      id: 'String Input',
      type: ComponentType.stringInput,
    );
    _flowManager.addComponent(stringInput);
    _componentPositions[stringInput.id] = const Offset(100, 400);
    _componentKeys[stringInput.id] = GlobalKey();

    // Logic component
    final andGate = Component(
      id: 'AND Gate',
      type: ComponentType.andGate,
    );
    _flowManager.addComponent(andGate);
    _componentPositions[andGate.id] = const Offset(350, 150);
    _componentKeys[andGate.id] = GlobalKey();

    // Math component
    final addComp = Component(
      id: 'Addition',
      type: ComponentType.add,
    );
    _flowManager.addComponent(addComp);
    _componentPositions[addComp.id] = const Offset(350, 250);
    _componentKeys[addComp.id] = GlobalKey();

    // Comparison component
    final greaterThan = Component(
      id: 'Greater Than',
      type: ComponentType.isGreaterThan,
    );
    _flowManager.addComponent(greaterThan);
    _componentPositions[greaterThan.id] = const Offset(350, 350);
    _componentKeys[greaterThan.id] = GlobalKey();

    // Equality component
    final equals = Component(
      id: 'Equality',
      type: ComponentType.isEqual,
    );
    _flowManager.addComponent(equals);
    _componentPositions[equals.id] = const Offset(600, 250);
    _componentKeys[equals.id] = GlobalKey();

    // Set initial values
    boolInput.ports[0].value = true;
    num1Input.ports[0].value = 5.0;
    num2Input.ports[0].value = 3.0;
    stringInput.ports[0].value = "Hello";

    // Calculate initial values
    _flowManager.recalculateAll();

    // Clear the command history since we're setting up the initial state
    _commandHistory.clear();
  }

  void _handleValueChanged(
      String componentId, int portIndex, dynamic newValue) {
    // Get the current value before changing it
    Component? component = _flowManager.findComponentById(componentId);
    if (component != null && portIndex < component.ports.length) {
      dynamic oldValue = component.ports[portIndex].value;

      // Only create a command if the value actually changed
      if (oldValue != newValue) {
        setState(() {
          final command = UpdatePortValueCommand(
            _flowManager,
            componentId,
            portIndex,
            newValue,
            oldValue,
          );
          _commandHistory.execute(command);
        });
      }
    }
  }

  void _handlePortDragStarted(PortDragInfo portInfo) {
    setState(() {
      _currentDraggedPort = portInfo;
    });
  }

  void _handlePortDragAccepted(PortDragInfo targetPortInfo) {
    if (_currentDraggedPort != null) {
      Component? sourceComponent =
          _flowManager.findComponentById(_currentDraggedPort!.componentId);
      Component? targetComponent =
          _flowManager.findComponentById(targetPortInfo.componentId);

      if (sourceComponent != null && targetComponent != null) {
        if (_flowManager.canCreateConnection(
            _currentDraggedPort!.componentId,
            _currentDraggedPort!.portIndex,
            targetPortInfo.componentId,
            targetPortInfo.portIndex)) {
          setState(() {
            final command = CreateConnectionCommand(
              _flowManager,
              _currentDraggedPort!.componentId,
              _currentDraggedPort!.portIndex,
              targetPortInfo.componentId,
              targetPortInfo.portIndex,
            );
            _commandHistory.execute(command);
          });
        } else {
          // Show an error snackbar if the connection can't be created
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Cannot connect these ports - type mismatch or invalid connection'),
              duration: Duration(seconds: 2),
            ),
          );
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
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
            const UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
            const RedoIntent(),
        // For Mac users
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ):
            const UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyY):
            const RedoIntent(),
        // Additional Mac shortcut (Command+Shift+Z)
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift,
            LogicalKeyboardKey.keyZ): const RedoIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          UndoIntent: CallbackAction<UndoIntent>(
            onInvoke: (UndoIntent intent) {
              if (_commandHistory.canUndo) {
                setState(() {
                  _commandHistory.undo();
                });
              }
              return null;
            },
          ),
          RedoIntent: CallbackAction<RedoIntent>(
            onInvoke: (RedoIntent intent) {
              if (_commandHistory.canRedo) {
                setState(() {
                  _commandHistory.redo();
                });
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Visual Flow Editor'),
              actions: [
                // Undo button
                IconButton(
                  icon: const Icon(Icons.undo),
                  tooltip: _commandHistory.canUndo
                      ? 'Undo: ${_commandHistory.lastUndoDescription}'
                      : 'Undo',
                  onPressed: _commandHistory.canUndo
                      ? () {
                          setState(() {
                            _commandHistory.undo();
                          });
                        }
                      : null, // Disable button if cannot undo
                ),
                // Redo button
                IconButton(
                  icon: const Icon(Icons.redo),
                  tooltip: _commandHistory.canRedo
                      ? 'Redo: ${_commandHistory.lastRedoDescription}'
                      : 'Redo',
                  onPressed: _commandHistory.canRedo
                      ? () {
                          setState(() {
                            _commandHistory.redo();
                          });
                        }
                      : null, // Disable button if cannot redo
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
                  foregroundPainter: ConnectionPainter(
                    flowManager: _flowManager,
                    componentPositions: _componentPositions,
                    componentKeys: _componentKeys,
                    tempLineStartInfo: _currentDraggedPort,
                    tempLineEndPoint: _tempLineEndPoint,
                  ),
                  child: SizedBox(
                    width: _canvasWidth,
                    height: _canvasHeight,
                    child: Stack(
                      children: _flowManager.components.map((component) {
                        return Positioned(
                          left: _componentPositions[component.id]?.dx ?? 0,
                          top: _componentPositions[component.id]?.dy ?? 0,
                          child: Draggable<String>(
                            data: component.id,
                            feedback: Material(
                              elevation: 5.0,
                              color: Colors.transparent,
                              child: ComponentWidget(
                                component: component,
                                widgetKey:
                                    _componentKeys[component.id] ?? GlobalKey(),
                                position: _componentPositions[component.id] ??
                                    Offset.zero,
                                onValueChanged: _handleValueChanged,
                                onPortDragStarted: _handlePortDragStarted,
                                onPortDragAccepted: _handlePortDragAccepted,
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: ComponentWidget(
                                component: component,
                                widgetKey: GlobalKey(),
                                position: _componentPositions[component.id] ??
                                    Offset.zero,
                                onValueChanged: _handleValueChanged,
                                onPortDragStarted: _handlePortDragStarted,
                                onPortDragAccepted: _handlePortDragAccepted,
                              ),
                            ),
                            onDragStarted: () {
                              // Store the original position when drag starts
                              _dragStartPosition =
                                  _componentPositions[component.id];
                            },
                            onDragEnd: (details) {
                              final RenderBox? viewerChildRenderBox =
                                  _interactiveViewerChildKey.currentContext
                                      ?.findRenderObject() as RenderBox?;

                              if (viewerChildRenderBox != null) {
                                final Offset localOffset = viewerChildRenderBox
                                    .globalToLocal(details.offset);

                                if (_dragStartPosition != null &&
                                    _dragStartPosition != localOffset) {
                                  setState(() {
                                    final command = MoveComponentCommand(
                                      component.id,
                                      localOffset,
                                      _dragStartPosition!,
                                      _componentPositions,
                                    );
                                    _commandHistory.execute(command);

                                    _dragStartPosition = null;
                                  });
                                }
                              }
                            },
                            child: GestureDetector(
                              onSecondaryTapDown: (details) {
                                _showContextMenu(
                                    context, details.globalPosition, component);
                              },
                              child: ComponentWidget(
                                component: component,
                                widgetKey:
                                    _componentKeys[component.id] ?? GlobalKey(),
                                position: _componentPositions[component.id] ??
                                    Offset.zero,
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
            floatingActionButton: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    setState(() {
                      _transformationController.value = Matrix4.identity();
                    });
                  },
                  tooltip: 'Reset View',
                  child: const Icon(Icons.center_focus_strong),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  onPressed: _showAddComponentDialog,
                  tooltip: 'Add Component',
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddComponentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Component'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: ListView(
              children: [
                _buildComponentCategorySection('Logic Gates', [
                  ComponentType.andGate,
                  ComponentType.orGate,
                  ComponentType.xorGate,
                  ComponentType.notGate,
                ]),
                _buildComponentCategorySection('Math Operations', [
                  ComponentType.add,
                  ComponentType.subtract,
                  ComponentType.multiply,
                  ComponentType.divide,
                ]),
                _buildComponentCategorySection('Comparisons', [
                  ComponentType.isGreaterThan,
                  ComponentType.isLessThan,
                  ComponentType.isEqual,
                ]),
                _buildComponentCategorySection('Input Components', [
                  ComponentType.booleanInput,
                  ComponentType.numberInput,
                  ComponentType.stringInput,
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComponentCategorySection(
      String title, List<ComponentType> types) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const Divider(),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: types.map((type) {
            return InkWell(
              onTap: () {
                _addNewComponent(type);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Column(
                  children: [
                    Icon(_getIconForComponentType(type)),
                    const SizedBox(height: 4.0),
                    Text(_getNameForComponentType(type)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getIconForComponentType(ComponentType type) {
    switch (type) {
      case ComponentType.andGate:
        return Icons.call_merge;
      case ComponentType.orGate:
        return Icons.call_split;
      case ComponentType.xorGate:
        return Icons.shuffle;
      case ComponentType.notGate:
        return Icons.block;

      case ComponentType.add:
        return Icons.add;
      case ComponentType.subtract:
        return Icons.remove;
      case ComponentType.multiply:
        return Icons.close;
      case ComponentType.divide:
        return Icons.expand;

      case ComponentType.isGreaterThan:
        return Icons.navigate_next;
      case ComponentType.isLessThan:
        return Icons.navigate_before;
      case ComponentType.isEqual:
        return Icons.drag_handle;

      case ComponentType.booleanInput:
        return Icons.toggle_on;
      case ComponentType.numberInput:
        return Icons.numbers;
      case ComponentType.stringInput:
        return Icons.text_fields;
    }
  }

  String _getNameForComponentType(ComponentType type) {
    switch (type) {
      case ComponentType.andGate:
        return 'AND Gate';
      case ComponentType.orGate:
        return 'OR Gate';
      case ComponentType.xorGate:
        return 'XOR Gate';
      case ComponentType.notGate:
        return 'NOT Gate';

      case ComponentType.add:
        return 'Add';
      case ComponentType.subtract:
        return 'Subtract';
      case ComponentType.multiply:
        return 'Multiply';
      case ComponentType.divide:
        return 'Divide';

      case ComponentType.isGreaterThan:
        return 'Greater Than';
      case ComponentType.isLessThan:
        return 'Less Than';
      case ComponentType.isEqual:
        return 'Equals';

      case ComponentType.booleanInput:
        return 'Boolean';
      case ComponentType.numberInput:
        return 'Number';
      case ComponentType.stringInput:
        return 'String';
    }
  }

  void _addNewComponent(ComponentType type) {
    // Generate a unique name based on type
    String baseName = _getNameForComponentType(type);
    int counter = 1;
    String newName = '$baseName $counter';

    // Make sure the name is unique
    while (_flowManager.components.any((comp) => comp.id == newName)) {
      counter++;
      newName = '$baseName $counter';
    }

    final newComponent = Component(
      id: newName,
      type: type,
    );

    // Find a good position - center of screen plus some random offset
    final RenderBox? viewerChildRenderBox =
        _interactiveViewerChildKey.currentContext?.findRenderObject()
            as RenderBox?;

    Offset screenCenter = Offset(_canvasWidth / 2, _canvasHeight / 2);
    if (viewerChildRenderBox != null) {
      // Adjust for current transformation
      screenCenter = viewerChildRenderBox.localToGlobal(Offset.zero);
    }

    final random = Random();
    final randomOffset = Offset(
      (random.nextDouble() * 200) - 100,
      (random.nextDouble() * 200) - 100,
    );

    final newPosition = screenCenter + randomOffset;
    final newKey = GlobalKey();

    Map<String, dynamic> state = {
      'position': newPosition,
      'key': newKey,
      'positions': _componentPositions,
      'keys': _componentKeys,
    };

    setState(() {
      final command = AddComponentCommand(_flowManager, newComponent, state);
      _commandHistory.execute(command);

      // Set position and key directly since they're not handled in the command execution
      _componentPositions[newComponent.id] = newPosition;
      _componentKeys[newComponent.id] = newKey;
    });
  }

  void _showContextMenu(
      BuildContext context, Offset position, Component component) {
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
              Text('Edit Name'),
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
          _handleCopyComponent(component);
          break;
        case 'edit':
          _handleEditComponent(context, component);
          break;
        case 'delete':
          _handleDeleteComponent(component);
          break;
      }
    });
  }

  void _handleCopyComponent(Component component) {
    // Create a copy with the same type
    String newName = '${component.id} (Copy)';

    // Make sure the name is unique
    int counter = 1;
    while (_flowManager.components.any((comp) => comp.id == newName)) {
      counter++;
      newName = '${component.id} (Copy $counter)';
    }

    final newComponent = Component(
      id: newName,
      type: component.type,
    );

    // Copy values from original ports
    for (int i = 0;
        i < component.ports.length && i < newComponent.ports.length;
        i++) {
      if (component.ports[i].isInput && component.inputConnections[i] == null) {
        newComponent.ports[i].value = component.ports[i].value;
      }
    }

    // Position the copy slightly offset from the original
    final newPosition = Offset(
      (_componentPositions[component.id]?.dx ?? 0) + 20,
      (_componentPositions[component.id]?.dy ?? 0) + 20,
    );

    final newKey = GlobalKey();

    Map<String, dynamic> state = {
      'position': newPosition,
      'key': newKey,
      'positions': _componentPositions,
      'keys': _componentKeys,
    };

    setState(() {
      final command = AddComponentCommand(_flowManager, newComponent, state);
      _commandHistory.execute(command);

      // Set position and key directly since they're not handled in the command
      _componentPositions[newComponent.id] = newPosition;
      _componentKeys[newComponent.id] = newKey;
    });
  }

  void _handleEditComponent(BuildContext context, Component component) {
    TextEditingController nameController =
        TextEditingController(text: component.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Component Name'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: 'Component Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final oldId = component.id;
              String newId = nameController.text.trim();

              // Check if the name is unique or empty
              if (newId.isEmpty) {
                newId = oldId;
              } else if (_flowManager.components
                  .any((comp) => comp.id == newId && comp.id != oldId)) {
                // Name already exists, add a suffix
                int counter = 1;
                String baseName = newId;
                while (_flowManager.components
                    .any((comp) => comp.id == newId && comp.id != oldId)) {
                  counter++;
                  newId = '$baseName $counter';
                }
              }

              // Only create a command if the name actually changed
              if (oldId != newId) {
                setState(() {
                  final command = EditComponentCommand(
                    _flowManager,
                    oldId,
                    newId,
                    _componentPositions,
                    _componentKeys,
                    _flowManager.connections,
                    _flowManager.components,
                  );
                  _commandHistory.execute(command);
                });
              }
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _handleDeleteComponent(Component component) {
    // Find all connections related to this component before removing
    final affectedConnections = _flowManager.connections
        .where((connection) =>
            connection.fromComponentId == component.id ||
            connection.toComponentId == component.id)
        .toList();

    setState(() {
      final oldPosition = _componentPositions[component.id] ?? Offset.zero;
      final oldKey = _componentKeys[component.id];

      final command = RemoveComponentCommand(
        _flowManager,
        component,
        oldPosition,
        oldKey,
        affectedConnections,
      );
      _commandHistory.execute(command);
    });
  }
}
