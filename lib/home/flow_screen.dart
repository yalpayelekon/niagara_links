import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niagara_links/home/grid_painter.dart';
import 'package:niagara_links/home/paste_special_dialog.dart';
import 'package:niagara_links/home/resize_component_command.dart';
import 'package:niagara_links/models/command_history.dart';
import 'package:niagara_links/models/component.dart';
import '../models/component_type.dart';
import '../models/connection.dart';
import '../models/logic_components.dart';
import '../models/math_components.dart';
import '../models/point_components.dart';
import '../models/port.dart';
import '../models/port_type.dart';
import '../models/ramp_component.dart';
import '../models/rectangle.dart';
import 'handlers.dart';
import 'intents.dart';
import 'manager.dart';
import 'component_widget.dart';
import 'connection_painter.dart';
import 'command.dart';
import 'selection_box_painter.dart';
import 'utils.dart';

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
  late FlowHandlers _flowHandlers;
  Offset? _selectionBoxStart;
  Offset? _selectionBoxEnd;
  bool _isDraggingSelectionBox = false;

  SlotDragInfo? _currentDraggedPort;
  Offset? _tempLineEndPoint;
  Offset? _dragStartPosition;
  Offset? _clipboardComponentPosition;
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _interactiveViewerChildKey = GlobalKey();
  final Map<String, double> _componentWidths = {};
  Size _canvasSize = const Size(2000, 2000); // Initial canvas size
  Offset _canvasOffset = Offset.zero; // Canvas position within the view
  static const double _canvasPadding = 100.0; // Padding around components

  List<Component> _clipboardComponents = [];
  List<Offset> _clipboardPositions = [];
  List<Connection> _clipboardConnections = [];
  final Set<Component> _selectedComponents = {};

  @override
  void initState() {
    super.initState();
    _transformationController.value = Matrix4.identity();

    _flowHandlers = FlowHandlers(
      flowManager: _flowManager,
      commandHistory: _commandHistory,
      componentPositions: _componentPositions,
      componentKeys: _componentKeys,
      componentWidths: _componentWidths,
      setState: setState,
      updateCanvasSize: _updateCanvasSize,
      selectedComponents: _selectedComponents,
      clipboardComponents: _clipboardComponents,
      clipboardPositions: _clipboardPositions,
      clipboardConnections: _clipboardConnections,
      setClipboardComponentPosition: (position) {
        setState(() {
          _clipboardComponentPosition = position;
        });
      },
    );

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
    final numericWritable = PointComponent(
      id: 'Numeric Writable',
      type: ComponentType(ComponentType.NUMERIC_WRITABLE),
    );
    _flowManager.addComponent(numericWritable);
    _componentPositions[numericWritable.id] = const Offset(500, 250);
    _componentKeys[numericWritable.id] = GlobalKey();

    final numericPoint = PointComponent(
      id: 'Numeric Point',
      type: ComponentType(ComponentType.NUMERIC_POINT),
    );
    _flowManager.addComponent(numericPoint);
    _componentPositions[numericPoint.id] = const Offset(900, 250);
    _componentKeys[numericPoint.id] = GlobalKey();

    _flowManager.recalculateAll();
    _updateCanvasSize();
    _commandHistory.clear();
  }

  void _handleComponentResize(String componentId, double newWidth) {
    _flowHandlers.handleComponentResize(componentId, newWidth);
  }

  void _addNewComponent(ComponentType type, {Offset? clickPosition}) {
    String baseName = getNameForComponentType(type);
    int counter = 1;
    String newName = '$baseName $counter';

    while (_flowManager.components.any((comp) => comp.id == newName)) {
      counter++;
      newName = '$baseName $counter';
    }

    Component newComponent =
        _flowManager.createComponentByType(newName, type.type);

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
      _componentWidths[newComponent.id] = 160.0;
      _componentPositions[newComponent.id] = newPosition;
      _componentKeys[newComponent.id] = newKey;

      _updateCanvasSize();
    });
  }

  void _handleValueChanged(
      String componentId, int slotIndex, dynamic newValue) {
    _flowHandlers.handleValueChanged(componentId, slotIndex, newValue);
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

  void _handlePortDragStarted(SlotDragInfo slotInfo) {
    setState(() {
      _currentDraggedPort = slotInfo;
    });
  }

  void _handlePortDragAccepted(SlotDragInfo targetSlotInfo) {
    if (_currentDraggedPort != null) {
      Component? sourceComponent =
          _flowManager.findComponentById(_currentDraggedPort!.componentId);
      Component? targetComponent =
          _flowManager.findComponentById(targetSlotInfo.componentId);

      if (sourceComponent != null && targetComponent != null) {
        if (_flowManager.canCreateConnection(
            _currentDraggedPort!.componentId,
            _currentDraggedPort!.slotIndex,
            targetSlotInfo.componentId,
            targetSlotInfo.slotIndex)) {
          setState(() {
            final command = CreateConnectionCommand(
              _flowManager,
              _currentDraggedPort!.componentId,
              _currentDraggedPort!.slotIndex,
              targetSlotInfo.componentId,
              targetSlotInfo.slotIndex,
            );
            _commandHistory.execute(command);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Cannot connect these slots - type mismatch or invalid connection'),
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
      shortcuts: getShortcuts(),
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
          SelectAllIntent: CallbackAction<SelectAllIntent>(
            onInvoke: (SelectAllIntent intent) {
              setState(() {
                _selectedComponents.clear();
                _selectedComponents.addAll(_flowManager.components);
              });
              return null;
            },
          ),
          DeleteIntent: CallbackAction<DeleteIntent>(
            onInvoke: (DeleteIntent intent) {
              setState(() {
                if (_selectedComponents.isNotEmpty) {
                  for (var component in _selectedComponents.toList()) {
                    _handleDeleteComponent(component);
                  }
                  _selectedComponents.clear();
                }
              });
              return null;
            },
          ),
          CopyIntent: CallbackAction<CopyIntent>(
            onInvoke: (CopyIntent intent) {
              if (_selectedComponents.length == 1) {
                _handleCopyComponent(_selectedComponents.first);
              } else if (_selectedComponents.isNotEmpty) {
                _handleCopyMultipleComponents();
              }
              return null;
            },
          ),
          MoveDownIntent: CallbackAction<MoveDownIntent>(
            onInvoke: (MoveDownIntent intent) {
              if (_selectedComponents.isNotEmpty) {
                for (var component in _selectedComponents) {
                  _handleMoveComponentDown(component);
                }
              }
              return null;
            },
          ),
          MoveLeftIntent: CallbackAction<MoveLeftIntent>(
            onInvoke: (MoveLeftIntent intent) {
              if (_selectedComponents.isNotEmpty) {
                for (var component in _selectedComponents) {
                  _handleMoveComponentLeft(component);
                }
              }
              return null;
            },
          ),
          MoveRightIntent: CallbackAction<MoveRightIntent>(
            onInvoke: (MoveRightIntent intent) {
              if (_selectedComponents.isNotEmpty) {
                for (var component in _selectedComponents) {
                  _handleMoveComponentRight(component);
                }
              }
              return null;
            },
          ),
          MoveUpIntent: CallbackAction<MoveUpIntent>(
            onInvoke: (MoveUpIntent intent) {
              if (_selectedComponents.isNotEmpty) {
                for (var component in _selectedComponents) {
                  _handleMoveComponentUp(component);
                }
              }
              return null;
            },
          ),
          PasteIntent: CallbackAction<PasteIntent>(
            onInvoke: (PasteIntent intent) {
              if (_clipboardComponents.isNotEmpty) {
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
                    componentWidths: _componentWidths,
                    tempLineStartInfo: _currentDraggedPort,
                    tempLineEndPoint: _tempLineEndPoint,
                  ),
                  child: GestureDetector(
                    onTapDown: (details) {
                      Offset? canvasPosition =
                          getPosition(details.globalPosition);
                      if (canvasPosition != null) {
                        //print("Canvas position onTapDown: $canvasPosition");
                        setState(() {
                          _selectionBoxStart = canvasPosition;
                          _isDraggingSelectionBox = false;
                          _selectedComponents.clear();
                        });
                      }
                    },
                    onPanStart: (details) {
                      Offset? canvasPosition =
                          getPosition(details.globalPosition);
                      if (canvasPosition != null) {
                        print("Canvas position onPanStart: $canvasPosition");
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
                          setState(() {
                            _isDraggingSelectionBox = true;
                            _selectionBoxStart = canvasPosition;
                            _selectionBoxEnd = canvasPosition;
                          });
                        }
                      }
                    },
                    onPanUpdate: (details) {
                      if (_isDraggingSelectionBox) {
                        Offset? canvasPosition =
                            getPosition(details.globalPosition);
                        if (canvasPosition != null) {
                          setState(() {
                            _selectionBoxEnd = canvasPosition;
                          });
                        }
                      }
                    },
                    onPanEnd: (details) {
                      if (_isDraggingSelectionBox &&
                          _selectionBoxStart != null &&
                          _selectionBoxEnd != null) {
                        final selectionRect = Rect.fromPoints(
                            _selectionBoxStart!, _selectionBoxEnd!);

                        setState(() {
                          if (!HardwareKeyboard.instance.isControlPressed) {
                            _selectedComponents.clear();
                          }

                          for (final component in _flowManager.components) {
                            final componentPos =
                                _componentPositions[component.id];
                            if (componentPos != null) {
                              const double componentWidth = 180.0;
                              const double componentHeight = 150.0;

                              final componentRect = Rect.fromLTWH(
                                componentPos.dx,
                                componentPos.dy,
                                componentWidth,
                                componentHeight,
                              );

                              if (selectionRect.overlaps(componentRect)) {
                                _selectedComponents.add(component);
                              }
                            }
                          }

                          _isDraggingSelectionBox = false;
                          _selectionBoxStart = null;
                          _selectionBoxEnd = null;
                        });
                      }
                    },
                    onDoubleTapDown: (TapDownDetails details) {
                      Offset? canvasPosition =
                          getPosition(details.globalPosition);
                      print(
                          "Canvas position onSecondaryTapDown: $canvasPosition");
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
                          if (_isDraggingSelectionBox &&
                              _selectionBoxStart != null &&
                              _selectionBoxEnd != null)
                            CustomPaint(
                              painter: SelectionBoxPainter(
                                start: _selectionBoxStart,
                                end: _selectionBoxEnd,
                              ),
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
                                      height:
                                          component.allSlots.length * rowHeight,
                                      isSelected: _selectedComponents
                                          .contains(component),
                                      widgetKey: _componentKeys[component.id] ??
                                          GlobalKey(),
                                      position:
                                          _componentPositions[component.id] ??
                                              Offset.zero,
                                      width: _componentWidths[component.id] ??
                                          160.0,
                                      onValueChanged: _handleValueChanged,
                                      onSlotDragStarted: _handlePortDragStarted,
                                      onSlotDragAccepted:
                                          _handlePortDragAccepted,
                                      onWidthChanged: _handleComponentResize,
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
                                    child: ComponentWidget(
                                      component: component,
                                      height:
                                          component.allSlots.length * rowHeight,
                                      isSelected: _selectedComponents
                                          .contains(component),
                                      widgetKey: GlobalKey(),
                                      position:
                                          _componentPositions[component.id] ??
                                              Offset.zero,
                                      width: _componentWidths[component.id] ??
                                          160.0,
                                      onValueChanged: _handleValueChanged,
                                      onSlotDragStarted: _handlePortDragStarted,
                                      onSlotDragAccepted:
                                          _handlePortDragAccepted,
                                      onWidthChanged: _handleComponentResize,
                                    ),
                                  ),
                                  onDragStarted: () {
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
                                          final offset =
                                              localOffset - _dragStartPosition!;

                                          if (_selectedComponents
                                                  .contains(component) &&
                                              _selectedComponents.length > 1) {
                                            for (var selectedComponent
                                                in _selectedComponents) {
                                              final currentPos =
                                                  _componentPositions[
                                                      selectedComponent.id];
                                              if (currentPos != null) {
                                                final newPos =
                                                    currentPos + offset;
                                                final command =
                                                    MoveComponentCommand(
                                                  selectedComponent.id,
                                                  newPos,
                                                  currentPos,
                                                  _componentPositions,
                                                );
                                                _commandHistory
                                                    .execute(command);
                                              }
                                            }
                                          } else {
                                            final command =
                                                MoveComponentCommand(
                                              component.id,
                                              localOffset,
                                              _dragStartPosition!,
                                              _componentPositions,
                                            );
                                            _commandHistory.execute(command);

                                            _selectedComponents.clear();
                                            _selectedComponents.add(component);
                                          }

                                          _dragStartPosition = null;
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
                                      if (HardwareKeyboard
                                          .instance.isControlPressed) {
                                        setState(() {
                                          if (_selectedComponents
                                              .contains(component)) {
                                            _selectedComponents
                                                .remove(component);
                                          } else {
                                            _selectedComponents.add(component);
                                          }
                                        });
                                      } else {
                                        setState(() {
                                          _selectedComponents.clear();
                                          _selectedComponents.add(component);
                                        });
                                      }
                                    },
                                    child: ComponentWidget(
                                      component: component,
                                      height:
                                          component.allSlots.length * rowHeight,
                                      width: _componentWidths[component.id] ??
                                          160.0,
                                      onWidthChanged: _handleComponentResize,
                                      isSelected: _selectedComponents
                                          .contains(component),
                                      widgetKey: _componentKeys[component.id] ??
                                          GlobalKey(),
                                      position:
                                          _componentPositions[component.id] ??
                                              Offset.zero,
                                      onValueChanged: _handleValueChanged,
                                      onSlotDragStarted: _handlePortDragStarted,
                                      onSlotDragAccepted:
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
            children: [
              Icon(Icons.paste_outlined,
                  size: 18,
                  color: _clipboardComponents.isNotEmpty ? null : Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Paste Special',
                style: TextStyle(
                    color:
                        _clipboardComponents.isNotEmpty ? null : Colors.grey),
              ),
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
        case 'paste-special':
          _showPasteSpecialDialog(canvasPosition);
          break;
        case 'select-all':
          setState(() {
            _selectedComponents.clear();
            _selectedComponents.addAll(_flowManager.components);
          });
          break;
      }
    });
  }

  // Replace with a call to the handler method
  void _showPasteSpecialDialog(Offset pastePosition) {
    if (_clipboardComponents.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PasteSpecialDialog(
          onPasteConfirmed: (numberOfCopies, keepAllLinks, keepAllRelations) {
            _flowHandlers.handlePasteSpecialComponent(
                pastePosition, numberOfCopies, keepAllLinks);
          },
        );
      },
    );
  }

  void _handlePasteComponent(Offset position) {
    _flowHandlers.handlePasteComponent(position);
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
                    'Custom Components',
                    [
                      RectangleComponent.RECTANGLE,
                      RampComponent.RAMP,
                    ],
                    position),
                _buildComponentCategorySection(
                    'Logic Gates',
                    [
                      ComponentType.AND_GATE,
                      ComponentType.OR_GATE,
                      ComponentType.XOR_GATE,
                      ComponentType.NOT_GATE,
                    ],
                    position),
                _buildComponentCategorySection(
                    'Math Operations',
                    [
                      ComponentType.ADD,
                      ComponentType.SUBTRACT,
                      ComponentType.MULTIPLY,
                      ComponentType.DIVIDE,
                      ComponentType.MAX,
                      ComponentType.MIN,
                      ComponentType.POWER,
                      ComponentType.ABS,
                    ],
                    position),
                _buildComponentCategorySection(
                    'Comparisons',
                    [
                      ComponentType.IS_GREATER_THAN,
                      ComponentType.IS_LESS_THAN,
                      ComponentType.IS_EQUAL,
                    ],
                    position),
                _buildComponentCategorySection(
                    'Writable Points',
                    [
                      ComponentType.BOOLEAN_WRITABLE,
                      ComponentType.NUMERIC_WRITABLE,
                      ComponentType.STRING_WRITABLE,
                    ],
                    position),
                _buildComponentCategorySection(
                    'Read-Only Points',
                    [
                      ComponentType.BOOLEAN_POINT,
                      ComponentType.NUMERIC_POINT,
                      ComponentType.STRING_POINT,
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
      String title, List<String> typeStrings, Offset position) {
    List<ComponentType> types =
        typeStrings.map((t) => ComponentType(t)).toList();

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
          if (_selectedComponents.length == 1) {
            _handleCopyComponent(_selectedComponents.first);
          } else if (_selectedComponents.isNotEmpty) {
            _handleCopyMultipleComponents();
          }
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
    _flowHandlers.handleEditComponent(context, component);
  }

  void _handleDeleteComponent(Component component) {
    _flowHandlers.handleDeleteComponent(component);
  }

  void _handleCopyComponent(Component component) {
    _flowHandlers.handleCopyComponent(component);
  }

  void _handleCopyMultipleComponents() {
    _flowHandlers.handleCopyMultipleComponents();
  }

  void _handleMoveComponentDown(Component component) {
    _flowHandlers.handleMoveComponentDown(component);
  }

  void _handleMoveComponentUp(Component component) {
    _flowHandlers.handleMoveComponentUp(component);
  }

  void _handleMoveComponentLeft(Component component) {
    _flowHandlers.handleMoveComponentLeft(component);
  }

  void _handleMoveComponentRight(Component component) {
    _flowHandlers.handleMoveComponentRight(component);
  }
}
