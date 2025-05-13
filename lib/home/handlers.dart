import 'package:flutter/material.dart';
import 'package:niagara_links/models/command_history.dart';
import 'package:niagara_links/models/component.dart';
import 'package:niagara_links/models/connection.dart';
import 'package:niagara_links/models/port.dart';
import 'package:niagara_links/models/port_type.dart';
import 'manager.dart';
import 'component_widget.dart';
import 'command.dart';
import 'resize_component_command.dart';

class FlowHandlers {
  final FlowManager flowManager;
  final CommandHistory commandHistory;
  final Map<String, Offset> componentPositions;
  final Map<String, GlobalKey> componentKeys;
  final Map<String, double> componentWidths;
  final Function(void Function()) setState;
  final Function() updateCanvasSize;
  final Set<Component> selectedComponents;
  final List<Component> clipboardComponents;
  final List<Offset> clipboardPositions;
  final List<Connection> clipboardConnections;
  final Function(Offset) setClipboardComponentPosition;

  FlowHandlers({
    required this.flowManager,
    required this.commandHistory,
    required this.componentPositions,
    required this.componentKeys,
    required this.componentWidths,
    required this.setState,
    required this.updateCanvasSize,
    required this.selectedComponents,
    required this.clipboardComponents,
    required this.clipboardPositions,
    required this.clipboardConnections,
    required this.setClipboardComponentPosition,
  });

  void handleWidthChanged(String componentId, double newWidth) {
    setState(() {
      componentWidths[componentId] = newWidth;
    });
  }

  void handleComponentResize(String componentId, double newWidth) {
    final oldWidth = componentWidths[componentId] ?? 160.0;

    setState(() {
      final command = ResizeComponentCommand(
        componentId,
        newWidth,
        oldWidth,
        componentWidths,
      );
      commandHistory.execute(command);
    });
  }

  void handleValueChanged(String componentId, int slotIndex, dynamic newValue) {
    Component? component = flowManager.findComponentById(componentId);
    if (component != null) {
      Slot? slot = component.getSlotByIndex(slotIndex);

      if (slot != null) {
        dynamic oldValue;
        if (slot is Property) {
          oldValue = slot.value;
        } else if (slot is ActionSlot) {
          oldValue = slot.parameter;
        }

        if (oldValue != newValue) {
          setState(() {
            final command = UpdatePortValueCommand(
              flowManager,
              componentId,
              slotIndex,
              newValue,
              oldValue,
            );
            commandHistory.execute(command);
          });
        }
      }
    }
  }

  void handleDeleteComponent(Component component) {
    final affectedConnections = flowManager.connections
        .where((connection) =>
            connection.fromComponentId == component.id ||
            connection.toComponentId == component.id)
        .toList();

    setState(() {
      final oldPosition = componentPositions[component.id] ?? Offset.zero;
      final oldKey = componentKeys[component.id];

      final command = RemoveComponentCommand(
        flowManager,
        component,
        oldPosition,
        oldKey,
        affectedConnections,
      );
      commandHistory.execute(command);

      updateCanvasSize();
    });
  }

