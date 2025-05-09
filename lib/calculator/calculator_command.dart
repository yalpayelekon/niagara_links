// lib/calculator/calculator_command.dart

import 'dart:ui';

import 'calculator_models.dart';
import 'calculator_connection.dart';

/// Base class for commands that can be undone and redone
abstract class CalculatorCommand {
  /// Execute the command
  void execute();

  /// Undo the command
  void undo();

  /// Redo the command (typically just calls execute)
  void redo() {
    execute();
  }

  /// Description of the command for UI purposes
  String get description;
}

/// Command for adding a calculator item
class AddItemCommand extends CalculatorCommand {
  final CalculatorManager calculatorManager;
  final CalculatorItem item;
  final Map<String, dynamic> state;

  AddItemCommand(this.calculatorManager, this.item, this.state);

  @override
  void execute() {
    calculatorManager.addItem(item);
    if (state.containsKey('position')) {
      (state['positions'] as Map<String, dynamic>)[item.id] = state['position'];
    }
    if (state.containsKey('key')) {
      (state['keys'] as Map<String, dynamic>)[item.id] = state['key'];
    }
  }

  @override
  void undo() {
    calculatorManager.removeItem(item.id);
    if (state.containsKey('positions')) {
      (state['positions'] as Map<String, dynamic>).remove(item.id);
    }
    if (state.containsKey('keys')) {
      (state['keys'] as Map<String, dynamic>).remove(item.id);
    }
  }

  @override
  String get description => 'Add ${item.id}';
}

/// Command for removing a calculator item
class RemoveItemCommand extends CalculatorCommand {
  final CalculatorManager calculatorManager;
  final CalculatorItem item;
  final Offset position;
  final dynamic key;
  final List<CalculatorConnection> affectedConnections;

  RemoveItemCommand(
    this.calculatorManager,
    this.item,
    this.position,
    this.key,
    this.affectedConnections,
  );

  @override
  void execute() {
    calculatorManager.removeItem(item.id);
  }

  @override
  void undo() {
    calculatorManager.addItem(item);

    // Restore all connections
    for (var connection in affectedConnections) {
      calculatorManager.createConnection(
        connection.fromItemId,
        connection.fromPortIndex,
        connection.toItemId,
        connection.toPortIndex,
      );
    }
  }

  @override
  String get description => 'Remove ${item.id}';
}

/// Command for creating a connection between two calculator items
class CreateConnectionCommand extends CalculatorCommand {
  final CalculatorManager calculatorManager;
  final String fromItemId;
  final int fromPortIndex;
  final String toItemId;
  final int toPortIndex;

  CreateConnectionCommand(
    this.calculatorManager,
    this.fromItemId,
    this.fromPortIndex,
    this.toItemId,
    this.toPortIndex,
  );

  @override
  void execute() {
    calculatorManager.createConnection(
      fromItemId,
      fromPortIndex,
      toItemId,
      toPortIndex,
    );
  }

  @override
  void undo() {
    calculatorManager.removeConnection(
      fromItemId,
      fromPortIndex,
      toItemId,
      toPortIndex,
    );
  }

  @override
  String get description => 'Connect ${fromItemId}→${toItemId}';
}

/// Command for updating a port value
class UpdatePortValueCommand extends CalculatorCommand {
  final CalculatorManager calculatorManager;
  final String itemId;
  final int portIndex;
  final double newValue;
  final double oldValue;

  UpdatePortValueCommand(
    this.calculatorManager,
    this.itemId,
    this.portIndex,
    this.newValue,
    this.oldValue,
  );

  @override
  void execute() {
    calculatorManager.updatePortValue(itemId, portIndex, newValue);
  }

  @override
  void undo() {
    calculatorManager.updatePortValue(itemId, portIndex, oldValue);
  }

  @override
  String get description => 'Change ${itemId} value to $newValue';
}

/// Command for moving an item
class MoveItemCommand extends CalculatorCommand {
  final String itemId;
  final Offset newPosition;
  final Offset oldPosition;
  final Map<String, Offset> itemPositions;

