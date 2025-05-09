// lib/logic/logic_item_widget.dart

import 'package:flutter/material.dart';
import 'logic_models.dart';

class PortDragInfo {
  final String itemId;
  final int portIndex;

  PortDragInfo(this.itemId, this.portIndex);
}

class LogicItemWidget extends StatefulWidget {
  final LogicItem item;
  final GlobalKey widgetKey;
  final Offset position;
  final Function(String, int, bool) onValueChanged;
  final Function(PortDragInfo) onPortDragStarted;
  final Function(PortDragInfo) onPortDragAccepted;

  const LogicItemWidget({
    super.key,
    required this.item,
    required this.widgetKey,
    required this.position,
    required this.onValueChanged,
    required this.onPortDragStarted,
    required this.onPortDragAccepted,
  });

  @override
  State<LogicItemWidget> createState() => _LogicItemWidgetState();
}

class _LogicItemWidgetState extends State<LogicItemWidget> {
  static const double itemExternalPadding = 8.0;
  static const double itemTitleSectionHeight = 28.0;
  static const double rowHeight = 36.0;
  static const double rowAreaWidth = 160.0;

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
          _buildTitleSection(),
          const SizedBox(height: 2),
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

  Widget _buildTitleSection() {
    return SizedBox(
      height: itemTitleSectionHeight,
      width: rowAreaWidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.item.id,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black45, width: 1),
            ),
            child: Text(
              _getOperationSymbol(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _getOperationTextColor(),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                  ],
                ),
                _buildStateIndicator(port),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStateIndicator(LogicPort port) {
    final isEnabled = widget.item.operationType == LogicOperationType.input ||
        (port.isInput && widget.item.inputConnections[port.index] == null);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: isEnabled
              ? () {
                  widget.onValueChanged(
                      widget.item.id, port.index, !port.value);
                }
              : null,
          child: Container(
            width: 36,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: port.value ? Colors.green : Colors.red[300],
              border: Border.all(
                color: Colors.black45,
                width: 0.5,
              ),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              alignment:
                  port.value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black45,
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          port.value ? 'T' : 'F',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: port.value ? Colors.green[800] : Colors.red[800],
          ),
        ),
      ],
    );
  }

  String _getOperationSymbol() {
    switch (widget.item.operationType) {
      case LogicOperationType.and:
        return 'AND';
      case LogicOperationType.or:
        return 'OR';
      case LogicOperationType.xor:
        return 'XOR';
      case LogicOperationType.not:
        return 'NOT';
      case LogicOperationType.input:
        return 'IN';
    }
  }

  Color _getOperationColor() {
    switch (widget.item.operationType) {
      case LogicOperationType.and:
        return Colors.lightBlue[100]!;
      case LogicOperationType.or:
        return Colors.tealAccent[100]!;
      case LogicOperationType.xor:
        return Colors.purpleAccent[100]!;
      case LogicOperationType.not:
        return Colors.orangeAccent[100]!;
      case LogicOperationType.input:
        return Colors.lightGreen[100]!;
    }
  }

  Color _getOperationTextColor() {
    switch (widget.item.operationType) {
      case LogicOperationType.and:
        return Colors.blue[800]!;
      case LogicOperationType.or:
        return Colors.teal[800]!;
      case LogicOperationType.xor:
        return Colors.purple[800]!;
      case LogicOperationType.not:
        return Colors.orange[800]!;
      case LogicOperationType.input:
        return Colors.green[800]!;
    }
  }
}
