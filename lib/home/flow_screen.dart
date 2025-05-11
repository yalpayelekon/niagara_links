import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niagara_links/home/grid_painter.dart';
import 'package:niagara_links/models/command_history.dart';
import 'package:niagara_links/models/component.dart';
import '../models/enums.dart';
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

class CopyIntent extends Intent {
  const CopyIntent();
}

class PasteIntent extends Intent {
  const PasteIntent();
}

class DeleteIntent extends Intent {
  const DeleteIntent();
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
  Offset? _dragStartPosition;
  Offset? _clipboardComponentPosition;
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _interactiveViewerChildKey = GlobalKey();

  Size _canvasSize = const Size(2000, 2000); // Initial canvas size
  Offset _canvasOffset = Offset.zero; // Canvas position within the view
  static const double _canvasPadding = 100.0; // Padding around components

  Component? _clipboardComponent;
  Component? _selectedComponent;

  @override
  void initState() {
    super.initState();
    _transformationController.value = Matrix4.identity();
    _initializeComponents();
  }

  void _updateCanvasSize() {
    if (_componentPositions.isEmpty) return;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (var entry in _componentPositions.entries) {
      final position = entry.value;
      final componentId = entry.key;

      const estimatedWidth = 180.0; // 160 width + 20 padding
      const estimatedHeight = 120.0;

      minX = min(minX, position.dx);
      minY = min(minY, position.dy);
      maxX = max(maxX, position.dx + estimatedWidth);
      maxY = max(maxY, position.dy + estimatedHeight);
    }

    bool needsUpdate = false;
    Size newCanvasSize = _canvasSize;
    Offset newCanvasOffset = _canvasOffset;

    if (minX < _canvasPadding) {
      double extraWidth = _canvasPadding - minX;
      newCanvasSize =
          Size(_canvasSize.width + extraWidth, newCanvasSize.height);
      newCanvasOffset =
          Offset(_canvasOffset.dx - extraWidth, newCanvasOffset.dy);

      for (var id in _componentPositions.keys) {
        _componentPositions[id] = Offset(
          _componentPositions[id]!.dx + extraWidth,
          _componentPositions[id]!.dy,
        );
      }
      needsUpdate = true;
    }

    if (minY < _canvasPadding) {
      double extraHeight = _canvasPadding - minY;
      newCanvasSize =
          Size(newCanvasSize.width, _canvasSize.height + extraHeight);
      newCanvasOffset =
          Offset(newCanvasOffset.dx, _canvasOffset.dy - extraHeight);

      for (var id in _componentPositions.keys) {
        _componentPositions[id] = Offset(
          _componentPositions[id]!.dx,
          _componentPositions[id]!.dy + extraHeight,
        );
      }
      needsUpdate = true;
    }

    if (maxX > _canvasSize.width - _canvasPadding) {
      double extraWidth = maxX - (_canvasSize.width - _canvasPadding);
      newCanvasSize =
          Size(_canvasSize.width + extraWidth, newCanvasSize.height);
      needsUpdate = true;
    }

    if (maxY > _canvasSize.height - _canvasPadding) {
      double extraHeight = maxY - (_canvasSize.height - _canvasPadding);
      newCanvasSize =
          Size(newCanvasSize.width, _canvasSize.height + extraHeight);
      needsUpdate = true;
    }

    if (needsUpdate) {
      setState(() {
        _canvasSize = newCanvasSize;
        _canvasOffset = newCanvasOffset;
      });
    }
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

    // Update canvas size to fit all components
    _updateCanvasSize();

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

  Offset? getPosition(Offset globalPosition) {
    final RenderBox? viewerChildRenderBox =
        _interactiveViewerChildKey.currentContext?.findRenderObject()
            as RenderBox?;

    if (viewerChildRenderBox != null) {
      final Offset localPosition =
          viewerChildRenderBox.globalToLocal(globalPosition);

      final matrix = _transformationController.value;
      final inverseMatrix = Matrix4.inverted(matrix);
      final canvasPosition =
          MatrixUtils.transformPoint(inverseMatrix, localPosition);
      return canvasPosition;
    }
    return null;
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
      // TODO: include MAC shortcuts
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
            const UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
            const RedoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC):
            const CopyIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV):
            const PasteIntent(),
        LogicalKeySet(LogicalKeyboardKey.delete): const DeleteIntent(),
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
          CopyIntent: CallbackAction<CopyIntent>(
            onInvoke: (CopyIntent intent) {
              if (_selectedComponent != null) {
                _handleCopyComponent(_selectedComponent!);
              }
              return null;
            },
          ),
          DeleteIntent: CallbackAction<DeleteIntent>(
            onInvoke: (DeleteIntent intent) {
              if (_selectedComponent != null) {
                _handleDeleteComponent(_selectedComponent!);
              }
              return null;
            },
          ),
          PasteIntent: CallbackAction<PasteIntent>(
            onInvoke: (PasteIntent intent) {
              if (_clipboardComponent != null) {
                if (_clipboardComponentPosition != null) {
                  const double offsetAmount = 30.0;
                  final Offset pastePosition = _clipboardComponentPosition! +
                      const Offset(offsetAmount, offsetAmount);

                  _handlePasteComponent(pastePosition);
                } else {
                  final RenderBox? viewerChildRenderBox =
                      _interactiveViewerChildKey.currentContext
                          ?.findRenderObject() as RenderBox?;

                  if (viewerChildRenderBox != null) {
                    final viewportSize = viewerChildRenderBox.size;
                    final viewportCenter =
                        Offset(viewportSize.width / 2, viewportSize.height / 2);

                    final matrix = _transformationController.value;
                    final inverseMatrix = Matrix4.inverted(matrix);
                    final canvasPosition = MatrixUtils.transformPoint(
                        inverseMatrix, viewportCenter);

                    _handlePasteComponent(canvasPosition);
                  }
                }
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Center(
                    child: Text(
                      'Canvas: ${_canvasSize.width.toInt()} × ${_canvasSize.height.toInt()}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
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
                boundaryMargin: const EdgeInsets.all(1000),
                minScale: 0.1,
                constrained: false,
                maxScale: 3.0,
                panEnabled: true,
                scaleEnabled: true,
                child: CustomPaint(
                  key: _interactiveViewerChildKey,
                  foregroundPainter: ConnectionPainter(
                    flowManager: _flowManager,
                    componentPositions: _componentPositions,
                    componentKeys: _componentKeys,
                    tempLineStartInfo: _currentDraggedPort,
                    tempLineEndPoint: _tempLineEndPoint,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedComponent = null;
                      });
                    },
                    onSecondaryTapDown: (TapDownDetails details) {
                      Offset? canvasPosition =
                          getPosition(details.globalPosition);
                      if (canvasPosition != null) {
                        bool isClickOnComponent = false;

                        for (final componentId in _componentPositions.keys) {
                          final componentPos =
                              _componentPositions[componentId]!;

                          const double componentWidth = 180.0;
                          const double componentHeight = 150.0;

                          final componentRect = Rect.fromLTWH(
                            componentPos.dx,
                            componentPos.dy,
                            componentWidth,
                            componentHeight,
                          );

                          if (componentRect.contains(canvasPosition)) {
                            isClickOnComponent = true;
                            break;
                          }
                        }

                        if (!isClickOnComponent) {
                          _showCanvasContextMenu(
                              context, details.globalPosition);
                        }
                      }
                    },
                    child: Container(
                      width: _canvasSize.width,
                      height: _canvasSize.height,
                      color: Colors.grey[50],
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CustomPaint(
                            painter: GridPainter(),
                            size: _canvasSize,
                          ),
                          if (_flowManager.components.isEmpty)
                            const Center(
                              child: Text(
                                'Add components to the canvas',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          // Components
                          ..._flowManager.components.map(
                            (component) {
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
                                      isSelected: _selectedComponent?.id ==
                                          component.id,
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
                                      isSelected: _selectedComponent?.id ==
                                          component.id,
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
                                          _selectedComponent = component;
                                          _updateCanvasSize();
                                        });
                                      }
                                    }
                                  },
                                  child: GestureDetector(
                                    onSecondaryTapDown: (details) {
                                      _showContextMenu(context,
                                          details.globalPosition, component);
                                    },
                                    onTap: () {
                                      setState(() {
                                        _selectedComponent = component;
                                      });
                                    },
                                    child: ComponentWidget(
                                      component: component,
                                      isSelected: _selectedComponent?.id ==
                                          component.id,
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
                            },
                          ),
                        ],
                      ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCanvasContextMenu(BuildContext context, Offset globalPosition) {
    Offset canvasPosition = getPosition(globalPosition)!;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(globalPosition, globalPosition),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'add-component',
          child: Row(
            children: const [
              Icon(Icons.add_box, size: 18),
              SizedBox(width: 8),
              Text('Add Component'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'paste',
          enabled: _clipboardComponent != null,
          child: Row(
            children: [
              Icon(Icons.paste,
                  size: 18,
                  color: _clipboardComponent != null ? null : Colors.grey),
              const SizedBox(width: 8),
              Text('Paste',
                  style: TextStyle(
                      color: _clipboardComponent != null ? null : Colors.grey)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'select-all',
          child: Row(
            children: const [
              Icon(Icons.select_all, size: 18),
              SizedBox(width: 8),
              Text('Select All'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'clear-canvas',
          child: Row(
            children: const [
              Icon(Icons.clear, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Clear Canvas', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;

      switch (value) {
        case 'add-component':
          _showAddComponentDialogAtPosition(canvasPosition);
          break;
        case 'paste':
          _handlePasteComponent(canvasPosition);
          break;
        case 'select-all':
          // Placeholder for select all functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Select all functionality coming soon'),
              duration: Duration(seconds: 1),
            ),
          );
          break;
        case 'clear-canvas':
          // Placeholder for clear canvas functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clear canvas functionality coming soon'),
              duration: Duration(seconds: 1),
            ),
          );
          break;
      }
    });
  }

  void _showAddComponentDialogAtPosition(Offset position) {
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
                _buildComponentCategorySection(
                    'Logic Gates',
                    [
                      ComponentType.andGate,
                      ComponentType.orGate,
                      ComponentType.xorGate,
                      ComponentType.notGate,
                    ],
                    position),
                _buildComponentCategorySection(
                    'Math Operations',
                    [
                      ComponentType.add,
                      ComponentType.subtract,
                      ComponentType.multiply,
                      ComponentType.divide,
                      ComponentType.max,
                      ComponentType.min,
                      ComponentType.power,
                      ComponentType.abs,
                    ],
                    position),
                _buildComponentCategorySection(
                    'Comparisons',
                    [
                      ComponentType.isGreaterThan,
                      ComponentType.isLessThan,
                      ComponentType.isEqual,
                    ],
                    position),
                _buildComponentCategorySection(
                    'Input Components',
                    [
                      ComponentType.booleanInput,
                      ComponentType.numberInput,
                      ComponentType.stringInput,
                    ],
                    position),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComponentCategorySection(
      String title, List<ComponentType> types, Offset position) {
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
                _addNewComponent(type, clickPosition: position);
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

  void _addNewComponent(ComponentType type, {Offset? clickPosition}) {
    String baseName = getNameForComponentType(type);
    int counter = 1;
    String newName = '$baseName $counter';

    while (_flowManager.components.any((comp) => comp.id == newName)) {
      counter++;
      newName = '$baseName $counter';
    }

    final newComponent = Component(
      id: newName,
      type: type,
    );

    Offset newPosition;

    if (clickPosition != null) {
      newPosition = clickPosition;
    } else {
      final RenderBox? viewerChildRenderBox =
          _interactiveViewerChildKey.currentContext?.findRenderObject()
              as RenderBox?;

      newPosition = Offset(_canvasSize.width / 2, _canvasSize.height / 2);

      if (viewerChildRenderBox != null) {
        final viewportSize = viewerChildRenderBox.size;
        final viewportCenter =
            Offset(viewportSize.width / 2, viewportSize.height / 2);

        final matrix = _transformationController.value;
        final inverseMatrix = Matrix4.inverted(matrix);
        final transformedCenter =
            MatrixUtils.transformPoint(inverseMatrix, viewportCenter);

        final random = Random();
        final randomOffset = Offset(
          (random.nextDouble() * 200) - 100,
          (random.nextDouble() * 200) - 100,
        );

        newPosition = transformedCenter + randomOffset;
      }
    }

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

      _componentPositions[newComponent.id] = newPosition;
      _componentKeys[newComponent.id] = newKey;

      _updateCanvasSize();
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

                if (newId.isEmpty) {
                  newId = oldId;
                } else if (_flowManager.components
                    .any((comp) => comp.id == newId && comp.id != oldId)) {
                  int counter = 1;
                  String baseName = newId;
                  while (_flowManager.components
                      .any((comp) => comp.id == newId && comp.id != oldId)) {
                    counter++;
                    newId = '$baseName $counter';
                  }
                }

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

      _updateCanvasSize();
    });
  }

  void _handleCopyComponent(Component component) {
    _clipboardComponent = component;
    _clipboardComponentPosition = _componentPositions[component.id];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${component.id}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handlePasteComponent(Offset position) {
    if (_clipboardComponent == null) return;

    String newName = '${_clipboardComponent!.id} (Copy)';

    int counter = 1;
    while (_flowManager.components.any((comp) => comp.id == newName)) {
      counter++;
      newName = '${_clipboardComponent!.id} (Copy $counter)';
    }

    final newComponent = Component(
      id: newName,
      type: _clipboardComponent!.type,
    );

    // Copy values from ports that don't have input connections
    for (int i = 0;
        i < _clipboardComponent!.ports.length && i < newComponent.ports.length;
        i++) {
      if (_clipboardComponent!.ports[i].isInput &&
          _clipboardComponent!.inputConnections[i] == null) {
        newComponent.ports[i].value = _clipboardComponent!.ports[i].value;
      }
    }

    _clipboardComponent = null;
    final newKey = GlobalKey();

    Map<String, dynamic> state = {
      'position': position,
      'key': newKey,
      'positions': _componentPositions,
      'keys': _componentKeys,
    };

    setState(() {
      final command = AddComponentCommand(_flowManager, newComponent, state);
      _commandHistory.execute(command);

      _componentPositions[newComponent.id] = position;
      _componentKeys[newComponent.id] = newKey;

      _updateCanvasSize();
    });
  }
}
