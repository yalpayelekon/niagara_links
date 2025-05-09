enum OperationType {
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

class CalculatorItem {
  String id;
  OperationType operationType;
  List<LogicPort> ports = [];

  Map<int, ConnectionEndpoint> inputConnections = {};

  CalculatorItem({
    required this.id,
    required this.operationType,
  }) {
    _setupPorts();
  }

  void _setupPorts() {
    ports.clear();

    switch (operationType) {
      case OperationType.and:
      case OperationType.or:
      case OperationType.xor:
        ports.add(LogicPort(isInput: true, index: 0)); // Input A
        ports.add(LogicPort(isInput: true, index: 1)); // Input B
        ports.add(LogicPort(isInput: false, index: 2)); // Output
        break;
      case OperationType.input:
        ports.add(LogicPort(isInput: false, index: 0)); // Output
        break;
      case OperationType.not:
        ports.add(LogicPort(isInput: true, index: 0)); // Input
        ports.add(LogicPort(isInput: false, index: 1)); // Output
        break;
    }
  }

  void calculate() {
    if (operationType == OperationType.input) {
      // Input nodes don't need calculation
      return;
    }

    if (operationType == OperationType.not) {
      bool input = ports[0].value;
      bool result = !input;
      ports[1].value = result;
      return;
    }

    bool inputA = ports[0].value;
    bool inputB = ports[1].value;
    bool result = false;

    switch (operationType) {
      case OperationType.and:
        result = inputA && inputB;
        break;
      case OperationType.or:
        result = inputA || inputB;
        break;
      case OperationType.xor:
        result = inputA != inputB;
        break;
      default:
        break;
    }

    ports.firstWhere((port) => !port.isInput).value = result;
  }

  void updateOperationType(OperationType newType) {
    operationType = newType;
    _setupPorts();
  }
}

class ConnectionEndpoint {
  final String itemId;
  final int portIndex;

  ConnectionEndpoint({
    required this.itemId,
    required this.portIndex,
  });
}
