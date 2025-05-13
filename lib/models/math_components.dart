// math_components.dart
import 'dart:math' show pow;
import 'component.dart';
import 'component_type.dart';
import 'port.dart';
import 'port_type.dart';

class MathComponent extends Component {
  MathComponent({
    required super.id,
    required super.type,
  }) {
    _setupPorts();
  }

  void _setupPorts() {
    switch (type.type) {
      case ComponentType.ADD:
      case ComponentType.SUBTRACT:
      case ComponentType.MULTIPLY:
      case ComponentType.DIVIDE:
      case ComponentType.MAX:
      case ComponentType.MIN:
        properties.add(Property.withDefaultValue(
            name: "Input A",
            index: 0,
            isInput: true,
            type: PortType(PortType.NUMERIC)));
        properties.add(Property.withDefaultValue(
            name: "Input B",
            index: 1,
            isInput: true,
            type: PortType(PortType.NUMERIC)));
        properties.add(Property.withDefaultValue(
            name: "Output",
            index: 2,
            isInput: false,
            type: PortType(PortType.NUMERIC)));
        break;

      case ComponentType.POWER:
        properties.add(Property.withDefaultValue(
            name: "Base",
            index: 0,
            isInput: true,
            type: PortType(PortType.NUMERIC)));
        properties.add(Property.withDefaultValue(
            name: "Exponent",
            index: 1,
            isInput: true,
            type: PortType(PortType.NUMERIC)));
        properties.add(Property.withDefaultValue(
            name: "Output",
            index: 2,
            isInput: false,
            type: PortType(PortType.NUMERIC)));
        break;

      case ComponentType.ABS:
        properties.add(Property.withDefaultValue(
            name: "Input",
            index: 0,
            isInput: true,
            type: PortType(PortType.NUMERIC)));
        properties.add(Property.withDefaultValue(
            name: "Output",
            index: 1,
            isInput: false,
            type: PortType(PortType.NUMERIC)));
        break;
    }
  }

  @override
  void calculate() {
    switch (type.type) {
      case ComponentType.ADD:
        final num inputA = properties[0].value as num;
        final num inputB = properties[1].value as num;
        properties[2].value = inputA + inputB;
        break;

      case ComponentType.SUBTRACT:
        final num inputA = properties[0].value as num;
        final num inputB = properties[1].value as num;
        properties[2].value = inputA - inputB;
        break;

      case ComponentType.MULTIPLY:
        final num inputA = properties[0].value as num;
        final num inputB = properties[1].value as num;
        properties[2].value = inputA * inputB;
        break;

      case ComponentType.DIVIDE:
        final num inputA = properties[0].value as num;
        final num inputB = properties[1].value as num;
        // Check for division by zero
        properties[2].value = inputB != 0 ? inputA / inputB : double.infinity;
        break;

      case ComponentType.MAX:
        final num inputA = properties[0].value as num;
        final num inputB = properties[1].value as num;
        properties[2].value = inputA > inputB ? inputA : inputB;
        break;

      case ComponentType.MIN:
        final num inputA = properties[0].value as num;
        final num inputB = properties[1].value as num;
        properties[2].value = inputA < inputB ? inputA : inputB;
        break;

      case ComponentType.POWER:
        final num base = properties[0].value as num;
        final num exponent = properties[1].value as num;
        properties[2].value = pow(base, exponent);
        break;

      case ComponentType.ABS:
        final num input = properties[0].value as num;
        properties[1].value = input.abs();
        break;
    }
  }
}
