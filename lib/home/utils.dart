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
    case ComponentType.max:
      return 'MAX';
    case ComponentType.min:
      return 'MIN';
    case ComponentType.power:
      return 'POW';
    case ComponentType.abs:
      return '|x|';
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
    case ComponentType.max:
    case ComponentType.min:
    case ComponentType.power:
    case ComponentType.abs:
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
    case ComponentType.max:
    case ComponentType.min:
    case ComponentType.power:
    case ComponentType.abs:
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

Widget buildTypeIndicator(PortType type) {
  IconData icon;
  Color color;

  switch (type) {
    case PortType.boolean:
      icon = Icons.toggle_on_outlined;
      color = Colors.indigo;
      break;
    case PortType.number:
      icon = Icons.numbers;
      color = Colors.green;
      break;
    case PortType.string:
      icon = Icons.text_fields;
      color = Colors.orange;
      break;
    case PortType.any:
      icon = Icons.all_inclusive;
      color = Colors.purple;
      break;
  }

  return Icon(
    icon,
    color: color,
    size: 12,
  );
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
    case ComponentType.max:
      return Icons.arrow_upward;
    case ComponentType.min:
      return Icons.arrow_downward;
    case ComponentType.power:
      return Icons.upload;
    case ComponentType.abs:
      return Icons.straighten;

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
    case ComponentType.max:
      return 'Maximum';
    case ComponentType.min:
      return 'Minimum';
    case ComponentType.power:
      return 'Power';
    case ComponentType.abs:
      return 'Absolute Value';

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

List<ComponentType> getCompatibleTypes(ComponentType currentType) {
  // Group types by their port structure for compatibility
  switch (currentType) {
    // 2-input, 1-output boolean components
    case ComponentType.andGate:
    case ComponentType.orGate:
    case ComponentType.xorGate:
      return [
        ComponentType.andGate,
        ComponentType.orGate,
        ComponentType.xorGate,
      ];

    // 1-input, 1-output boolean components
    case ComponentType.notGate:
      return [ComponentType.notGate];

    // 2-input, 1-output math components
    case ComponentType.add:
    case ComponentType.subtract:
    case ComponentType.multiply:
    case ComponentType.divide:
    case ComponentType.max:
    case ComponentType.min:
    case ComponentType.power:
      return [
        ComponentType.add,
        ComponentType.subtract,
        ComponentType.multiply,
        ComponentType.divide,
      ];

    // 2-input, 1-output comparison components
    case ComponentType.isGreaterThan:
    case ComponentType.isLessThan:
      return [
        ComponentType.isGreaterThan,
        ComponentType.isLessThan,
      ];
    case ComponentType.abs:
      return [ComponentType.abs];

    // Comparison with any type
    case ComponentType.isEqual:
      return [ComponentType.isEqual];

    // Single input components (by type)
    case ComponentType.booleanInput:
      return [ComponentType.booleanInput];
    case ComponentType.numberInput:
      return [ComponentType.numberInput];
    case ComponentType.stringInput:
      return [ComponentType.stringInput];
  }
}
