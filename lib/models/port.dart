import 'port_type.dart';

class Port {
  final bool isInput;
  final int index;
  final String name;
  final PortType type;
  dynamic value; // Can store boolean, number, or string

  Port({
    required this.isInput,
    required this.index,
    required this.name,
    required this.type,
    this.value,
  });

  factory Port.withDefaultValue({
    required bool isInput,
    required int index,
    required String name,
    required PortType type,
  }) {
    dynamic defaultValue;
    if (type.type == PortType.BOOLEAN) {
      defaultValue = false;
    } else if (type.type == PortType.NUMERIC) {
      defaultValue = 0.0;
    } else if (type.type == PortType.STRING) {
      defaultValue = '';
    } else if (type.type == PortType.ANY) {
      defaultValue = null;
    }

    return Port(
      isInput: isInput,
      index: index,
      name: name,
      type: type,
      value: defaultValue,
    );
  }

  // Check if this port can connect to another port
  bool canConnectTo(Port otherPort) {
    // Input can only connect to output and vice versa
    if (isInput == otherPort.isInput) return false;

    // Check type compatibility
    return type.type == PortType.ANY ||
        otherPort.type.type == PortType.ANY ||
        type.type == otherPort.type.type;
  }
}
