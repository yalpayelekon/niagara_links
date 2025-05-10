import 'package:flutter/widgets.dart';
import 'package:niagara_links/models/command.dart';
import 'package:niagara_links/models/component.dart';
import 'package:niagara_links/models/connection.dart';
import 'package:niagara_links/models/enums.dart';

import 'manager.dart';

class AddComponentCommand extends Command {
  final FlowManager flowManager;
  final Component component;
  final Map<String, dynamic> state;

  AddComponentCommand(this.flowManager, this.component, this.state);

  @override
  void execute() {
    flowManager.addComponent(component);
    if (state.containsKey('position')) {
      (state['positions'] as Map<String, Offset>)[component.id] =
          state['position'];
    }
    if (state.containsKey('key')) {
      (state['keys'] as Map<String, GlobalKey>)[component.id] = state['key'];
    }
  }

  @override
  void undo() {
    flowManager.removeComponent(component.id);
    if (state.containsKey('positions')) {
      (state['positions'] as Map<String, Offset>).remove(component.id);
    }
    if (state.containsKey('keys')) {
      (state['keys'] as Map<String, GlobalKey>).remove(component.id);
    }
  }

  @override
  String get description => 'Add ${component.id}';
}

/// Command for removing a component
class RemoveComponentCommand extends Command {
  final FlowManager flowManager;
  final Component component;
  final Offset position;
  final GlobalKey? key;
  final List<Connection> affectedConnections;

  RemoveComponentCommand(
    this.flowManager,
    this.component,
    this.position,
    this.key,
    this.affectedConnections,
  );

  @override
  void execute() {
    flowManager.removeComponent(component.id);
  }

  @override
  void undo() {
    flowManager.addComponent(component);

    // Restore all connections
    for (var connection in affectedConnections) {
      flowManager.createConnection(
        connection.fromComponentId,
        connection.fromPortIndex,
        connection.toComponentId,
        connection.toPortIndex,
      );
    }
  }

  @override
  String get description => 'Remove ${component.id}';
}

/// Command for creating a connection between two components
class CreateConnectionCommand extends Command {
  final FlowManager flowManager;
  final String fromComponentId;
  final int fromPortIndex;
  final String toComponentId;
  final int toPortIndex;

  CreateConnectionCommand(
    this.flowManager,
    this.fromComponentId,
    this.fromPortIndex,
    this.toComponentId,
    this.toPortIndex,
  );

  @override
  void execute() {
    flowManager.createConnection(
      fromComponentId,
      fromPortIndex,
      toComponentId,
      toPortIndex,
    );
  }

  @override
  void undo() {
    flowManager.removeConnection(
      fromComponentId,
      fromPortIndex,
      toComponentId,
      toPortIndex,
    );
  }

  @override
  String get description => 'Connect $fromComponentId→$toComponentId';
}

/// Command for updating a port value
class UpdatePortValueCommand extends Command {
  final FlowManager flowManager;
  final String componentId;
  final int portIndex;
  final dynamic newValue;
  final dynamic oldValue;

  UpdatePortValueCommand(
    this.flowManager,
    this.componentId,
    this.portIndex,
    this.newValue,
    this.oldValue,
  );

  @override
  void execute() {
    flowManager.updatePortValue(componentId, portIndex, newValue);
  }

  @override
  void undo() {
    flowManager.updatePortValue(componentId, portIndex, oldValue);
  }

  @override
  String get description => 'Change $componentId value';
}

/// Command for moving a component
class MoveComponentCommand extends Command {
  final String componentId;
  final Offset newPosition;
  final Offset oldPosition;
  final Map<String, Offset> componentPositions;

  MoveComponentCommand(
    this.componentId,
    this.newPosition,
    this.oldPosition,
    this.componentPositions,
  );

  @override
  void execute() {
    componentPositions[componentId] = newPosition;
  }

  @override
  void undo() {
    componentPositions[componentId] = oldPosition;
  }

  @override
  String get description => 'Move $componentId';
}

class EditComponentCommand extends Command {
  final FlowManager flowManager;
  final String oldId;
  final String newId;
  final ComponentType? newType;
  final ComponentType? oldType;
  final Map<String, Offset> componentPositions;
  final Map<String, GlobalKey> componentKeys;

  EditComponentCommand({
    required this.flowManager,
    required this.oldId,
    required this.newId,
    this.newType,
    this.oldType,
    required this.componentPositions,
    required this.componentKeys,
  });

