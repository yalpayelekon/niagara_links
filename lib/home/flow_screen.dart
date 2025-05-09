import 'package:vector_math/vector_math_64.dart' as vector_math;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niagara_links/models/command_history.dart';
import 'package:niagara_links/models/component.dart';
import '../models/enums.dart';
import 'grid_painter.dart';
import 'manager.dart';
import 'component_widget.dart';
import 'connection_painter.dart';
import 'command.dart';
import 'utils.dart';

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

  final Map<String, Offset> _componentPositions = {};
  final Map<String, GlobalKey> _componentKeys = {};

  PortDragInfo? _currentDraggedPort;
  Offset? _tempLineEndPoint;
  Offset? _dragStartPosition; // Track starting position for move commands

  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _interactiveViewerChildKey = GlobalKey();

  Offset _viewPosition = Offset.zero;
  double _viewScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController.value = Matrix4.identity();
    _transformationController.addListener(_updateViewportInfo);
    _initializeComponents();
  }

  @override
  void dispose() {
    _transformationController.removeListener(_updateViewportInfo);
    super.dispose();
  }

  void _updateViewportInfo() {
    setState(() {
      _viewScale = _transformationController.value.getMaxScaleOnAxis();

      // Calculate the center of the viewport in canvas coordinates
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final Size size = renderBox.size;
        final Offset screenCenter = Offset(size.width / 2, size.height / 2);

        // Convert screen center to canvas coordinates
        final Matrix4 inverseTransform =
            Matrix4.inverted(_transformationController.value);
        final viewportCenter = _transformPoint(screenCenter, inverseTransform);
        _viewPosition = viewportCenter;
      }
    });
  }

  Offset _transformPoint(Offset point, Matrix4 transform) {
    final vector = vector_math.Vector3(point.dx, point.dy, 0.0);
    final transformed = transform.transform3(vector);
    return Offset(transformed.x, transformed.y);
  }

  void _initializeComponents() {
    // Component initialization code (unchanged)
    // ...

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

  // Handler methods (unchanged)
  // ...
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
              // Add position display in the app bar
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(24.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
                  color: Colors.indigo[700],
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'X: ${_viewPosition.dx.toStringAsFixed(0)}, Y: ${_viewPosition.dy.toStringAsFixed(0)}, Zoom: ${(_viewScale * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
            body: ClipRect(
              child: InteractiveViewer(
                transformationController: _transformationController,
                boundaryMargin: const EdgeInsets.all(10000),
                minScale: 0.1,
                maxScale: 3.0,
                onInteractionUpdate: (details) {
                  _updateViewportInfo();
                },
                onInteractionEnd: (details) {
                  _updateViewportInfo();
                },
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: GridPainter(
                        transform: _transformationController.value,
                        backgroundColor: Colors.grey[50]!,
                        gridSize: 50.0,
                        lineColor: Colors.grey[300]!,
                        lineWidth: 0.5,
                      ),
                      child: SizedBox(
                        width: 10000,
                        height: 10000,
                      ),
                    ),

                    // Foreground connection lines
                    Listener(
                      // Listener for tracking port connections without blocking pan gestures
                      onPointerMove: (event) {
                        if (_currentDraggedPort != null) {
                          setState(() {
                            final RenderBox? viewerChildRenderBox =
                                _interactiveViewerChildKey.currentContext
                                    ?.findRenderObject() as RenderBox?;
                            if (viewerChildRenderBox != null) {
                              _tempLineEndPoint = viewerChildRenderBox
                                  .globalToLocal(event.position);
                            }
                          });
                        }
                      },
                      onPointerUp: (event) {
                        if (_currentDraggedPort != null) {
                          setState(() {
                            _tempLineEndPoint = null;
                            _currentDraggedPort = null;
                          });
                        }
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
                          width: 10000,
                          height: 10000,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: _flowManager.components.map((component) {
                              return Positioned(
                                left:
                                    _componentPositions[component.id]?.dx ?? 0,
                                top: _componentPositions[component.id]?.dy ?? 0,
                                child: Draggable<String>(
                                  data: component.id,
                                  feedback: Material(
                                    elevation: 5.0,
                                    color: Colors.transparent,
                                    child: ComponentWidget(
                                      component: component,
                                      widgetKey: _componentKeys[component.id] ??
                                          GlobalKey(),
                                      position:
                                          _componentPositions[component.id] ??
                                              Offset.zero,
                                      onValueChanged: _handleValueChanged,
                                      onPortDragStarted: _handlePortDragStarted,
                                      onPortDragAccepted:
                                          _handlePortDragAccepted,
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
                                    child: ComponentWidget(
                                      component: component,
                                      widgetKey: GlobalKey(),
                                      position:
                                          _componentPositions[component.id] ??
                                              Offset.zero,
                                      onValueChanged: _handleValueChanged,
                                      onPortDragStarted: _handlePortDragStarted,
                                      onPortDragAccepted:
                                          _handlePortDragAccepted,
                                    ),
                                  ),
                                  // Important: Make ignorePointerOnDrag: false to allow panning during drag
                                  ignoringFeedbackPointer: false,
                                  onDragStarted: () {
                                    // Store the original position when drag starts
                                    _dragStartPosition =
                                        _componentPositions[component.id];
                                  },
                                  onDragEnd: (details) {
                                    final RenderBox? viewerChildRenderBox =
                                        _interactiveViewerChildKey
                                            .currentContext
                                            ?.findRenderObject() as RenderBox?;

                                    if (viewerChildRenderBox != null) {
                                      final Offset localOffset =
                                          viewerChildRenderBox
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
                                    // By defaulting to opaque: false, it allows the canvas panning gestures
                                    // to pass through when not specifically interacting with a component
                                    behavior: HitTestBehavior.opaque,
                                    onSecondaryTapDown: (details) {
                                      _showContextMenu(context,
                                          details.globalPosition, component);
                                    },
                                    child: ComponentWidget(
                                      component: component,
                                      widgetKey: _componentKeys[component.id] ??
                                          GlobalKey(),
                                      position:
                                          _componentPositions[component.id] ??
                                              Offset.zero,
                                      onValueChanged: _handleValueChanged,
                                      onPortDragStarted: _handlePortDragStarted,
                                      onPortDragAccepted:
                                          _handlePortDragAccepted,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Center view button
                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    setState(() {
                      _transformationController.value = Matrix4.identity();
                      _updateViewportInfo();
                    });
                  },
                  tooltip: 'Reset View',
                  child: const Icon(Icons.center_focus_strong),
                ),
                const SizedBox(height: 8),
                // Zoom out button
                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    setState(() {
                      final currentScale =
                          _transformationController.value.getMaxScaleOnAxis();
                      if (currentScale > 0.2) {
                        // Prevent zooming out too far
                        final Matrix4 newTransform =
                            Matrix4.copy(_transformationController.value);
                        newTransform.scale(0.8);
                        _transformationController.value = newTransform;
                        _updateViewportInfo();
                      }
                    });
                  },
                  tooltip: 'Zoom Out',
                  child: const Icon(Icons.zoom_out),
                ),
                const SizedBox(height: 8),
                // Zoom in button
                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    setState(() {
                      final currentScale =
                          _transformationController.value.getMaxScaleOnAxis();
                      if (currentScale < 2.5) {
                        // Prevent zooming in too far
                        final Matrix4 newTransform =
                            Matrix4.copy(_transformationController.value);
                        newTransform.scale(1.25);
                        _transformationController.value = newTransform;
                        _updateViewportInfo();
                      }
                    });
                  },
                  tooltip: 'Zoom In',
                  child: const Icon(Icons.zoom_in),
                ),
                const SizedBox(height: 16),
                // Add component button (unchanged)
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
                    Icon(getIconForComponentType(type)),
                    const SizedBox(height: 4.0),
                    Text(getNameForComponentType(type)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Updated _addNewComponent method to place components relative to current viewport
  void _addNewComponent(ComponentType type) {
    // Generate a unique name based on type
    String baseName = getNameForComponentType(type);
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

    // Use the current viewport position as the base for new component placement
    Offset basePosition = _viewPosition;

    // Add a random offset around the current viewport center
    final random = Random();
    final randomOffset = Offset(
      (random.nextDouble() * 200) - 100,
      (random.nextDouble() * 200) - 100,
    );

    final newPosition = basePosition + randomOffset;
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
    ComponentType selectedType = component.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Edit Component'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Component Name'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ComponentType>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Component Type',
                ),
                items: getCompatibleTypes(component.type).map((type) {
                  return DropdownMenuItem<ComponentType>(
                    value: type,
                    child: Text(getNameForComponentType(type)),
                  );
                }).toList(),
                onChanged: (ComponentType? value) {
                  if (value != null) {
                    setState(() {
                      selectedType = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
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

                // Create a command if anything changed
                if (oldId != newId || component.type != selectedType) {
                  this.setState(() {
                    final command = EditComponentCommand(
                      flowManager: _flowManager,
                      oldId: oldId,
                      newId: newId,
                      oldType: component.type,
                      newType: selectedType,
                      componentPositions: _componentPositions,
                      componentKeys: _componentKeys,
                    );
                    _commandHistory.execute(command);
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      }),
    );
  }

  void _handleDeleteComponent(Component component) {
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
