enum PortType {
  boolean,
  number,
  string,
  any, // can connect to any type
}

enum ComponentType {
  andGate,
  orGate,
  notGate,
  xorGate,

  add,
  subtract,
  multiply,
  divide,

  isGreaterThan,
  isLessThan,
  isEqual,

  booleanInput,
  numberInput,
  stringInput,
}
