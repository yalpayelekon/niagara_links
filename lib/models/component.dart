import 'dart:math' show pow;
import 'port.dart';
import 'connection.dart';
import 'component_type.dart';
import 'port_type.dart';

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

    switch (type.type) {
      // Logic gates
      case ComponentType.AND_GATE:
      case ComponentType.OR_GATE:
      case ComponentType.XOR_GATE:
        ports.add(Port.withDefaultValue(
            isInput: true,
            index: 0,
            name: "Input A",
            type: PortType(PortType.BOOLEAN)));
        ports.add(Port.withDefaultValue(
            isInput: true,
            index: 1,
            name: "Input B",
            type: PortType(PortType.BOOLEAN)));
        ports.add(Port.withDefaultValue(
            isInput: false,
            index: 2,
            name: "Output",
            type: PortType(PortType.BOOLEAN)));
        break;

      case ComponentType.NOT_GATE:
        ports.add(Port.withDefaultValue(
            isInput: true,
            index: 0,
            name: "Input",
            type: PortType(PortType.BOOLEAN)));
        ports.add(Port.withDefaultValue(
            isInput: false,
            index: 1,
            name: "Output",
            type: PortType(PortType.BOOLEAN)));
        break;

      // Math components
      case ComponentType.ADD:
      case ComponentType.SUBTRACT:
      case ComponentType.MULTIPLY:
      case ComponentType.DIVIDE:
      case ComponentType.MAX:
      case ComponentType.MIN:
        ports.add(Port.withDefaultValue(
            isInput: true,
            index: 0,
            name: "Input A",
            type: PortType(PortType.NUMERIC)));
        ports.add(Port.withDefaultValue(
            isInput: true,
            index: 1,
            name: "Input B",
            type: PortType(PortType.NUMERIC)));
        ports.add(Port.withDefaultValue(
            isInput: false,
            index: 2,
            name: "Output",
            type: PortType(PortType.NUMERIC)));
        break;

      case ComponentType.POWER:
        ports.add(Port.withDefaultValue(
            isInput: true,
            index: 0,
            name: "Base",
            type: PortType(PortType.NUMERIC)));
        ports.add(Port.withDefaultValue(
            isInput: true,
            index: 1,
            name: "Exponent",
            type: PortType(PortType.NUMERIC)));
        ports.add(Port.withDefaultValue(
            isInput: false,
            index: 2,
            name: "Output",
            type: PortType(PortType.NUMERIC)));
        break;

      case ComponentType.ABS:
        ports.add(Port.withDefaultValue(
            isInput: true,
            index: 0,
            name: "Input",
            type: PortType(PortType.NUMERIC)));
        ports.add(Port.withDefaultValue(
            isInput: false,
            index: 1,
            name: "Output",
            type: PortType(PortType.NUMERIC)));
        break;

      // Comparison components
      case ComponentType.IS_GREATER_THAN:
      case ComponentType.IS_LESS_THAN:
        ports.add(Port.withDefaultValue(
            isInput: true,
            index: 0,
            name: "Input A",
            type: PortType(PortType.NUMERIC)));
        ports.add(Port.withDefaultValue(
            isInput: true,
            index: 1,
            name: "Input B",
            type: PortType(PortType.NUMERIC)));
        ports.add(Port.withDefaultValue(
            isInput: false,
            index: 2,
            name: "Output",
            type: PortType(PortType.BOOLEAN)));
        break;

      case ComponentType.IS_EQUAL:
        ports.add(Port.withDefaultValue(
            isInput: true,
            index: 0,
            name: "Input A",
            type: PortType(PortType.ANY)));
        ports.add(Port.withDefaultValue(
            isInput: true,
            index: 1,
            name: "Input B",
            type: PortType(PortType.ANY)));
        ports.add(Port.withDefaultValue(
            isInput: false,
            index: 2,
            name: "Output",
            type: PortType(PortType.BOOLEAN)));
        break;

      // Writable points
      case ComponentType.BOOLEAN_WRITABLE:
        ports.add(Port.withDefaultValue(
            isInput: false,
            index: 0,
            name: "Output",
            type: PortType(PortType.BOOLEAN)));
        break;

      case ComponentType.NUMERIC_WRITABLE:
        ports.add(Port.withDefaultValue(
            isInput: false,
            index: 0,
            name: "Output",
            type: PortType(PortType.NUMERIC)));
        break;

      case ComponentType.STRING_WRITABLE:
        ports.add(Port.withDefaultValue(
            isInput: false,
            index: 0,
            name: "Output",
            type: PortType(PortType.STRING)));
        break;

      // Read-only points
      case ComponentType.BOOLEAN_POINT:
        ports.add(Port.withDefaultValue(
            isInput: false,
            index: 0,
            name: "Output",
            type: PortType(PortType.BOOLEAN)));
        break;

      case ComponentType.NUMERIC_POINT:
        ports.add(Port.withDefaultValue(
            isInput: false,
            index: 0,
            name: "Output",
            type: PortType(PortType.NUMERIC)));
        break;

      case ComponentType.STRING_POINT:
        ports.add(Port.withDefaultValue(
            isInput: false,
            index: 0,
            name: "Output",
            type: PortType(PortType.STRING)));
        break;
    }
  }

  // Calculate the output based on inputs
  void calculate() {
    switch (type.type) {
      // Logic Gates
      case ComponentType.AND_GATE:
        final bool inputA = ports[0].value as bool;
        final bool inputB = ports[1].value as bool;
        ports[2].value = inputA && inputB;
        break;

      case ComponentType.OR_GATE:
        final bool inputA = ports[0].value as bool;
        final bool inputB = ports[1].value as bool;
        ports[2].value = inputA || inputB;
        break;

      case ComponentType.XOR_GATE:
        final bool inputA = ports[0].value as bool;
        final bool inputB = ports[1].value as bool;
        ports[2].value = inputA != inputB;
        break;

      case ComponentType.NOT_GATE:
        final bool input = ports[0].value as bool;
        ports[1].value = !input;
        break;

      // Math Components
      case ComponentType.ADD:
        final num inputA = ports[0].value as num;
        final num inputB = ports[1].value as num;
        ports[2].value = inputA + inputB;
        break;

      case ComponentType.SUBTRACT:
        final num inputA = ports[0].value as num;
        final num inputB = ports[1].value as num;
        ports[2].value = inputA - inputB;
        break;

      case ComponentType.MULTIPLY:
        final num inputA = ports[0].value as num;
        final num inputB = ports[1].value as num;
        ports[2].value = inputA * inputB;
        break;

      case ComponentType.DIVIDE:
        final num inputA = ports[0].value as num;
        final num inputB = ports[1].value as num;
        // Check for division by zero
        ports[2].value = inputB != 0 ? inputA / inputB : double.infinity;
        break;

      case ComponentType.MAX:
        final num inputA = ports[0].value as num;
        final num inputB = ports[1].value as num;
        ports[2].value = inputA > inputB ? inputA : inputB;
        break;

      case ComponentType.MIN:
        final num inputA = ports[0].value as num;
        final num inputB = ports[1].value as num;
        ports[2].value = inputA < inputB ? inputA : inputB;
        break;

      case ComponentType.POWER:
        final num base = ports[0].value as num;
        final num exponent = ports[1].value as num;
        ports[2].value = pow(base, exponent);
        break;

      case ComponentType.ABS:
        final num input = ports[0].value as num;
        ports[1].value = input.abs();
        break;

      // Comparison Components
      case ComponentType.IS_GREATER_THAN:
        final num inputA = ports[0].value as num;
        final num inputB = ports[1].value as num;
        ports[2].value = inputA > inputB;
        break;

      case ComponentType.IS_LESS_THAN:
        final num inputA = ports[0].value as num;
        final num inputB = ports[1].value as num;
        ports[2].value = inputA < inputB;
        break;

      case ComponentType.IS_EQUAL:
        final dynamic inputA = ports[0].value;
        final dynamic inputB = ports[1].value;
        ports[2].value = inputA == inputB;
        break;

      // Input components don't need calculation
      case ComponentType.BOOLEAN_WRITABLE:
      case ComponentType.NUMERIC_WRITABLE:
      case ComponentType.STRING_WRITABLE:
      case ComponentType.BOOLEAN_POINT:
      case ComponentType.NUMERIC_POINT:
      case ComponentType.STRING_POINT:
        break;
    }
  }
}