  MoveItemCommand(
    this.itemId,
    this.newPosition,
    this.oldPosition,
    this.itemPositions,
  );

  @override
  void execute() {
    itemPositions[itemId] = newPosition;
  }

  @override
  void undo() {
    itemPositions[itemId] = oldPosition;
  }

  @override
  String get description => 'Move ${itemId}';
}

/// Command for editing an item's properties
class EditItemCommand extends CalculatorCommand {
  final CalculatorManager calculatorManager;
  final String itemId;
  final String newName;
  final String oldName;
  final OperationType newType;
  final OperationType oldType;
  final Map<String, Offset> itemPositions;
  final Map<String, dynamic> itemKeys;

  EditItemCommand(
    this.calculatorManager,
    this.itemId,
    this.newName,
    this.oldName,
    this.newType,
    this.oldType,
    this.itemPositions,
    this.itemKeys,
  );

  @override
  void execute() {
    CalculatorItem? item = calculatorManager.findItemById(itemId);
    if (item != null) {
      // Store current port values before changing type
      Map<int, double> oldValues = {};
      for (var port in item.ports) {
        oldValues[port.index] = port.value;
      }

      // Update name
      item.id = newName;

      // Handle position and key updates if name changes
      if (oldName != newName) {
        if (itemPositions.containsKey(oldName)) {
          final position = itemPositions[oldName];
          itemPositions.remove(oldName);
          itemPositions[newName] = position!;
        }

        if (itemKeys.containsKey(oldName)) {
          final key = itemKeys[oldName];
          itemKeys.remove(oldName);
          itemKeys[newName] = key!;
        }
      }

      // Change operation type if different
      if (item.operationType != newType) {
        item.updateOperationType(newType);

        // Copy over old values where possible
        for (var port in item.ports) {
          if (port.isInput && oldValues.containsKey(port.index)) {
            port.value = oldValues[port.index]!;
          }
        }
      }

      calculatorManager.recalculateAll();
    }
  }

  @override
  void undo() {
    CalculatorItem? item = calculatorManager.findItemById(newName);
    if (item != null) {
      // Store current port values before changing type
      Map<int, double> oldValues = {};
      for (var port in item.ports) {
        oldValues[port.index] = port.value;
      }

      // Update name
      item.id = oldName;

      // Handle position and key updates if name changes
      if (oldName != newName) {
        if (itemPositions.containsKey(newName)) {
          final position = itemPositions[newName];
          itemPositions.remove(newName);
          itemPositions[oldName] = position!;
        }

        if (itemKeys.containsKey(newName)) {
          final key = itemKeys[newName];
          itemKeys.remove(newName);
          itemKeys[oldName] = key!;
        }
      }

      // Change operation type back if different
      if (item.operationType != oldType) {
        item.updateOperationType(oldType);

        // Copy over old values where possible
        for (var port in item.ports) {
          if (port.isInput && oldValues.containsKey(port.index)) {
            port.value = oldValues[port.index]!;
          }
        }
      }

      calculatorManager.recalculateAll();
    }
  }

  @override
  String get description => 'Edit ${oldName} to ${newName}';
}

/// Command history manager to track undo/redo operations
class CommandHistory {
  final List<CalculatorCommand> _undoStack = [];
  final List<CalculatorCommand> _redoStack = [];
  final int _maxHistorySize;

  CommandHistory({int maxHistorySize = 100}) : _maxHistorySize = maxHistorySize;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void execute(CalculatorCommand command) {
    command.execute();
    _undoStack.add(command);

    // Clear redo stack when new command is executed
    _redoStack.clear();

    // Limit history size
    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeAt(0);
    }
  }

  void undo() {
    if (canUndo) {
      final command = _undoStack.removeLast();
      command.undo();
      _redoStack.add(command);
    }
  }

  void redo() {
    if (canRedo) {
      final command = _redoStack.removeLast();
      command.redo();
      _undoStack.add(command);
    }
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }

  String? get lastUndoDescription =>
      canUndo ? _undoStack.last.description : null;

  String? get lastRedoDescription =>
      canRedo ? _redoStack.last.description : null;
}
