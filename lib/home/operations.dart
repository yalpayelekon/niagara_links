import 'dart:math';
import 'package:flutter/material.dart';
import 'package:niagara_links/models/component.dart';
import 'package:niagara_links/models/enums.dart';
import 'package:niagara_links/models/command_history.dart';
import 'manager.dart';
import 'command.dart';
import 'utils.dart';
import 'dialogs.dart';

class ComponentOperations {
  final FlowManager flowManager;
  final CommandHistory commandHistory;
  final Map<String, Offset> componentPositions;
  final Map<String, GlobalKey> componentKeys;
  final Function(VoidCallback) setState;
  final Function() updateCanvasSize;

  ComponentOperations({
    required this.flowManager,
    required this.commandHistory,
    required this.componentPositions,
    required this.componentKeys,
    required this.setState,
    required this.updateCanvasSize,
  });

  void handleCopyComponent(Component component) {
    String newName = '${component.id} (Copy)';

    int counter = 1;
    while (flowManager.components.any((comp) => comp.id == newName)) {
      counter++;
      newName = '${component.id} (Copy $counter)';
    }

    final newComponent = Component(
      id: newName,
      type: component.type,
    );

    // Copy input values from the original component
    for (int i = 0;
        i < component.ports.length && i < newComponent.ports.length;
        i++) {
      if (component.ports[i].isInput && component.inputConnections[i] == null) {
        newComponent.ports[i].value = component.ports[i].value;
      }
    }

    final newPosition = Offset(
      (componentPositions[component.id]?.dx ?? 0) + 20,
      (componentPositions[component.id]?.dy ?? 0) + 20,
    );

    final newKey = GlobalKey();

    Map<String, dynamic> state = {
      'position': newPosition,
      'key': newKey,
      'positions': componentPositions,
      'keys': componentKeys,
    };

    setState(() {
      final command = AddComponentCommand(flowManager, newComponent, state);
      commandHistory.execute(command);

      componentPositions[newComponent.id] = newPosition;
      componentKeys[newComponent.id] = newKey;

      updateCanvasSize();
    });
  }

  void handleEditComponent(BuildContext context, Component component) async {
    final result = await ComponentDialogs.showEditComponentDialog(
      context,
      component,
      flowManager,
    );

    if (result != null && result.hasChanges) {
      setState(() {
        final command = EditComponentCommand(
          flowManager: flowManager,
          oldId: result.oldId,
          newId: result.newId,
          oldType: result.oldType,
          newType: result.newType,
          componentPositions: componentPositions,
          componentKeys: componentKeys,
        );
        commandHistory.execute(command);
      });
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

  void addNewComponent(ComponentType type, {Offset? clickPosition}) {
    String baseName = getNameForComponentType(type);
    int counter = 1;
    String newName = '$baseName $counter';

    while (flowManager.components.any((comp) => comp.id == newName)) {
      counter++;
      newName = '$baseName $counter';
    }

    final newComponent = Component(
      id: newName,
      type: type,
    );

    Offset newPosition = clickPosition ?? _calculateDefaultPosition();

    final newKey = GlobalKey();

    Map<String, dynamic> state = {
      'position': newPosition,
      'key': newKey,
      'positions': componentPositions,
      'keys': componentKeys,
    };

    setState(() {
      final command = AddComponentCommand(flowManager, newComponent, state);
      commandHistory.execute(command);

      componentPositions[newComponent.id] = newPosition;
      componentKeys[newComponent.id] = newKey;

      updateCanvasSize();
    });
  }

  void handleValueChanged(String componentId, int portIndex, dynamic newValue) {
    // Get the current value before changing it
    Component? component = flowManager.findComponentById(componentId);
    if (component != null && portIndex < component.ports.length) {
      dynamic oldValue = component.ports[portIndex].value;

      // Only create a command if the value actually changed
      if (oldValue != newValue) {
        setState(() {
          final command = UpdatePortValueCommand(
            flowManager,
            componentId,
            portIndex,
            newValue,
            oldValue,
          );
          commandHistory.execute(command);
        });
      }
    }
  }

  Offset _calculateDefaultPosition() {
    // This is a placeholder - you'll need to pass the necessary context
    // from FlowScreen to calculate the proper default position
    final random = Random();
    final randomOffset = Offset(
      (random.nextDouble() * 200) - 100,
      (random.nextDouble() * 200) - 100,
    );

    return Offset(400, 300) + randomOffset; // Default center position
  }
}
