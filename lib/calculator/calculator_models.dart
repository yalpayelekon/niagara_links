enum OperationType {
  add,
  subtract,
  multiply,
  divide,
  input, // A simple input node for entering values
}

class CalculatorPort {
  final bool isInput; // true for input, false for output
  double value;
  final int index;

  CalculatorPort({
    required this.isInput,
    this.value = 0.0,
    required this.index,
  });
}

class CalculatorItem {
  String id;
  OperationType operationType;
  List<CalculatorPort> ports = [];

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
      case OperationType.add:
      case OperationType.subtract:
      case OperationType.multiply:
      case OperationType.divide:
        ports.add(CalculatorPort(isInput: true, index: 0)); // Input A
        ports.add(CalculatorPort(isInput: true, index: 1)); // Input B
        ports.add(CalculatorPort(isInput: false, index: 2)); // Output
        break;
      case OperationType.input:
        ports.add(CalculatorPort(isInput: false, index: 0)); // Output
        break;
    }
  }

  void calculate() {
    if (operationType == OperationType.input) {
      // Input nodes don't need calculation
      return;
    }

    double inputA = ports[0].value;
    double inputB = ports[1].value;
    double result = 0.0;

    switch (operationType) {
      case OperationType.add:
        result = inputA + inputB;
        break;
      case OperationType.subtract:
        result = inputA - inputB;
        break;
      case OperationType.multiply:
        result = inputA * inputB;
        break;
      case OperationType.divide:
        // Prevent division by zero
        result = inputB != 0 ? inputA / inputB : double.infinity;
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
