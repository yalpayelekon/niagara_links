import 'package:flutter/material.dart';
import 'package:niagara_links/models/component.dart';
import 'package:niagara_links/models/enums.dart';
import 'package:niagara_links/models/port.dart';

import 'utils.dart';

class PortDragInfo {
  final String componentId;
  final int portIndex;

  PortDragInfo(this.componentId, this.portIndex);
}

class ComponentWidget extends StatefulWidget {
  final Component component;
  final GlobalKey widgetKey;
  final Offset position;
  final bool isSelected;
  final Function(String, int, dynamic) onValueChanged;
  final Function(PortDragInfo) onPortDragStarted;
  final Function(PortDragInfo) onPortDragAccepted;

  const ComponentWidget({
    super.key,
    required this.component,
    required this.isSelected,
    required this.widgetKey,
    required this.position,
    required this.onValueChanged,
    required this.onPortDragStarted,
    required this.onPortDragAccepted,
  });

  @override
  State<ComponentWidget> createState() => _ComponentWidgetState();
}

class _ComponentWidgetState extends State<ComponentWidget> {
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
        color: getComponentColor(widget.component),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(2, 3),
          ),
        ],
        border: Border.all(
          color: widget.isSelected ? Colors.indigo : Colors.transparent,
          width: widget.isSelected ? 2.0 : 0.3,
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
                widget.component.ports.length,
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
              widget.component.id,
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
              getComponentSymbol(widget.component),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: getComponentTextColor(widget.component),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortRow(int index) {
    final port = widget.component.ports[index];
    final isInput = port.isInput;
    final label = port.name;

    return DragTarget<PortDragInfo>(
      onAccept: (draggedPortInfo) {
        widget.onPortDragAccepted(PortDragInfo(widget.component.id, index));
      },
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<PortDragInfo>(
          data: PortDragInfo(widget.component.id, index),
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
            widget.onPortDragStarted(PortDragInfo(widget.component.id, index));
          },
          child: Container(
            height: rowHeight,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            decoration: BoxDecoration(
              color: (candidateData.isNotEmpty)
                  ? Colors.lightBlue.withOpacity(0.3)
                  : null,
              border: (index < widget.component.ports.length - 1)
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
                    const SizedBox(width: 4),
                    buildTypeIndicator(port.type),
                  ],
                ),
                _buildValueDisplay(port),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildValueDisplay(Port port) {
    // If this is an input component or a port that can be edited directly
    bool canEdit = widget.component.type == ComponentType.booleanInput ||
        widget.component.type == ComponentType.numberInput ||
        widget.component.type == ComponentType.stringInput ||
        (port.isInput && widget.component.inputConnections[port.index] == null);

    switch (port.type) {
      case PortType.boolean:
        return GestureDetector(
          onTap: canEdit
              ? () {
                  widget.onValueChanged(
                      widget.component.id, port.index, !(port.value as bool));
                }
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: port.value as bool ? Colors.green : Colors.red[300],
                  border: Border.all(
                    color: Colors.black45,
                    width: 0.5,
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 150),
                  alignment: port.value as bool
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
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
              const SizedBox(width: 4),
              Text(
                port.value as bool ? 'T' : 'F',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color:
                      port.value as bool ? Colors.green[800] : Colors.red[800],
                ),
              ),
            ],
          ),
        );

      case PortType.number:
        return SizedBox(
          width: 60,
          height: 24,
          child: TextField(
            enabled: canEdit,
            controller:
                TextEditingController(text: (port.value as num).toString()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.5),
                ),
              ),
              filled: true,
              fillColor: canEdit ? Colors.white : Colors.grey[200],
            ),
            onChanged: (newValue) {
              num? parsed = num.tryParse(newValue);
              if (parsed != null) {
                widget.onValueChanged(widget.component.id, port.index, parsed);
              }
            },
          ),
        );

      case PortType.string:
        return SizedBox(
          width: 60,
          height: 24,
          child: TextField(
            enabled: canEdit,
            controller: TextEditingController(text: port.value as String),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.5),
                ),
              ),
              filled: true,
              fillColor: canEdit ? Colors.white : Colors.grey[200],
            ),
            onChanged: (newValue) {
              widget.onValueChanged(widget.component.id, port.index, newValue);
            },
          ),
        );

      case PortType.any:
        // For "any" type, display based on the actual value type
        if (port.value is bool) {
          return Text(
            port.value as bool ? 'true' : 'false',
            style: const TextStyle(fontSize: 10),
          );
        } else if (port.value is num) {
          return Text(
            (port.value as num).toString(),
            style: const TextStyle(fontSize: 10),
          );
        } else if (port.value is String) {
          return Text(
            '"${port.value as String}"',
            style: const TextStyle(fontSize: 10),
          );
        } else {
          return const Text(
            "null",
            style: TextStyle(fontSize: 10),
          );
        }
    }
  }
}
