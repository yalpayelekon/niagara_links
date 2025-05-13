import 'port_type.dart';

abstract class Port {
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

  bool canConnectTo(Port otherPort) {
    if (isInput == otherPort.isInput) return false;

    return type.type == PortType.ANY ||
        otherPort.type.type == PortType.ANY ||
        type == otherPort.type;
  }
}

class Property extends Port {
  Property({
    required super.isInput,
    required super.index,
    required super.name,
    required super.type,
    super.value,
  });

  factory Property.withDefaultValue({
    required bool isInput,
    required int index,
    required String name,
    required PortType type,
  }) {
    dynamic defaultValue;
    switch (type.type) {
      case PortType.BOOLEAN:
        defaultValue = false;
        break;
      case PortType.NUMERIC:
        defaultValue = 0.0;
        break;
      case PortType.STRING:
        defaultValue = '';
        break;
      case PortType.ANY:
        defaultValue = null;
        break;
    }

    return Property(
      isInput: isInput,
      index: index,
      name: name,
      type: type,
      value: defaultValue,
    );
  }
}

class Action extends Port {
  final PortType? parameterType;
  final PortType? returnType;

  Action({
    required super.index,
    required super.name,
    this.parameterType,
    this.returnType,
    super.value,
  }) : super(
          isInput: true,
          type: parameterType ?? PortType(PortType.ANY),
        );

  dynamic execute({dynamic parameter}) {
    return null;
  }
}

class Topic extends Port {
  final PortType eventType;

  Topic({
    required super.index,
    required super.name,
    required this.eventType,
  }) : super(
          isInput: false,
          type: eventType,
          value: null,
        );

  void fire(dynamic event) {
    value = event; // Store the last event value
  }
}
