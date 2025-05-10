import 'package:flutter/material.dart';
import 'package:niagara_links/models/component.dart';
import 'package:niagara_links/models/enums.dart';
import 'manager.dart';
import 'utils.dart';

class ComponentDialogs {
  static void showAddComponentDialog(BuildContext context,
      Function(ComponentType type, {Offset? clickPosition}) onComponentSelected,
      {Offset? position}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Component'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: ListView(
              children: [
                _buildComponentCategorySection(
                    context,
                    'Logic Gates',
                    [
                      ComponentType.andGate,
                      ComponentType.orGate,
                      ComponentType.xorGate,
                      ComponentType.notGate,
                    ],
                    onComponentSelected,
                    position),
                _buildComponentCategorySection(
                    context,
                    'Math Operations',
                    [
                      ComponentType.add,
                      ComponentType.subtract,
                      ComponentType.multiply,
                      ComponentType.divide,
                      ComponentType.max,
                      ComponentType.min,
                      ComponentType.power,
                      ComponentType.abs,
                    ],
                    onComponentSelected,
                    position),
                _buildComponentCategorySection(
                    context,
                    'Comparisons',
                    [
                      ComponentType.isGreaterThan,
                      ComponentType.isLessThan,
                      ComponentType.isEqual,
                    ],
                    onComponentSelected,
                    position),
                _buildComponentCategorySection(
                    context,
                    'Input Components',
                    [
                      ComponentType.booleanInput,
                      ComponentType.numberInput,
                      ComponentType.stringInput,
                    ],
                    onComponentSelected,
                    position),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildComponentCategorySection(
    BuildContext context,
    String title,
    List<ComponentType> types,
    Function(ComponentType type, {Offset? clickPosition}) onComponentSelected,
    Offset? position,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const Divider(),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: types.map((type) {
            return InkWell(
              onTap: () {
                onComponentSelected(type, clickPosition: position);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Column(
                  children: [
                    Icon(getIconForComponentType(type)),
                    const SizedBox(height: 4.0),
                    Text(getNameForComponentType(type)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static Future<EditComponentResult?> showEditComponentDialog(
    BuildContext context,
    Component component,
    FlowManager flowManager,
  ) async {
    TextEditingController nameController =
        TextEditingController(text: component.id);
    ComponentType selectedType = component.type;

    return await showDialog<EditComponentResult>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Component'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'Component Name'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ComponentType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Component Type',
                  ),
                  items: getCompatibleTypes(component.type).map((type) {
                    return DropdownMenuItem<ComponentType>(
                      value: type,
                      child: Text(getNameForComponentType(type)),
                    );
                  }).toList(),
                  onChanged: (ComponentType? value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final oldId = component.id;
                  String newId = nameController.text.trim();

                  // Validate and adjust name if needed
                  if (newId.isEmpty) {
                    newId = oldId;
                  } else if (flowManager.components
                      .any((comp) => comp.id == newId && comp.id != oldId)) {
                    int counter = 1;
                    String baseName = newId;
                    while (flowManager.components
                        .any((comp) => comp.id == newId && comp.id != oldId)) {
                      counter++;
                      newId = '$baseName $counter';
                    }
                  }

                  Navigator.pop(
                      context,
                      EditComponentResult(
                        oldId: oldId,
                        newId: newId,
                        oldType: component.type,
                        newType: selectedType,
                      ));
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class EditComponentResult {
  final String oldId;
  final String newId;
  final ComponentType oldType;
  final ComponentType newType;

  EditComponentResult({
    required this.oldId,
    required this.newId,
    required this.oldType,
    required this.newType,
  });

  bool get hasChanges => oldId != newId || oldType != newType;
}
