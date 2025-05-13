// utils.dart
import 'package:flutter/material.dart';
import '../models/component.dart';
import '../models/component_type.dart';
import '../models/port_type.dart';
import '../models/ramp_component.dart';
import '../models/rectangle.dart';

const double rowHeight = 36.0;

String getComponentSymbol(Component component) {
  // Custom components
  if (component.type.type == RectangleComponent.RECTANGLE) {
    return 'R';
  }
  if (component.type.type == RampComponent.RAMP) {
    return '⏱️';
  }

  // Standard components
  switch (component.type.type) {
    case ComponentType.AND_GATE:
      return 'AND';
    case ComponentType.OR_GATE:
      return 'OR';
    case ComponentType.XOR_GATE:
      return 'XOR';
    case ComponentType.NOT_GATE:
      return 'NOT';
    case ComponentType.ADD:
      return '+';
    case ComponentType.SUBTRACT:
      return '-';
    case ComponentType.MULTIPLY:
      return '×';
    case ComponentType.DIVIDE:
      return '÷';
    case ComponentType.MAX:
      return 'MAX';
    case ComponentType.MIN:
      return 'MIN';
    case ComponentType.POWER:
      return 'POW';
    case ComponentType.ABS:
      return '|x|';
    case ComponentType.IS_GREATER_THAN:
      return '>';
    case ComponentType.IS_LESS_THAN:
      return '<';
    case ComponentType.IS_EQUAL:
      return '=';
    case ComponentType.BOOLEAN_WRITABLE:
      return 'BW';
    case ComponentType.NUMERIC_WRITABLE:
      return 'NW';
    case ComponentType.STRING_WRITABLE:
      return 'SW';
    case ComponentType.BOOLEAN_POINT:
      return 'BP';
    case ComponentType.NUMERIC_POINT:
      return 'NP';
    case ComponentType.STRING_POINT:
      return 'SP';
    default:
      return '?';
  }
}

Color getComponentColor(Component component) {
  // Custom components
  if (component.type.type == RectangleComponent.RECTANGLE) {
    return Colors.lime[100]!;
  }
  if (component.type.type == RampComponent.RAMP) {
    return Colors.amber[100]!;
  }

  // Standard components
  if (component.type.isLogicGate) {
    return Colors.lightBlue[100]!;
  } else if (component.type.isMathOperation) {
    return Colors.lightGreen[100]!;
  } else if (component.type.type == ComponentType.BOOLEAN_WRITABLE ||
      component.type.type == ComponentType.BOOLEAN_POINT) {
    return Colors.indigo[100]!;
  } else if (component.type.type == ComponentType.NUMERIC_WRITABLE ||
      component.type.type == ComponentType.NUMERIC_POINT) {
    return Colors.teal[100]!;
  } else if (component.type.type == ComponentType.STRING_WRITABLE ||
      component.type.type == ComponentType.STRING_POINT) {
    return Colors.orange[100]!;
  } else {
    return Colors.grey[100]!;
  }
}

// utils.dart (continued)
Color getComponentTextColor(Component component) {
  // Custom components
  if (component.type.type == RectangleComponent.RECTANGLE) {
    return Colors.green[800]!;
  }
  if (component.type.type == RampComponent.RAMP) {
    return Colors.amber[800]!;
  }

  // Standard components
  if (component.type.isLogicGate) {
    return Colors.blue[800]!;
  } else if (component.type.isMathOperation) {
    return Colors.green[800]!;
  } else if (component.type.type == ComponentType.BOOLEAN_WRITABLE ||
      component.type.type == ComponentType.BOOLEAN_POINT) {
    return Colors.indigo[800]!;
  } else if (component.type.type == ComponentType.NUMERIC_WRITABLE ||
      component.type.type == ComponentType.NUMERIC_POINT) {
    return Colors.teal[800]!;
  } else if (component.type.type == ComponentType.STRING_WRITABLE ||
      component.type.type == ComponentType.STRING_POINT) {
    return Colors.orange[800]!;
  } else {
    return Colors.grey[800]!;
  }
}

Widget buildTypeIndicator(PortType type) {
  IconData icon;
  Color color;

  switch (type.type) {
    case PortType.BOOLEAN:
      icon = Icons.toggle_on_outlined;
      color = Colors.indigo;
      break;
    case PortType.NUMERIC:
      icon = Icons.numbers;
      color = Colors.green;
      break;
    case PortType.STRING:
      icon = Icons.text_fields;
      color = Colors.orange;
      break;
    case PortType.ANY:
      icon = Icons.all_inclusive;
      color = Colors.purple;
      break;
    default:
      icon = Icons.help_outline;
      color = Colors.grey;
  }

  return Icon(
    icon,
    color: color,
    size: 12,
  );
}

IconData getIconForComponentType(ComponentType type) {
  // Custom components
  if (type.type == RectangleComponent.RECTANGLE) {
    return Icons.crop_square;
  }
  if (type.type == RampComponent.RAMP) {
    return Icons.show_chart;
  }

  // Standard components
  switch (type.type) {
    case ComponentType.AND_GATE:
      return Icons.call_merge;
    case ComponentType.OR_GATE:
      return Icons.call_split;
    case ComponentType.XOR_GATE:
      return Icons.shuffle;
    case ComponentType.NOT_GATE:
      return Icons.block;

    case ComponentType.ADD:
      return Icons.add;
    case ComponentType.SUBTRACT:
      return Icons.remove;
    case ComponentType.MULTIPLY:
      return Icons.close;
    case ComponentType.DIVIDE:
      return Icons.expand;
    case ComponentType.MAX:
      return Icons.arrow_upward;
    case ComponentType.MIN:
      return Icons.arrow_downward;
    case ComponentType.POWER:
      return Icons.upload;
    case ComponentType.ABS:
      return Icons.straighten;

    case ComponentType.IS_GREATER_THAN:
      return Icons.navigate_next;
    case ComponentType.IS_LESS_THAN:
      return Icons.navigate_before;
    case ComponentType.IS_EQUAL:
      return Icons.drag_handle;

    case ComponentType.BOOLEAN_WRITABLE:
      return Icons.toggle_on;
    case ComponentType.NUMERIC_WRITABLE:
      return Icons.numbers;
    case ComponentType.STRING_WRITABLE:
      return Icons.text_fields;

    case ComponentType.BOOLEAN_POINT:
      return Icons.toggle_off;
    case ComponentType.NUMERIC_POINT:
      return Icons.format_list_numbered;
    case ComponentType.STRING_POINT:
      return Icons.text_snippet;

    default:
      return Icons.help_outline;
  }
}