  @override
  void execute() {
    // Find the component
    Component? component = flowManager.findComponentById(oldId);
    if (component == null) return;

    // Store old port values before changing type
    Map<int, dynamic> oldValues = {};
    if (newType != null && oldType != null && newType != oldType) {
      for (var port in component.ports) {
        oldValues[port.index] = port.value;
      }
    }

    // Update component ID
    component.id = newId;

    // Update positions and keys
    if (oldId != newId) {
      if (componentPositions.containsKey(oldId)) {
        final position = componentPositions[oldId];
        componentPositions.remove(oldId);
        componentPositions[newId] = position!;
      }

      if (componentKeys.containsKey(oldId)) {
        final key = componentKeys[oldId];
        componentKeys.remove(oldId);
        componentKeys[newId] = key!;
      }

      // Update connections
      for (var connection in flowManager.connections) {
        if (connection.fromComponentId == oldId) {
          connection.fromComponentId = newId;
        }
        if (connection.toComponentId == oldId) {
          connection.toComponentId = newId;
        }
      }

      // Update input connections in other components
      for (var otherComponent in flowManager.components) {
        for (var entry in otherComponent.inputConnections.entries) {
          if (entry.value.componentId == oldId) {
            entry.value.componentId = newId;
          }
        }
      }
    }

    // Change type if needed
    if (newType != null && oldType != null && newType != oldType) {
      // Create a new component of the new type
      Component newTypeComponent = Component(
        id: component.id,
        type: newType!,
      );

      // Preserve input connections
      newTypeComponent.inputConnections = component.inputConnections;

      // Replace the component
      int index = flowManager.components.indexOf(component);
      if (index >= 0) {
        flowManager.components[index] = newTypeComponent;
      }

      // Copy over saved values where possible
      for (var port in newTypeComponent.ports) {
        if (port.isInput && oldValues.containsKey(port.index)) {
          // Try to convert value if needed
          dynamic oldValue = oldValues[port.index];
          if (oldValue != null) {
            if (port.type == PortType.boolean && oldValue is! bool) {
              port.value = oldValue != 0 && oldValue != '';
            } else if (port.type == PortType.number && oldValue is! num) {
              if (oldValue is bool) {
                port.value = oldValue ? 1.0 : 0.0;
              } else if (oldValue is String) {
                port.value = double.tryParse(oldValue) ?? 0.0;
              }
            } else if (port.type == PortType.string && oldValue is! String) {
              port.value = oldValue.toString();
            } else {
              port.value = oldValue;
            }
          }
        }
      }

      // Recalculate
      flowManager.recalculateAll();
    }
  }

  @override
  void undo() {
    // Find the component
    Component? component = flowManager.findComponentById(newId);
    if (component == null) return;

    // Store port values before changing type
    Map<int, dynamic> oldValues = {};
    if (newType != null && oldType != null && newType != oldType) {
      for (var port in component.ports) {
        oldValues[port.index] = port.value;
      }
    }

    // Update component ID
    component.id = oldId;

    // Update positions and keys
    if (oldId != newId) {
      if (componentPositions.containsKey(newId)) {
        final position = componentPositions[newId];
        componentPositions.remove(newId);
        componentPositions[oldId] = position!;
      }

      if (componentKeys.containsKey(newId)) {
        final key = componentKeys[newId];
        componentKeys.remove(newId);
        componentKeys[oldId] = key!;
      }

      // Update connections
      for (var connection in flowManager.connections) {
        if (connection.fromComponentId == newId) {
          connection.fromComponentId = oldId;
        }
        if (connection.toComponentId == newId) {
          connection.toComponentId = oldId;
        }
      }

      // Update input connections in other components
      for (var otherComponent in flowManager.components) {
        for (var entry in otherComponent.inputConnections.entries) {
          if (entry.value.componentId == newId) {
            entry.value.componentId = oldId;
          }
        }
      }
    }

    // Change type back if needed
    if (newType != null && oldType != null && newType != oldType) {
      // Create a new component of the original type
      Component originalTypeComponent = Component(
        id: component.id,
        type: oldType!,
      );

      // Preserve input connections
      originalTypeComponent.inputConnections = component.inputConnections;

      // Replace the component
      int index = flowManager.components.indexOf(component);
      if (index >= 0) {
        flowManager.components[index] = originalTypeComponent;
      }

      // Copy over saved values where possible
      for (var port in originalTypeComponent.ports) {
        if (port.isInput && oldValues.containsKey(port.index)) {
          // Try to convert value if needed
          dynamic oldValue = oldValues[port.index];
          if (oldValue != null) {
            if (port.type == PortType.boolean && oldValue is! bool) {
              port.value = oldValue != 0 && oldValue != '';
            } else if (port.type == PortType.number && oldValue is! num) {
              if (oldValue is bool) {
                port.value = oldValue ? 1.0 : 0.0;
              } else if (oldValue is String) {
                port.value = double.tryParse(oldValue) ?? 0.0;
              }
            } else if (port.type == PortType.string && oldValue is! String) {
              port.value = oldValue.toString();
            } else {
              port.value = oldValue;
            }
          }
        }
      }

      flowManager.recalculateAll();
    }
  }

  @override
  String get description => oldType != newType
      ? 'Edit $oldId type and name'
      : 'Rename $oldId to $newId';
}
