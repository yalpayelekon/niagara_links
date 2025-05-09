// lib/logic/logic_models.dart

enum LogicOperationType {
  and,
  or,
  xor,
  not,
  input,
}

class LogicPort {
  final bool isInput; // true for input, false for output
  bool value;
  final int index;

  LogicPort({
    required this.isInput,
    this.value = false,
    required this.index,
  });
}

class LogicItem {
  String id;
  LogicOperationType operationType;
  List<LogicPort> ports = [];

  Map<int, LogicConnectionEndpoint> inputConnections = {};

  LogicItem({
    required this.id,
    required this.operationType,
  }) {
    _setupPorts();
  }

  void _setupPorts() {
    ports.clear();

    switch (operationType) {
      case LogicOperationType.and:
      case LogicOperationType.or:
      case LogicOperationType.xor:
        ports.add(LogicPort(isInput: true, index: 0)); // Input A
        ports.add(LogicPort(isInput: true, index: 1)); // Input B
        ports.add(LogicPort(isInput: false, index: 2)); // Output
        break;
      case LogicOperationType.input:
        ports.add(LogicPort(isInput: false, index: 0)); // Output
        break;
      case LogicOperationType.not:
        ports.add(LogicPort(isInput: true, index: 0)); // Input
        ports.add(LogicPort(isInput: false, index: 1)); // Output
        break;
    }
  }

  void calculate() {
    if (operationType == LogicOperationType.input) {
      // Input nodes don't need calculation
      return;
    }

    if (operationType == LogicOperationType.not) {
      bool input = ports[0].value;
      bool result = !input;
      ports.firstWhere((port) => !port.isInput).value = result;
      return;
    }

    bool inputA = ports[0].value;
    bool inputB = ports[1].value;
    bool result = false;

    switch (operationType) {
      case LogicOperationType.and:
        result = inputA && inputB;
        break;
      case LogicOperationType.or:
        result = inputA || inputB;
        break;
      case LogicOperationType.xor:
        result = inputA != inputB;
        break;
      default:
        break;
    }

    ports.firstWhere((port) => !port.isInput).value = result;
  }

  void updateOperationType(LogicOperationType newType) {
    operationType = newType;
    _setupPorts();
  }
}

class LogicConnectionEndpoint {
  final String itemId;
  final int portIndex;

  LogicConnectionEndpoint({
    required this.itemId,
    required this.portIndex,
  });
}

// Now let's create the LogicConnection class

class LogicConnection {
  final String fromItemId;
  final int fromPortIndex;
  final String toItemId;
  final int toPortIndex;

  LogicConnection({
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
