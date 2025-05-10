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
  max,
  min,
  power,
  abs,

  isGreaterThan,
  isLessThan,
  isEqual,

  booleanInput,
  numberInput,
  stringInput,
}
