import 'port_type.dart';

// Base Slot interface
abstract class Slot {
  final String name;
  final int index;

  Slot({
    required this.name,
    required this.index,
  });
}

// Property slot (formerly Port)
class Property extends Slot {
  final bool isInput;
  final PortType type;
  dynamic value; // Can store boolean, number, or string

  Property({
    required super.name,
    required super.index,
    required this.isInput,
    required this.type,
    this.value,
  });

  factory Property.withDefaultValue({
    required String name,
    required int index,
    required bool isInput,
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
      name: name,
      index: index,
      isInput: isInput,
      type: type,
      value: defaultValue,
    );
  }

  bool canConnectTo(Property otherProperty) {
    if (isInput == otherProperty.isInput) return false;

    return type.type == PortType.ANY ||
        otherProperty.type.type == PortType.ANY ||
        type == otherProperty.type;
  }
}

class ActionSlot extends Slot {
  final PortType? parameterType;
  final PortType? returnType;
  dynamic parameter;
  dynamic returnValue;

  ActionSlot({
    required super.name,
    required super.index,
    this.parameterType,
    this.returnType,
    this.parameter,
    this.returnValue,
  });

  dynamic execute({dynamic parameter}) {
    // Base implementation - should be overridden
    this.parameter = parameter;
    return returnValue;
  }
}

// Topic slot
class Topic extends Slot {
  final PortType eventType;
  dynamic lastEvent;

  Topic({
    required super.name,
    required super.index,
    required this.eventType,
  });

  void fire(dynamic event) {
    lastEvent = event; // Store the last event value
  }
}
