import 'port.dart';
import 'connection.dart';
import 'component_type.dart';

abstract class Component {
  String id;
  final ComponentType type;
  final List<Property> properties;
  final List<ActionSlot> actions;
  final List<Topic> topics;
  Map<int, ConnectionEndpoint> inputConnections = {};

  Component({
    required this.id,
    required this.type,
    List<Property>? properties,
    List<ActionSlot>? actions,
    List<Topic>? topics,
  })  : properties = properties ?? [],
        actions = actions ?? [],
        topics = topics ?? [];

  List<Slot> get allSlots {
    List<Slot> slots = [];
    slots.addAll(properties);
    slots.addAll(actions);
    slots.addAll(topics);
    return slots;
  }

  // Find a property by index
  Property? getPropertyByIndex(int index) {
    try {
      return properties.firstWhere((prop) => prop.index == index);
    } catch (e) {
      return null;
    }
  }

  ActionSlot? getActionByIndex(int index) {
    try {
      return actions.firstWhere((action) => action.index == index);
    } catch (e) {
      return null;
    }
  }

  Topic? getTopicByIndex(int index) {
    try {
      return topics.firstWhere((topic) => topic.index == index);
    } catch (e) {
      return null;
    }
  }

  Slot? getSlotByIndex(int index) {
    Property? property = getPropertyByIndex(index);
    if (property != null) return property;

    ActionSlot? action = getActionByIndex(index);
    if (action != null) return action;

    return getTopicByIndex(index);
  }

  void addInputConnection(int slotIndex, ConnectionEndpoint endpoint) {
    inputConnections[slotIndex] = endpoint;
  }

  void removeInputConnection(int slotIndex) {
    inputConnections.remove(slotIndex);
  }

  void calculate();
}
