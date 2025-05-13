// point_components.dart
import 'component.dart';
import 'component_type.dart';
import 'port.dart';
import 'port_type.dart';

class PointComponent extends Component {
  PointComponent({
    required super.id,
    required super.type,
  }) {
    _setupPorts();
  }

  void _setupPorts() {
    switch (type.type) {
      case ComponentType.BOOLEAN_WRITABLE:
        properties.add(Property.withDefaultValue(
            name: "Output",
            index: 0,
            isInput: false,
            type: PortType(PortType.BOOLEAN)));
        break;

      case ComponentType.NUMERIC_WRITABLE:
        properties.add(Property.withDefaultValue(
            name: "Output",
            index: 0,
            isInput: false,
            type: PortType(PortType.NUMERIC)));
        break;

      case ComponentType.STRING_WRITABLE:
        properties.add(Property.withDefaultValue(
            name: "Output",
            index: 0,
            isInput: false,
            type: PortType(PortType.STRING)));
        break;

      case ComponentType.BOOLEAN_POINT:
        properties.add(Property.withDefaultValue(
            name: "Output",
            index: 0,
            isInput: false,
            type: PortType(PortType.BOOLEAN)));
        break;

      case ComponentType.NUMERIC_POINT:
        properties.add(Property.withDefaultValue(
            name: "Output",
            index: 0,
            isInput: false,
            type: PortType(PortType.NUMERIC)));
        break;

      case ComponentType.STRING_POINT:
        properties.add(Property.withDefaultValue(
            name: "Output",
            index: 0,
            isInput: false,
            type: PortType(PortType.STRING)));
        break;
    }
  }

  @override
  void calculate() {}
}
