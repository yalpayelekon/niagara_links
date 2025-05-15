// lib/home/component_panel.dart
import 'package:flutter/material.dart';
import '../models/component_type.dart';
import '../models/rectangle.dart';
import '../models/ramp_component.dart';
import 'utils.dart';

class ComponentPanel extends StatelessWidget {
  final BuildContext context;
  final Function(ComponentType, Offset) onComponentDragged;

  const ComponentPanel({
    super.key,
    required this.context,
    required this.onComponentDragged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.indigo[50],
            child: const Row(
              children: [
                Icon(Icons.category, size: 20),
                SizedBox(width: 8),
                Text(
                  'Components',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildCategorySection('Custom Components', [
                  RectangleComponent.RECTANGLE,
                  RampComponent.RAMP,
                ]),
                _buildCategorySection('Logic Gates', [
                  ComponentType.AND_GATE,
                  ComponentType.OR_GATE,
                  ComponentType.XOR_GATE,
                  ComponentType.NOT_GATE,
                ]),
                _buildCategorySection('Math Operations', [
                  ComponentType.ADD,
                  ComponentType.SUBTRACT,
                  ComponentType.MULTIPLY,
                  ComponentType.DIVIDE,
                  ComponentType.MAX,
                  ComponentType.MIN,
                  ComponentType.POWER,
                  ComponentType.ABS,
                ]),
                _buildCategorySection('Comparisons', [
                  ComponentType.IS_GREATER_THAN,
                  ComponentType.IS_LESS_THAN,
                  ComponentType.IS_EQUAL,
                ]),
                _buildCategorySection('Writable Points', [
                  ComponentType.BOOLEAN_WRITABLE,
                  ComponentType.NUMERIC_WRITABLE,
                  ComponentType.STRING_WRITABLE,
                ]),
                _buildCategorySection('Read-Only Points', [
                  ComponentType.BOOLEAN_POINT,
                  ComponentType.NUMERIC_POINT,
                  ComponentType.STRING_POINT,
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String title, List<String> typeStrings) {
    List<ComponentType> types =
        typeStrings.map((t) => ComponentType(t)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const Divider(height: 1),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: types.map((type) {
            return _buildDraggableComponentItem(type);
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDraggableComponentItem(ComponentType type) {
    return LongPressDraggable<ComponentType>(
      data: type,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.indigo),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                getIconForComponentType(type),
                color: Colors.indigo,
              ),
              const SizedBox(height: 4),
              Text(
                getNameForComponentType(type),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      onDragEnd: (details) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final Offset localPosition = renderBox.globalToLocal(details.offset);
        onComponentDragged(type, localPosition);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(getIconForComponentType(type), size: 20),
            const SizedBox(height: 4),
            Text(
              getNameForComponentType(type),
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
