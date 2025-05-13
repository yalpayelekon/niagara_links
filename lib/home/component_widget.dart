import 'package:flutter/material.dart';
import '../models/component.dart';
import '../models/port.dart';
import '../models/port_type.dart';
import 'utils.dart';

class SlotDragInfo {
  final String componentId;
  final int slotIndex;

  SlotDragInfo(this.componentId, this.slotIndex);
}

class ComponentWidget extends StatefulWidget {
  final Component component;
  final GlobalKey widgetKey;
  final Offset position;
  final bool isSelected;
  final double width;
  final double height;
  final Function(String, int, dynamic) onValueChanged;
  final Function(SlotDragInfo) onSlotDragStarted;
  final Function(SlotDragInfo) onSlotDragAccepted;
  final Function(String, double) onWidthChanged;

  const ComponentWidget({
    super.key,
    required this.component,
    required this.isSelected,
    required this.widgetKey,
    required this.position,
    required this.width,
    required this.height,
    required this.onValueChanged,
    required this.onSlotDragStarted,
    required this.onSlotDragAccepted,
    required this.onWidthChanged,
  });

  @override
  State<ComponentWidget> createState() => _ComponentWidgetState();
}

class _ComponentWidgetState extends State<ComponentWidget> {
  static const double itemExternalPadding = 8.0;
  static const double itemTitleSectionHeight = 28.0;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: widget.width,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black.withOpacity(0.25)),
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.component.properties.isNotEmpty)
                      ..._buildSectionHeader("Properties"),
                    ...widget.component.properties
                        .map((property) => _buildPropertyRow(property)),
                    if (widget.component.actions.isNotEmpty)
                      ..._buildSectionHeader("Actions"),
                    ...widget.component.actions
                        .map((action) => _buildActionRow(action)),
                    if (widget.component.topics.isNotEmpty)
                      ..._buildSectionHeader("Topics"),
                    ...widget.component.topics
                        .map((topic) => _buildTopicRow(topic)),
                  ],
                ),
              ),
              _buildResizeHandle(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return SizedBox(
      height: itemTitleSectionHeight,
      width: widget.width,
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

  Widget _buildResizeHandle() {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        double newWidth = widget.width + details.delta.dx;
        if (newWidth >= 100.0) {
          widget.onWidthChanged(widget.component.id, newWidth);
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: Container(
          width: 8.0,
          height: widget.height,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 3.0,
              height: 20.0,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.7),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSectionHeader(String title) {
    return [
      Container(
        color: Colors.grey.shade200,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: Colors.grey.shade800,
          ),
        ),
      ),
    ];
  }

  Widget _buildPropertyRow(Property property) {
    final isInput = property.isInput;
    final label = property.name;

    return DragTarget<SlotDragInfo>(
      onAcceptWithDetails: (DragTargetDetails<SlotDragInfo> details) {
        widget.onSlotDragAccepted(
            SlotDragInfo(widget.component.id, property.index));
      },
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<SlotDragInfo>(
          data: SlotDragInfo(widget.component.id, property.index),
          feedback: Material(
            elevation: 4.0,
            color: Colors.transparent,
            child: Container(
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
            widget.onSlotDragStarted(
                SlotDragInfo(widget.component.id, property.index));
          },
          child: Container(
            height: rowHeight,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            decoration: BoxDecoration(
              color: (candidateData.isNotEmpty)
                  ? Colors.lightBlue.withOpacity(0.3)
                  : null,
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withOpacity(0.15),
                  width: 1.0,
                ),
              ),
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
                    buildTypeIndicator(property.type),
                  ],
                ),
                _buildPropertyValueDisplay(property),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionRow(ActionSlot action) {
    final label = action.name;

    return DragTarget<SlotDragInfo>(
      onAcceptWithDetails: (DragTargetDetails<SlotDragInfo> details) {
        widget.onSlotDragAccepted(
            SlotDragInfo(widget.component.id, action.index));
      },
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<SlotDragInfo>(
          data: SlotDragInfo(widget.component.id, action.index),
          feedback: Material(
            elevation: 4.0,
            color: Colors.transparent,
            child: Container(
              height: rowHeight,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                border: Border.all(
                  color: Colors.amber.shade800,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(3.0),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          onDragStarted: () {
            widget.onSlotDragStarted(
                SlotDragInfo(widget.component.id, action.index));
          },
          child: Container(
            height: rowHeight,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            decoration: BoxDecoration(
              color: (candidateData.isNotEmpty)
                  ? Colors.amber.withOpacity(0.2)
                  : null,
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withOpacity(0.15),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flash_on,
                      size: 14,
                      color: Colors.amber.shade800,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                    if (action.parameterType != null) ...[
                      const SizedBox(width: 4),
                      buildTypeIndicator(action.parameterType!),
                    ],
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.play_arrow,
                      size: 16, color: Colors.amber.shade800),
                  constraints: BoxConstraints.tightFor(width: 24, height: 24),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    widget.onValueChanged(
                        widget.component.id, action.index, null);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopicRow(Topic topic) {
    final label = topic.name;

    return DragTarget<SlotDragInfo>(
      onAcceptWithDetails: (DragTargetDetails<SlotDragInfo> details) {
        widget
            .onSlotDragAccepted(SlotDragInfo(widget.component.id, topic.index));
      },
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<SlotDragInfo>(
          data: SlotDragInfo(widget.component.id, topic.index),
          feedback: Material(
            elevation: 4.0,
            color: Colors.transparent,
            child: Container(
              height: rowHeight,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                border: Border.all(
                  color: Colors.green.shade800,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(3.0),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          onDragStarted: () {
            widget.onSlotDragStarted(
                SlotDragInfo(widget.component.id, topic.index));
          },
          child: Container(
            height: rowHeight,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            decoration: BoxDecoration(
              color: (candidateData.isNotEmpty)
                  ? Colors.green.withOpacity(0.2)
                  : null,
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withOpacity(0.15),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up,
                      size: 14,
                      color: Colors.green.shade800,
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
                    buildTypeIndicator(topic.eventType),
                  ],
                ),
                if (topic.lastEvent != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      _formatEventValue(topic.lastEvent),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatEventValue(dynamic value) {
    if (value == null) return "null";
    if (value is bool) return value ? "T" : "F";
    if (value is num) return value.toStringAsFixed(1);
    if (value is String) {
      return '"${value.length > 5 ? '${value.substring(0, 5)}...' : value}"';
    }
    return value.toString();
  }

  Widget _buildPropertyValueDisplay(Property property) {
    Component component = widget.component;
    bool canEdit =
        !property.isInput && component.inputConnections[property.index] == null;

    switch (property.type.type) {
      case PortType.BOOLEAN:
        return GestureDetector(
          onTap: canEdit
              ? () {
                  widget.onValueChanged(widget.component.id, property.index,
                      !(property.value as bool));
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
                  color:
                      property.value as bool ? Colors.green : Colors.red[300],
                  border: Border.all(
                    color: Colors.black45,
                    width: 0.5,
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 150),
                  alignment: property.value as bool
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
                property.value as bool ? 'T' : 'F',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: property.value as bool
                      ? Colors.green[800]
                      : Colors.red[800],
                ),
              ),
            ],
          ),
        );

      case PortType.NUMERIC:
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Text(
            (property.value as num).toStringAsFixed(2),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
        );

      case PortType.STRING:
        return Container(
          width: 60,
          padding: const EdgeInsets.only(right: 8.0),
          child: Tooltip(
            message: property.value as String,
            child: Text(
              '"${(property.value as String).length > 6 ? '${(property.value as String).substring(0, 6)}...' : property.value as String}"',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        );

      case PortType.ANY:
        if (property.value is bool) {
          return Text(
            property.value as bool ? 'true' : 'false',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800]),
          );
        } else if (property.value is num) {
          return Text(
            (property.value as num).toStringAsFixed(2),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800]),
          );
        } else if (property.value is String) {
          return Text(
            '"${(property.value as String).length > 8 ? '${(property.value as String).substring(0, 8)}...' : property.value as String}"',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800]),
          );
        } else {
          return Text(
            "null",
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800]),
          );
        }
    }
    return const SizedBox();
  }
}
