import 'package:niagara_links/models/connection_endpoint.dart';
import 'package:niagara_links/models/enums.dart';
import 'package:niagara_links/models/port.dart';

class Component {
  String id;
  final ComponentType type;
  List<Port> ports = [];
  Map<int, ConnectionEndpoint> inputConnections = {};

  Component({
    required this.id,
    required this.type,
  }) {
    _setupPorts();
  }

  void _setupPorts() {
    ports.clear();

    switch (type) {
      // Logic gates
      case ComponentType.andGate:
      case ComponentType.orGate:
      case ComponentType.xorGate:
        ports.add(Port.withDefaultValue(
            isInput: true, index: 0, name: "Input A", type: PortType.boolean));
        ports.add(Port.withDefaultValue(
            isInput: true, index: 1, name: "Input B", type: PortType.boolean));
        ports.add(Port.withDefaultValue(
            isInput: false, index: 2, name: "Output", type: PortType.boolean));
        break;

      case ComponentType.notGate:
        ports.add(Port.withDefaultValue(
            isInput: true, index: 0, name: "Input", type: PortType.boolean));
        ports.add(Port.withDefaultValue(
            isInput: false, index: 1, name: "Output", type: PortType.boolean));
        break;

      // Math components
      case ComponentType.add:
      case ComponentType.subtract:
      case ComponentType.multiply:
      case ComponentType.divide:
        ports.add(Port.withDefaultValue(
            isInput: true, index: 0, name: "Input A", type: PortType.number));
        ports.add(Port.withDefaultValue(
            isInput: true, index: 1, name: "Input B", type: PortType.number));
        ports.add(Port.withDefaultValue(
            isInput: false, index: 2, name: "Output", type: PortType.number));
        break;

      // Comparison components
      case ComponentType.isGreaterThan:
      case ComponentType.isLessThan:
        ports.add(Port.withDefaultValue(
            isInput: true, index: 0, name: "Input A", type: PortType.number));
        ports.add(Port.withDefaultValue(
            isInput: true, index: 1, name: "Input B", type: PortType.number));
        ports.add(Port.withDefaultValue(
            isInput: false, index: 2, name: "Output", type: PortType.boolean));
        break;

      case ComponentType.isEqual:
        ports.add(Port.withDefaultValue(
            isInput: true, index: 0, name: "Input A", type: PortType.any));
        ports.add(Port.withDefaultValue(
            isInput: true, index: 1, name: "Input B", type: PortType.any));
        ports.add(Port.withDefaultValue(
            isInput: false, index: 2, name: "Output", type: PortType.boolean));
        break;

      // Input components
      case ComponentType.booleanInput:
        ports.add(Port.withDefaultValue(
            isInput: false, index: 0, name: "Output", type: PortType.boolean));
        break;

      case ComponentType.numberInput:
        ports.add(Port.withDefaultValue(
            isInput: false, index: 0, name: "Output", type: PortType.number));
        break;

      case ComponentType.stringInput:
        ports.add(Port.withDefaultValue(
            isInput: false, index: 0, name: "Output", type: PortType.string));
        break;
    }
  }

  // Calculate the output based on inputs
  void calculate() {
    switch (type) {
      // Logic Gates
      case ComponentType.andGate:
        final bool inputA = ports[0].value as bool;
        final bool inputB = ports[1].value as bool;
        ports[2].value = inputA && inputB;
        break;

      case ComponentType.orGate:
        final bool inputA = ports[0].value as bool;
        final bool inputB = ports[1].value as bool;
        ports[2].value = inputA || inputB;
        break;

      case ComponentType.xorGate:
        final bool inputA = ports[0].value as bool;
        final bool inputB = ports[1].value as bool;
        ports[2].value = inputA != inputB;
        break;

      case ComponentType.notGate:
        final bool input = ports[0].value as bool;
        ports[1].value = !input;
        break;

      // Math Components
      case ComponentType.add:
        final num inputA = ports[0].value as num;
        final num inputB = ports[1].value as num;
        ports[2].value = inputA + inputB;
        break;

      case ComponentType.subtract:
        final num inputA = ports[0].value as num;
        final num inputB = ports[1].value as num;
        ports[2].value = inputA - inputB;
        break;

      case ComponentType.multiply:
        final num inputA = ports[0].value as num;
        final num inputB = ports[1].value as num;
        ports[2].value = inputA * inputB;
        break;

      case ComponentType.divide:
        final num inputA = ports[0].value as num;
        final num inputB = ports[1].value as num;
        // Check for division by zero
        ports[2].value = inputB != 0 ? inputA / inputB : double.infinity;
        break;

      // Comparison Components
      case ComponentType.isGreaterThan:
        final num inputA = ports[0].value as num;
        final num inputB = ports[1].value as num;
        ports[2].value = inputA > inputB;
        break;

      case ComponentType.isLessThan:
        final num inputA = ports[0].value as num;
        final num inputB = ports[1].value as num;
        ports[2].value = inputA < inputB;
        break;

      case ComponentType.isEqual:
        final dynamic inputA = ports[0].value;
        final dynamic inputB = ports[1].value;
        ports[2].value = inputA == inputB;
        break;

      // Input components don't need calculation
      case ComponentType.booleanInput:
      case ComponentType.numberInput:
      case ComponentType.stringInput:
        break;
    }
  }
}
