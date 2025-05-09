import 'package:flutter/material.dart';
import '../models/component.dart';
import '../models/enums.dart';

String getComponentSymbol(Component component) {
  switch (component.type) {
    case ComponentType.andGate:
      return 'AND';
    case ComponentType.orGate:
      return 'OR';
    case ComponentType.xorGate:
      return 'XOR';
    case ComponentType.notGate:
      return 'NOT';
    case ComponentType.add:
      return '+';
    case ComponentType.subtract:
      return '-';
    case ComponentType.multiply:
      return '×';
    case ComponentType.divide:
      return '÷';
    case ComponentType.isGreaterThan:
      return '>';
    case ComponentType.isLessThan:
      return '<';
    case ComponentType.isEqual:
      return '=';
    case ComponentType.booleanInput:
      return 'IN';
    case ComponentType.numberInput:
      return '#';
    case ComponentType.stringInput:
      return 'abc';
  }
}

Color getComponentColor(Component component) {
  switch (component.type) {
    // Logic gates - blue family
    case ComponentType.andGate:
    case ComponentType.orGate:
    case ComponentType.xorGate:
    case ComponentType.notGate:
      return Colors.lightBlue[100]!;

    // Math operations - green family
    case ComponentType.add:
    case ComponentType.subtract:
    case ComponentType.multiply:
    case ComponentType.divide:
      return Colors.lightGreen[100]!;

    // Comparison operations - purple family
    case ComponentType.isGreaterThan:
    case ComponentType.isLessThan:
    case ComponentType.isEqual:
      return Colors.purpleAccent[100]!;

    // Input components
    case ComponentType.booleanInput:
      return Colors.indigo[100]!;
    case ComponentType.numberInput:
      return Colors.teal[100]!;
    case ComponentType.stringInput:
      return Colors.orange[100]!;
  }
}

Color getComponentTextColor(Component component) {
  switch (component.type) {
    // Logic gates - blue family
    case ComponentType.andGate:
    case ComponentType.orGate:
    case ComponentType.xorGate:
    case ComponentType.notGate:
      return Colors.blue[800]!;

    // Math operations - green family
    case ComponentType.add:
    case ComponentType.subtract:
    case ComponentType.multiply:
    case ComponentType.divide:
      return Colors.green[800]!;

    // Comparison operations - purple family
    case ComponentType.isGreaterThan:
    case ComponentType.isLessThan:
    case ComponentType.isEqual:
      return Colors.purple[800]!;

    // Input components
    case ComponentType.booleanInput:
      return Colors.indigo[800]!;
    case ComponentType.numberInput:
      return Colors.teal[800]!;
    case ComponentType.stringInput:
      return Colors.orange[800]!;
  }
}

IconData getIconForComponentType(ComponentType type) {
  switch (type) {
    case ComponentType.andGate:
      return Icons.call_merge;
    case ComponentType.orGate:
      return Icons.call_split;
    case ComponentType.xorGate:
      return Icons.shuffle;
    case ComponentType.notGate:
      return Icons.block;

    case ComponentType.add:
      return Icons.add;
    case ComponentType.subtract:
      return Icons.remove;
    case ComponentType.multiply:
      return Icons.close;
    case ComponentType.divide:
      return Icons.expand;

    case ComponentType.isGreaterThan:
      return Icons.navigate_next;
    case ComponentType.isLessThan:
      return Icons.navigate_before;
    case ComponentType.isEqual:
      return Icons.drag_handle;

    case ComponentType.booleanInput:
      return Icons.toggle_on;
    case ComponentType.numberInput:
      return Icons.numbers;
    case ComponentType.stringInput:
      return Icons.text_fields;
  }
}

String getNameForComponentType(ComponentType type) {
  switch (type) {
    case ComponentType.andGate:
      return 'AND Gate';
    case ComponentType.orGate:
      return 'OR Gate';
    case ComponentType.xorGate:
      return 'XOR Gate';
    case ComponentType.notGate:
      return 'NOT Gate';

    case ComponentType.add:
      return 'Add';
    case ComponentType.subtract:
      return 'Subtract';
    case ComponentType.multiply:
      return 'Multiply';
    case ComponentType.divide:
      return 'Divide';

    case ComponentType.isGreaterThan:
      return 'Greater Than';
    case ComponentType.isLessThan:
      return 'Less Than';
    case ComponentType.isEqual:
      return 'Equals';

    case ComponentType.booleanInput:
      return 'Boolean';
    case ComponentType.numberInput:
      return 'Number';
    case ComponentType.stringInput:
      return 'String';
  }
}
