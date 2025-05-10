import 'enums.dart';

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
    switch (type) {
      case PortType.boolean:
        defaultValue = false;
        break;
      case PortType.number:
        defaultValue = 0.0;
        break;
      case PortType.string:
        defaultValue = '';
        break;
      case PortType.any:
        defaultValue = null;
        break;
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
    return type == PortType.any ||
        otherPort.type == PortType.any ||
        type == otherPort.type;
  }
}
