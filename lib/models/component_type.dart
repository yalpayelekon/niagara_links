class ComponentType {
  // Logic gates
  static const String AND_GATE = "AND_GATE";
  static const String OR_GATE = "OR_GATE";
  static const String XOR_GATE = "XOR_GATE";
  static const String NOT_GATE = "NOT_GATE";
  static const String IS_GREATER_THAN = "IS_GREATER_THAN";
  static const String IS_LESS_THAN = "IS_LESS_THAN";
  static const String IS_EQUAL = "IS_EQUAL";

  // Math operations
  static const String ADD = "ADD";
  static const String SUBTRACT = "SUBTRACT";
  static const String MULTIPLY = "MULTIPLY";
  static const String DIVIDE = "DIVIDE";
  static const String MAX = "MAX";
  static const String MIN = "MIN";
  static const String POWER = "POWER";
  static const String ABS = "ABS";

  // Writable points (inputs)
  static const String BOOLEAN_WRITABLE = "BOOLEAN_WRITABLE";
  static const String NUMERIC_WRITABLE = "NUMERIC_WRITABLE";
  static const String STRING_WRITABLE = "STRING_WRITABLE";

  // Read-only points
  static const String BOOLEAN_POINT = "BOOLEAN_POINT";
  static const String NUMERIC_POINT = "NUMERIC_POINT";
  static const String STRING_POINT = "STRING_POINT";

  final String type;

  const ComponentType(this.type);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ComponentType && other.type == type;

  @override
  int get hashCode => type.hashCode;

  bool get isLogicGate =>
      type == AND_GATE ||
      type == OR_GATE ||
      type == NOT_GATE ||
      type == AND_GATE ||
      type == IS_EQUAL ||
      type == IS_LESS_THAN ||
      type == IS_GREATER_THAN;

  bool get isMathOperation =>
      type == ADD ||
      type == SUBTRACT ||
      type == MULTIPLY ||
      type == DIVIDE ||
      type == MAX ||
      type == MIN ||
      type == POWER ||
      type == ABS;

  bool get isWritablePoint =>
      type == BOOLEAN_WRITABLE ||
      type == NUMERIC_WRITABLE ||
      type == STRING_WRITABLE;

  bool get isReadOnlyPoint =>
      type == BOOLEAN_POINT || type == NUMERIC_POINT || type == STRING_POINT;

  bool get isPoint => isWritablePoint || isReadOnlyPoint;

  bool get isBooleanType =>
      type == BOOLEAN_WRITABLE ||
      type == BOOLEAN_POINT ||
      type == AND_GATE ||
      type == OR_GATE ||
      type == XOR_GATE ||
      type == NOT_GATE ||
      type == IS_GREATER_THAN ||
      type == IS_LESS_THAN ||
      type == IS_EQUAL;

  bool get isNumericType =>
      type == NUMERIC_WRITABLE || type == NUMERIC_POINT || isMathOperation;

  bool get isStringType => type == STRING_WRITABLE || type == STRING_POINT;

  // Factory method to create from string
  static ComponentType fromString(String type) {
    return ComponentType(type);
  }
}
