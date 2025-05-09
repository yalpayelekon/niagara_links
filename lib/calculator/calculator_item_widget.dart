// lib/calculator_item_widget.dart

import 'package:flutter/material.dart';
import 'calculator_models.dart';

class CalculatorItemWidget extends StatefulWidget {
  final CalculatorItem item;
  final GlobalKey widgetKey;
  final Offset position;
  final Function(String, int, double) onValueChanged;
  final Function(PortDragInfo) onPortDragStarted;
  final Function(PortDragInfo) onPortDragAccepted;

  const CalculatorItemWidget({
    Key? key,
    required this.item,
    required this.widgetKey,
    required this.position,
    required this.onValueChanged,
    required this.onPortDragStarted,
    required this.onPortDragAccepted,
  }) : super(key: key);

  @override
  State<CalculatorItemWidget> createState() => _CalculatorItemWidgetState();
}

class _CalculatorItemWidgetState extends State<CalculatorItemWidget> {
  static const double itemExternalPadding = 8.0;
  static const double itemTitleSectionHeight = 28.0;
  static const double rowHeight = 36.0; // Increased for input fields
  static const double rowAreaWidth = 150.0; // Increased for input fields

  // Controllers for input fields
  List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(CalculatorItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      _initControllers();
    } else {
      // Update controllers with new values from model
      for (var i = 0; i < widget.item.ports.length; i++) {
        if (i < _controllers.length) {
          _controllers[i].text = widget.item.ports[i].value.toString();
        }
      }
    }
  }

  void _initControllers() {
    // Dispose old controllers
    for (var controller in _controllers) {
      controller.dispose();
    }

    // Create new controllers
    _controllers = List.generate(
        widget.item.ports.length,
        (index) => TextEditingController(
            text: widget.item.ports[index].value.toString()));
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Get the operation symbol based on type
  String _getOperationSymbol() {
    switch (widget.item.operationType) {
      case OperationType.add:
        return '+';
      case OperationType.subtract:
        return '-';
      case OperationType.multiply:
        return '×';
      case OperationType.divide:
        return '÷';
      case OperationType.input:
        return 'IN';
    }
  }

  // Get color based on operation type
  Color _getOperationColor() {
    switch (widget.item.operationType) {
      case OperationType.add:
        return Colors.lightBlue[100]!;
      case OperationType.subtract:
        return Colors.tealAccent[100]!;
      case OperationType.multiply:
        return Colors.purpleAccent[100]!;
      case OperationType.divide:
        return Colors.orangeAccent[100]!;
      case OperationType.input:
        return Colors.lightGreen[100]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: widget.widgetKey,
      padding: const EdgeInsets.all(itemExternalPadding),
      decoration: BoxDecoration(
        color: _getOperationColor(),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(2, 3),
          ),
        ],
        border: Border.all(
          color: Colors.black.withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: itemTitleSectionHeight - 4,
            constraints: BoxConstraints(
              maxWidth: rowAreaWidth + 20,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.item.id,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.black45, width: 1),
                  ),
                  child: Text(
                    _getOperationSymbol(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: rowAreaWidth,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black.withOpacity(0.25)),
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                widget.item.ports.length,
                (index) => _buildPortRow(index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortRow(int index) {
    final port = widget.item.ports[index];
    final isInput = port.isInput;
    final label = isInput
        ? 'Input ${String.fromCharCode(65 + port.index)}' // A, B, etc.
        : 'Output';

    return DragTarget<PortDragInfo>(
      onAccept: (draggedPortInfo) {
        widget.onPortDragAccepted(PortDragInfo(widget.item.id, index));
      },
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<PortDragInfo>(
          data: PortDragInfo(widget.item.id, index),
          feedback: Material(
            elevation: 4.0,
            color: Colors.transparent,
            child: Container(
              width: rowAreaWidth,
              height: rowHeight,
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.2),
                border: Border.all(
                  color: Colors.indigo,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(3.0),
              ),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          onDragStarted: () {
            widget.onPortDragStarted(PortDragInfo(widget.item.id, index));
          },
          child: Container(
            height: rowHeight,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            decoration: BoxDecoration(
              color: (candidateData.isNotEmpty)
                  ? Colors.lightBlue.withOpacity(0.3)
                  : null,
              border: (index < widget.item.ports.length - 1)
                  ? Border(
                      bottom: BorderSide(
                        color: Colors.black.withOpacity(0.15),
                        width: 1.0,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isInput ? Icons.arrow_back : Icons.arrow_forward,
                  size: 14,
                  color: Colors.indigo.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 70,
                  height: 24,
                  child: TextField(
                    controller: _controllers[index],
                    enabled: widget.item.operationType == OperationType.input ||
                        isInput,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.5),
                        ),
                      ),
                      filled: true,
                      fillColor: isInput ? Colors.white : Colors.grey[200],
                    ),
                    onChanged: (newValue) {
                      double? parsed = double.tryParse(newValue);
                      if (parsed != null) {
                        widget.onValueChanged(widget.item.id, index, parsed);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PortDragInfo {
  final String itemId;
  final int portIndex;

  PortDragInfo(this.itemId, this.portIndex);
}