String getNameForComponentType(ComponentType type) {
  // Custom components
  if (type.type == RectangleComponent.RECTANGLE) {
    return 'Rectangle';
  }
  if (type.type == RampComponent.RAMP) {
    return 'Ramp';
  }

  // Standard components
  switch (type.type) {
    case ComponentType.AND_GATE:
      return 'AND Gate';
    case ComponentType.OR_GATE:
      return 'OR Gate';
    case ComponentType.XOR_GATE:
      return 'XOR Gate';
    case ComponentType.NOT_GATE:
      return 'NOT Gate';

    case ComponentType.ADD:
      return 'Add';
    case ComponentType.SUBTRACT:
      return 'Subtract';
    case ComponentType.MULTIPLY:
      return 'Multiply';
    case ComponentType.DIVIDE:
      return 'Divide';
    case ComponentType.MAX:
      return 'Maximum';
    case ComponentType.MIN:
      return 'Minimum';
    case ComponentType.POWER:
      return 'Power';
    case ComponentType.ABS:
      return 'Absolute Value';

    case ComponentType.IS_GREATER_THAN:
      return 'Greater Than';
    case ComponentType.IS_LESS_THAN:
      return 'Less Than';
    case ComponentType.IS_EQUAL:
      return 'Equals';

    case ComponentType.BOOLEAN_WRITABLE:
      return 'Boolean Writable';
    case ComponentType.NUMERIC_WRITABLE:
      return 'Numeric Writable';
    case ComponentType.STRING_WRITABLE:
      return 'String Writable';

    case ComponentType.BOOLEAN_POINT:
      return 'Boolean Point';
    case ComponentType.NUMERIC_POINT:
      return 'Numeric Point';
    case ComponentType.STRING_POINT:
      return 'String Point';

    default:
      return 'Unknown Component';
  }
}

List<ComponentType> getCompatibleTypes(ComponentType currentType) {
  // Custom types
  if (currentType.type == RectangleComponent.RECTANGLE) {
    return [ComponentType(RectangleComponent.RECTANGLE)];
  }
  if (currentType.type == RampComponent.RAMP) {
    return [ComponentType(RampComponent.RAMP)];
  }

  // Standard types
  List<String> compatibleTypeStrings = [];

  if (currentType.type == ComponentType.AND_GATE ||
      currentType.type == ComponentType.OR_GATE ||
      currentType.type == ComponentType.XOR_GATE) {
    compatibleTypeStrings = [
      ComponentType.AND_GATE,
      ComponentType.OR_GATE,
      ComponentType.XOR_GATE,
    ];
  } else if (currentType.type == ComponentType.NOT_GATE) {
    compatibleTypeStrings = [ComponentType.NOT_GATE];
  } else if (currentType.type == ComponentType.ADD ||
      currentType.type == ComponentType.SUBTRACT ||
      currentType.type == ComponentType.MULTIPLY ||
      currentType.type == ComponentType.DIVIDE ||
      currentType.type == ComponentType.MAX ||
      currentType.type == ComponentType.MIN ||
      currentType.type == ComponentType.POWER) {
    compatibleTypeStrings = [
      ComponentType.ADD,
      ComponentType.SUBTRACT,
      ComponentType.MULTIPLY,
      ComponentType.DIVIDE,
      ComponentType.MAX,
      ComponentType.MIN,
      ComponentType.POWER,
    ];
  } else if (currentType.type == ComponentType.IS_GREATER_THAN ||
      currentType.type == ComponentType.IS_LESS_THAN) {
    compatibleTypeStrings = [
      ComponentType.IS_GREATER_THAN,
      ComponentType.IS_LESS_THAN,
    ];
  } else if (currentType.type == ComponentType.ABS) {
    compatibleTypeStrings = [ComponentType.ABS];
  } else if (currentType.type == ComponentType.IS_EQUAL) {
    compatibleTypeStrings = [ComponentType.IS_EQUAL];
  } else if (currentType.type == ComponentType.BOOLEAN_WRITABLE ||
      currentType.type == ComponentType.BOOLEAN_POINT) {
    compatibleTypeStrings = [
      ComponentType.BOOLEAN_WRITABLE,
      ComponentType.BOOLEAN_POINT,
    ];
  } else if (currentType.type == ComponentType.NUMERIC_WRITABLE ||
      currentType.type == ComponentType.NUMERIC_POINT) {
    compatibleTypeStrings = [
      ComponentType.NUMERIC_WRITABLE,
      ComponentType.NUMERIC_POINT,
    ];
  } else if (currentType.type == ComponentType.STRING_WRITABLE ||
      currentType.type == ComponentType.STRING_POINT) {
    compatibleTypeStrings = [
      ComponentType.STRING_WRITABLE,
      ComponentType.STRING_POINT,
    ];
  }

  return compatibleTypeStrings
      .map((typeString) => ComponentType(typeString))
      .toList();
}
