// lib/calculator_connection.dart

import 'calculator_models.dart';

class CalculatorConnection {
  final String fromItemId;
  final int fromPortIndex;
  final String toItemId;
  final int toPortIndex;

  CalculatorConnection({
    required this.fromItemId,
    required this.fromPortIndex,
    required this.toItemId,
    required this.toPortIndex,
  });

  // Check if this connection comes from a specific item and port
  bool isFromItem(String itemId, int portIndex) {
    return fromItemId == itemId && fromPortIndex == portIndex;
  }

  // Check if this connection goes to a specific item and port
  bool isToItem(String itemId, int portIndex) {
    return toItemId == itemId && toPortIndex == portIndex;
  }
}

// A manager class to handle calculator operations and value propagation
class CalculatorManager {
  List<CalculatorItem> items = [];
  List<CalculatorConnection> connections = [];

  // Add a new item to the calculator
  void addItem(CalculatorItem item) {
    items.add(item);
  }

  // Remove an item from the calculator
  void removeItem(String itemId) {
    items.removeWhere((item) => item.id == itemId);
    connections.removeWhere(
      (connection) =>
          connection.fromItemId == itemId || connection.toItemId == itemId,
    );

    // Recalculate after removing an item
    recalculateAll();
  }

  // Connect two calculator ports
  void createConnection(
      String fromItemId, int fromPortIndex, String toItemId, int toPortIndex) {
    // Check if the connection already exists
    bool connectionExists = connections.any((connection) =>
        connection.fromItemId == fromItemId &&
        connection.fromPortIndex == fromPortIndex &&
        connection.toItemId == toItemId &&
        connection.toPortIndex == toPortIndex);

    if (!connectionExists) {
      // Check that source is an output and destination is an input
      CalculatorItem? fromItem = findItemById(fromItemId);
      CalculatorItem? toItem = findItemById(toItemId);

      if (fromItem != null &&
          toItem != null &&
          fromPortIndex < fromItem.ports.length &&
          toPortIndex < toItem.ports.length) {
        if (!fromItem.ports[fromPortIndex].isInput &&
            toItem.ports[toPortIndex].isInput) {
          connections.add(CalculatorConnection(
            fromItemId: fromItemId,
            fromPortIndex: fromPortIndex,
            toItemId: toItemId,
            toPortIndex: toPortIndex,
          ));

          toItem.inputConnections[toPortIndex] = ConnectionEndpoint(
            itemId: fromItemId,
            portIndex: fromPortIndex,
          );

          propagateValue(fromItem, fromPortIndex);
        }
      }
    }
  }

  void removeConnection(
      String fromItemId, int fromPortIndex, String toItemId, int toPortIndex) {
    connections.removeWhere((connection) =>
        connection.fromItemId == fromItemId &&
        connection.fromPortIndex == fromPortIndex &&
        connection.toItemId == toItemId &&
        connection.toPortIndex == toPortIndex);

    CalculatorItem? toItem = findItemById(toItemId);
    if (toItem != null) {
      toItem.inputConnections.remove(toPortIndex);
    }

    recalculateAll();
  }

  CalculatorItem? findItemById(String id) {
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  void updatePortValue(String itemId, int portIndex, double value) {
    CalculatorItem? item = findItemById(itemId);
    if (item != null && portIndex < item.ports.length) {
      item.ports[portIndex].value = value;

      if (!item.ports[portIndex].isInput) {
        propagateValue(item, portIndex);
      } else {
        item.calculate();
        for (var port in item.ports) {
          if (!port.isInput) {
            propagateValue(item, port.index);
          }
        }
      }
    }
  }

  void propagateValue(CalculatorItem sourceItem, int sourcePortIndex) {
    if (sourcePortIndex >= sourceItem.ports.length ||
        sourceItem.ports[sourcePortIndex].isInput) {
      return;
    }

    double valueToPropagate = sourceItem.ports[sourcePortIndex].value;

    List<CalculatorConnection> outgoingConnections = connections
        .where((connection) =>
            connection.isFromItem(sourceItem.id, sourcePortIndex))
        .toList();

    for (var connection in outgoingConnections) {
      CalculatorItem? targetItem = findItemById(connection.toItemId);
      if (targetItem != null &&
          connection.toPortIndex < targetItem.ports.length) {
        targetItem.ports[connection.toPortIndex].value = valueToPropagate;

        targetItem.calculate();

        for (var port in targetItem.ports) {
          if (!port.isInput) {
            propagateValue(targetItem, port.index);
          }
        }
      }
    }
  }

  void recalculateAll() {
    for (var item in items) {
      for (var entry in item.inputConnections.entries) {
        int portIndex = entry.key;
        if (portIndex < item.ports.length && item.ports[portIndex].isInput) {
          item.ports[portIndex].value = 0.0; // Reset to prevent old values
        }
      }
    }

    for (var item in items) {
      if (item.operationType == OperationType.input ||
          item.inputConnections.isEmpty) {
        item.calculate();
      }
    }

    for (var item in items) {
      for (var port in item.ports) {
        if (!port.isInput) {
          propagateValue(item, port.index);
        }
      }
    }
  }
}
