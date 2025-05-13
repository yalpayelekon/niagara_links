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

        properties.add(Property.withDefaultValue(
            name: "In1",
            index: 1,
            isInput: true,
            type: PortType(PortType.BOOLEAN)));

        properties.add(Property.withDefaultValue(
            name: "In2",
            index: 2,
            isInput: true,
            type: PortType(PortType.BOOLEAN)));

        properties.add(Property.withDefaultValue(
            name: "In3",
            index: 3,
            isInput: true,
            type: PortType(PortType.BOOLEAN)));

        properties.add(Property.withDefaultValue(
            name: "In4",
            index: 4,
            isInput: true,
            type: PortType(PortType.BOOLEAN)));
        break;

      case ComponentType.NUMERIC_WRITABLE:
        properties.add(Property.withDefaultValue(
            name: "Output",
            index: 0,
            isInput: false,
            type: PortType(PortType.NUMERIC)));

        properties.add(Property.withDefaultValue(
            name: "In1",
            index: 1,
            isInput: true,
            type: PortType(PortType.NUMERIC)));

        properties.add(Property.withDefaultValue(
            name: "In2",
            index: 2,
            isInput: true,
            type: PortType(PortType.NUMERIC)));

        properties.add(Property.withDefaultValue(
            name: "In3",
            index: 3,
            isInput: true,
            type: PortType(PortType.NUMERIC)));

        properties.add(Property.withDefaultValue(
            name: "In4",
            index: 4,
            isInput: true,
            type: PortType(PortType.NUMERIC)));
        break;

      case ComponentType.STRING_WRITABLE:
        properties.add(Property.withDefaultValue(
            name: "Output",
            index: 0,
            isInput: false,
            type: PortType(PortType.STRING)));

        properties.add(Property.withDefaultValue(
            name: "In1",
            index: 1,
            isInput: true,
            type: PortType(PortType.STRING)));

        properties.add(Property.withDefaultValue(
            name: "In2",
            index: 2,
            isInput: true,
            type: PortType(PortType.STRING)));

        properties.add(Property.withDefaultValue(
            name: "In3",
            index: 3,
            isInput: true,
            type: PortType(PortType.STRING)));

        properties.add(Property.withDefaultValue(
            name: "In4",
            index: 4,
            isInput: true,
            type: PortType(PortType.STRING)));
        break;

      case ComponentType.BOOLEAN_POINT:
        properties.add(Property.withDefaultValue(
            name: "Input",
            index: 0,
            isInput: true,
            type: PortType(PortType.BOOLEAN)));
        break;

      case ComponentType.NUMERIC_POINT:
        properties.add(Property.withDefaultValue(
            name: "Input",
            index: 0,
            isInput: true,
            type: PortType(PortType.NUMERIC)));
        break;

      case ComponentType.STRING_POINT:
        properties.add(Property.withDefaultValue(
            name: "Input",
            index: 0,
            isInput: true,
            type: PortType(PortType.STRING)));
        break;
    }
  }

  @override
  void calculate() {
    // For writable point types, implement input precedence logic
    if (type.type == ComponentType.BOOLEAN_WRITABLE ||
        type.type == ComponentType.NUMERIC_WRITABLE ||
        type.type == ComponentType.STRING_WRITABLE) {
      // Get the output property
      Property outputProperty = properties[0];

      // Default value if no inputs have values
      dynamic currentValue = outputProperty.value;

      // Check input properties in order of precedence (lowest index first)
      for (int i = 1; i <= 4; i++) {
        Property inputProperty = properties[i];

        // If an input has a valid connection and a non-null value, use it
        if (inputConnections.containsKey(inputProperty.index)) {
          if (inputProperty.value != null) {
            // Found a valid input value, use it
            currentValue = inputProperty.value;
            // Break as we found a value from the highest precedence input
            break;
          }
        }
      }

      // Update the output property with the calculated value
      outputProperty.value = currentValue;
    }
  }
}
