import 'package:flutter/widgets.dart';
import 'package:niagara_links/models/command.dart';
import 'package:niagara_links/models/component.dart';
import 'package:niagara_links/models/connection.dart';
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

class UpdatePortValueCommand extends Command {
  final FlowManager flowManager;
  final String componentId;
  final int slotIndex;
  final dynamic newValue;
  final dynamic oldValue;

  UpdatePortValueCommand(
    this.flowManager,
    this.componentId,
    this.slotIndex,
    this.newValue,
    this.oldValue,
  );

  @override
  void execute() {
    flowManager.updatePortValue(componentId, slotIndex, newValue);
  }

  @override
  void undo() {
    flowManager.updatePortValue(componentId, slotIndex, oldValue);
  }

  @override
  String get description => 'Change $componentId value';
}

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