  void handleEditComponent(BuildContext context, Component component) {
    TextEditingController nameController =
        TextEditingController(text: component.id);

    Map<int, TextEditingController> propertyControllers = {};
    List<Property> editableProperties = component.properties
        .where((prop) =>
            !prop.isInput &&
            !component.inputConnections.containsKey(prop.index))
        .toList();

    for (var property in editableProperties) {
      if (property.type.type != PortType.BOOLEAN) {
        String valueText = property.value?.toString() ?? '';
        propertyControllers[property.index] =
            TextEditingController(text: valueText);
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Component'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'Component Name'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  if (editableProperties.isNotEmpty) ...[
                    const Text(
                      'Properties',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...editableProperties.map((property) {
                      if (property.type.type == PortType.BOOLEAN) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TextField(
                          controller: propertyControllers[property.index],
                          decoration: InputDecoration(
                            labelText: '${property.name} Value',
                            helperText: 'Type: ${property.type.type}',
                          ),
                          keyboardType: property.type.type == PortType.NUMERIC
                              ? TextInputType.number
                              : TextInputType.text,
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  String newName = nameController.text.trim();
                  if (newName.isNotEmpty && newName != component.id) {
                    component.id = newName;
                  }

                  for (var property in editableProperties) {
                    if (property.type.type != PortType.BOOLEAN &&
                        propertyControllers.containsKey(property.index)) {
                      String newValueText =
                          propertyControllers[property.index]!.text;

                      dynamic newValue;

                      if (property.type.type == PortType.NUMERIC) {
                        newValue = num.tryParse(newValueText) ?? property.value;
                      } else if (property.type.type == PortType.STRING) {
                        newValue = newValueText;
                      } else if (property.type.type == PortType.ANY) {
                        newValue = num.tryParse(newValueText);
                        newValue ??= newValueText;
                      }

                      if (newValue != property.value) {
                        handleValueChanged(
                            component.id, property.index, newValue);
                      }
                    }
                  }

                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void handleCopyComponent(Component component) {
    clipboardComponents.clear();
    clipboardPositions.clear();
    clipboardConnections.clear();

    clipboardComponents.add(component);
    clipboardPositions.add(componentPositions[component.id] ?? Offset.zero);
    setClipboardComponentPosition(
        componentPositions[component.id] ?? Offset.zero);
  }

  void handleCopyMultipleComponents() {
    if (selectedComponents.isEmpty) return;

    clipboardComponents.clear();
    clipboardPositions.clear();
    clipboardConnections.clear();

    Map<String, int> componentIndexMap = {};

    for (int i = 0; i < selectedComponents.length; i++) {
      var component = selectedComponents.elementAt(i);
      clipboardComponents.add(component);
      clipboardPositions.add(componentPositions[component.id] ?? Offset.zero);
      componentIndexMap[component.id] = i;
    }

    for (var connection in flowManager.connections) {
      bool fromSelected =
          componentIndexMap.containsKey(connection.fromComponentId);
      bool toSelected = componentIndexMap.containsKey(connection.toComponentId);

      if (fromSelected && toSelected) {
        clipboardConnections.add(connection);
      }
    }

    if (clipboardComponents.isNotEmpty) {
      setClipboardComponentPosition(clipboardPositions.first);
    }
  }

  void handlePasteComponent(Offset position) {
    if (clipboardComponents.isEmpty) return;

    Map<String, String> idMap = {};

    for (int i = 0; i < clipboardComponents.length; i++) {
      var originalComponent = clipboardComponents[i];
      var originalPosition = clipboardPositions[i];

      Offset relativeToPastePoint = originalPosition - clipboardPositions[0];
      Offset newPosition = position + relativeToPastePoint;

      String newName = '${originalComponent.id} (Copy)';
      int counter = 1;
      while (flowManager.components.any((comp) => comp.id == newName)) {
        counter++;
        newName = '${originalComponent.id} (Copy $counter)';
      }

      Component newComponent = flowManager.createComponentByType(
          newName, originalComponent.type.type);

      for (var sourceProperty in originalComponent.properties) {
        if (!originalComponent.inputConnections
            .containsKey(sourceProperty.index)) {
          for (var targetProperty in newComponent.properties) {
            if (targetProperty.index == sourceProperty.index) {
              targetProperty.value = sourceProperty.value;
              break;
            }
          }
        }
      }

      final newKey = GlobalKey();

      Map<String, dynamic> state = {
        'position': newPosition,
        'key': newKey,
        'positions': componentPositions,
        'keys': componentKeys,
      };

      idMap[originalComponent.id] = newComponent.id;
      final command = AddComponentCommand(flowManager, newComponent, state);
      commandHistory.execute(command);

      componentPositions[newComponent.id] = newPosition;
      componentKeys[newComponent.id] = newKey;
    }

    for (var connection in clipboardConnections) {
      String? newFromId = idMap[connection.fromComponentId];
      String? newToId = idMap[connection.toComponentId];

      if (newFromId != null && newToId != null) {
        final command = CreateConnectionCommand(
          flowManager,
          newFromId,
          connection.fromPortIndex,
          newToId,
          connection.toPortIndex,
        );
        commandHistory.execute(command);
      }
    }

    setState(() {
      updateCanvasSize();
    });
  }

  void handlePasteSpecialComponent(
      Offset position, int numberOfCopies, bool keepAllLinks) {
    if (clipboardComponents.isEmpty) return;

    const double offsetX = 50.0;
    const double offsetY = 50.0;

    for (int copyIndex = 0; copyIndex < numberOfCopies; copyIndex++) {
      final double baseOffsetX = copyIndex * offsetX;
      final double baseOffsetY = copyIndex * offsetY;

      Map<String, String> idMap = {};

      for (int i = 0; i < clipboardComponents.length; i++) {
        var originalComponent = clipboardComponents[i];
        var originalPosition = clipboardPositions[i];

        Offset relativeToPastePoint = originalPosition - clipboardPositions[0];

        Offset newPosition = Offset(
          position.dx + baseOffsetX + relativeToPastePoint.dx,
          position.dy + baseOffsetY + relativeToPastePoint.dy,
        );

        String newName = '${originalComponent.id} (Copy)';
        int counter = 1;
        while (flowManager.components.any((comp) => comp.id == newName)) {
          counter++;
          newName = '${originalComponent.id} (Copy $counter)';
        }

        Component newComponent = flowManager.createComponentByType(
            newName, originalComponent.type.type);

        for (var sourceProperty in originalComponent.properties) {
          if (!originalComponent.inputConnections
                  .containsKey(sourceProperty.index) ||
              !keepAllLinks) {
            for (var targetProperty in newComponent.properties) {
              if (targetProperty.index == sourceProperty.index) {
                targetProperty.value = sourceProperty.value;
                break;
              }
            }
          }
        }

        final newKey = GlobalKey();

        Map<String, dynamic> state = {
          'position': newPosition,
          'key': newKey,
          'positions': componentPositions,
          'keys': componentKeys,
        };

        idMap[originalComponent.id] = newComponent.id;
        final command = AddComponentCommand(flowManager, newComponent, state);
        commandHistory.execute(command);

        componentPositions[newComponent.id] = newPosition;
        componentKeys[newComponent.id] = newKey;
      }

      if (keepAllLinks) {
        for (var connection in clipboardConnections) {
          String? newFromId = idMap[connection.fromComponentId];
          String? newToId = idMap[connection.toComponentId];

          if (newFromId != null && newToId != null) {
            final command = CreateConnectionCommand(
              flowManager,
              newFromId,
              connection.fromPortIndex,
              newToId,
              connection.toPortIndex,
            );
            commandHistory.execute(command);
          }
        }
      }
    }

    setState(() {
      updateCanvasSize();
    });
  }

  void handleMoveComponentDown(Component component) {
    Offset? canvasPosition = componentPositions[component.id];
    if (canvasPosition != null) {
      canvasPosition = Offset(canvasPosition.dx, canvasPosition.dy + 20);
      setState(() {
        final command = MoveComponentCommand(
          component.id,
          canvasPosition!,
          componentPositions[component.id]!,
          componentPositions,
        );
        commandHistory.execute(command);
        updateCanvasSize();
      });
    }
  }

  void handleMoveComponentUp(Component component) {
    Offset? canvasPosition = componentPositions[component.id];
    if (canvasPosition != null) {
      canvasPosition = Offset(canvasPosition.dx, canvasPosition.dy - 20);
      setState(() {
        final command = MoveComponentCommand(
          component.id,
          canvasPosition!,
          componentPositions[component.id]!,
          componentPositions,
        );
        commandHistory.execute(command);
        updateCanvasSize();
      });
    }
  }

  void handleMoveComponentLeft(Component component) {
    Offset? canvasPosition = componentPositions[component.id];
    if (canvasPosition != null) {
      canvasPosition = Offset(canvasPosition.dx - 20, canvasPosition.dy);
      setState(() {
        final command = MoveComponentCommand(
          component.id,
          canvasPosition!,
          componentPositions[component.id]!,
          componentPositions,
        );
        commandHistory.execute(command);
        updateCanvasSize();
      });
    }
  }

  void handleMoveComponentRight(Component component) {
    Offset? canvasPosition = componentPositions[component.id];
    if (canvasPosition != null) {
      canvasPosition = Offset(canvasPosition.dx + 20, canvasPosition.dy);
      setState(() {
        final command = MoveComponentCommand(
          component.id,
          canvasPosition!,
          componentPositions[component.id]!,
          componentPositions,
        );
        commandHistory.execute(command);
        updateCanvasSize();
      });
    }
  }
}
