// logic_components.dart
import 'component.dart';
import 'component_type.dart';
import 'port.dart';
import 'port_type.dart';

class LogicComponent extends Component {
  LogicComponent({
    required super.id,
    required super.type,
  }) {
    _setupPorts();
  }

  void _setupPorts() {
    switch (type.type) {
      case ComponentType.AND_GATE:
      case ComponentType.OR_GATE:
      case ComponentType.XOR_GATE:
        properties.add(Property.withDefaultValue(
            name: "Input A",
            index: 0,
            isInput: true,
            type: PortType(PortType.BOOLEAN)));
        properties.add(Property.withDefaultValue(
            name: "Input B",
            index: 1,
            isInput: true,
            type: PortType(PortType.BOOLEAN)));
        properties.add(Property.withDefaultValue(
            name: "Output",
            index: 2,
            isInput: false,
            type: PortType(PortType.BOOLEAN)));
        break;

      case ComponentType.NOT_GATE:
        properties.add(Property.withDefaultValue(
            name: "Input",
            index: 0,
            isInput: true,
            type: PortType(PortType.BOOLEAN)));
        properties.add(Property.withDefaultValue(
            name: "Output",
            index: 1,
            isInput: false,
            type: PortType(PortType.BOOLEAN)));
        break;

      case ComponentType.IS_GREATER_THAN:
      case ComponentType.IS_LESS_THAN:
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
            type: PortType(PortType.BOOLEAN)));
        break;

      case ComponentType.IS_EQUAL:
        properties.add(Property.withDefaultValue(
            name: "Input A",
            index: 0,
            isInput: true,
            type: PortType(PortType.ANY)));
        properties.add(Property.withDefaultValue(
            name: "Input B",
            index: 1,
            isInput: true,
            type: PortType(PortType.ANY)));
        properties.add(Property.withDefaultValue(
            name: "Output",
            index: 2,
            isInput: false,
            type: PortType(PortType.BOOLEAN)));
        break;
    }
  }

  @override
  void calculate() {
    switch (type.type) {
      // Logic Gates
      case ComponentType.AND_GATE:
        final bool inputA = properties[0].value as bool;
        final bool inputB = properties[1].value as bool;
        properties[2].value = inputA && inputB;
        break;

      case ComponentType.OR_GATE:
        final bool inputA = properties[0].value as bool;
        final bool inputB = properties[1].value as bool;
        properties[2].value = inputA || inputB;
        break;

      case ComponentType.XOR_GATE:
        final bool inputA = properties[0].value as bool;
        final bool inputB = properties[1].value as bool;
        properties[2].value = inputA != inputB;
        break;

      case ComponentType.NOT_GATE:
        final bool input = properties[0].value as bool;
        properties[1].value = !input;
        break;

      // Comparison Components
      case ComponentType.IS_GREATER_THAN:
        final num inputA = properties[0].value as num;
        final num inputB = properties[1].value as num;
        properties[2].value = inputA > inputB;
        break;

      case ComponentType.IS_LESS_THAN:
        final num inputA = properties[0].value as num;
        final num inputB = properties[1].value as num;
        properties[2].value = inputA < inputB;
        break;

      case ComponentType.IS_EQUAL:
        final dynamic inputA = properties[0].value;
        final dynamic inputB = properties[1].value;
        properties[2].value = inputA == inputB;
        break;
    }
  }
}
