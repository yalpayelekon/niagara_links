class PortType {
  static const String BOOLEAN = "BOOLEAN";
  static const String NUMERIC = "NUMERIC";
  static const String STRING = "STRING";
  static const String ANY = "ANY";

  final String type;

  const PortType(this.type);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PortType && other.type == type;

  @override
  int get hashCode => type.hashCode;

  // Factory method
  static PortType fromString(String type) {
    return PortType(type);
  }
}
