import '../models/component.dart';
import '../models/connection.dart';
import '../models/component_type.dart';
import '../models/logic_components.dart';
import '../models/math_components.dart';
import '../models/point_components.dart';
import '../models/port_type.dart';
import '../models/port.dart';
import '../models/rectangle.dart';

class FlowManager {
  List<Component> components = [];
  List<Connection> connections = [];

  void addComponent(Component component) {
    components.add(component);
  }

  void removeComponent(String componentId) {
    components.removeWhere((component) => component.id == componentId);
    connections.removeWhere(
      (connection) =>
          connection.fromComponentId == componentId ||
          connection.toComponentId == componentId,
    );

    recalculateAll();
  }

  Component? findComponentById(String id) {
    try {
      return components.firstWhere((component) => component.id == id);
    } catch (e) {
      return null;
    }
  }

  bool canCreateConnection(String fromComponentId, int fromPortIndex,
      String toComponentId, int toPortIndex) {
    // Check if the components exist
    Component? fromComponent = findComponentById(fromComponentId);
    Component? toComponent = findComponentById(toComponentId);

    if (fromComponent == null || toComponent == null) return false;

    // Get the slots from each component
    Slot? fromSlot = fromComponent.getSlotByIndex(fromPortIndex);
    Slot? toSlot = toComponent.getSlotByIndex(toPortIndex);

    if (fromSlot == null || toSlot == null) return false;

    // Check slot types compatibility based on the slots table
    // Property to Property
    if (fromSlot is Property && toSlot is Property) {
      if (fromSlot.isInput || !toSlot.isInput) return false;
      return fromSlot.canConnectTo(toSlot);
    }

    // Property to Action
    else if (fromSlot is Property && toSlot is ActionSlot) {
      if (fromSlot.isInput) return false;
      return toSlot.parameterType == null ||
          toSlot.parameterType!.type == PortType.ANY ||
          fromSlot.type.type == toSlot.parameterType!.type;
    }

    // Action to Action
    else if (fromSlot is ActionSlot && toSlot is ActionSlot) {
      // Actions can be connected to other actions
      return true;
    }

    // Action to Topic
    else if (fromSlot is ActionSlot && toSlot is Topic) {
      return fromSlot.returnType == null ||
          fromSlot.returnType!.type == PortType.ANY ||
          toSlot.eventType.type == fromSlot.returnType!.type;
    }

    // Topic to Action
    else if (fromSlot is Topic && toSlot is ActionSlot) {
      return toSlot.parameterType == null ||
          toSlot.parameterType!.type == PortType.ANY ||
          fromSlot.eventType.type == toSlot.parameterType!.type;
    }

    // Topic to Topic
    else if (fromSlot is Topic && toSlot is Topic) {
      return toSlot.eventType.type == PortType.ANY ||
          fromSlot.eventType.type == PortType.ANY ||
          toSlot.eventType.type == fromSlot.eventType.type;
    }

    return false;
  }

  void createConnection(String fromComponentId, int fromPortIndex,
      String toComponentId, int toPortIndex) {
    // Check if connection can be created
    if (!canCreateConnection(
        fromComponentId, fromPortIndex, toComponentId, toPortIndex)) {
      return;
    }

    // Check if the connection already exists
    bool connectionExists = connections.any((connection) =>
        connection.fromComponentId == fromComponentId &&
        connection.fromPortIndex == fromPortIndex &&
        connection.toComponentId == toComponentId &&
        connection.toPortIndex == toPortIndex);

    if (!connectionExists) {
      Component? fromComponent = findComponentById(fromComponentId);
      Component? toComponent = findComponentById(toComponentId);

      if (fromComponent != null && toComponent != null) {
        connections.add(Connection(
          fromComponentId: fromComponentId,
          fromPortIndex: fromPortIndex,
          toComponentId: toComponentId,
          toPortIndex: toPortIndex,
        ));

        // Store the connection in the destination component
        toComponent.addInputConnection(
            toPortIndex,
            ConnectionEndpoint(
              componentId: fromComponentId,
              portIndex: fromPortIndex,
            ));

        // If from slot is a property and to slot is a property
        Slot? fromSlot = fromComponent.getSlotByIndex(fromPortIndex);
        Slot? toSlot = toComponent.getSlotByIndex(toPortIndex);

        if (fromSlot is Property && toSlot is Property) {
          propagatePropertyValue(fromComponent, fromPortIndex);
        }
      }
    }
  }

  void removeConnection(String fromComponentId, int fromPortIndex,
      String toComponentId, int toPortIndex) {
    connections.removeWhere((connection) =>
        connection.fromComponentId == fromComponentId &&
        connection.fromPortIndex == fromPortIndex &&
        connection.toComponentId == toComponentId &&
        connection.toPortIndex == toPortIndex);

    // Remove the connection from the destination component
    Component? toComponent = findComponentById(toComponentId);
    if (toComponent != null) {
      toComponent.removeInputConnection(toPortIndex);
    }

    recalculateAll();
  }

  // Update a property value and propagate it
  void updatePortValue(String componentId, int portIndex, dynamic value) {
    Component? component = findComponentById(componentId);
    if (component == null) return;

    Slot? slot = component.getSlotByIndex(portIndex);
    if (slot == null) return;

    if (slot is Property) {
      slot.value = value;

      // If it's an input property, recalculate the component
      if (slot.isInput) {
        component.calculate();

        // Propagate all output properties
        for (var property in component.properties.where((p) => !p.isInput)) {
          propagatePropertyValue(component, property.index);
        }

        // Fire topics if the component has any
        for (var topic in component.topics) {
          propagateTopicEvent(component, topic.index);
        }
      }
      // If it's an output property, propagate it
      else {
        propagatePropertyValue(component, portIndex);
      }
    }
    // Handle updating action parameters and executing
    else if (slot is ActionSlot) {
      slot.parameter = value;
      dynamic result = slot.execute(parameter: value);

      // If the action has a return type, propagate it
      if (slot.returnType != null && result != null) {
        // Propagate to connected actions/topics
        for (var connection in connections.where((connection) =>
            connection.isFromComponent(componentId, portIndex))) {
          Component? targetComponent =
              findComponentById(connection.toComponentId);
          if (targetComponent != null) {
            Slot? targetSlot =
                targetComponent.getSlotByIndex(connection.toPortIndex);

            if (targetSlot is ActionSlot) {
              updatePortValue(
                  connection.toComponentId, connection.toPortIndex, result);
            } else if (targetSlot is Topic) {
              (targetSlot as Topic).fire(result);
              propagateTopicEvent(targetComponent, connection.toPortIndex);
            }
          }
        }
      }
    }
  }

  // Propagate a property value to connected components
  void propagatePropertyValue(
      Component sourceComponent, int sourcePropertyIndex) {
    Property? sourceProperty =
        sourceComponent.getPropertyByIndex(sourcePropertyIndex);
    if (sourceProperty == null || sourceProperty.isInput) return;

    dynamic valueToPropagate = sourceProperty.value;

    // Find all connections from this output property
    List<Connection> outgoingConnections = connections
        .where((connection) =>
            connection.isFromComponent(sourceComponent.id, sourcePropertyIndex))
        .toList();

    for (var connection in outgoingConnections) {
      Component? targetComponent = findComponentById(connection.toComponentId);
      if (targetComponent == null) continue;

      Slot? targetSlot = targetComponent.getSlotByIndex(connection.toPortIndex);
      if (targetSlot == null) continue;

      // Property to Property
      if (targetSlot is Property) {
        targetSlot.value = valueToPropagate;
        targetComponent.calculate();

        // Propagate from the target component's output properties
        for (var property
            in targetComponent.properties.where((p) => !p.isInput)) {
          propagatePropertyValue(targetComponent, property.index);
        }

        // Fire topics if any
        for (var topic in targetComponent.topics) {
          propagateTopicEvent(targetComponent, topic.index);
        }
      }
      // Property to Action
      else if (targetSlot is ActionSlot) {
        dynamic result = targetSlot.execute(parameter: valueToPropagate);

        // Propagate the action result to any connected slots
        if (result != null) {
          // Find connections from this action
          for (var actionConnection in connections.where((conn) => conn
              .isFromComponent(targetComponent.id, connection.toPortIndex))) {
            Component? actionTargetComponent =
                findComponentById(actionConnection.toComponentId);
            if (actionTargetComponent == null) continue;

            Slot? actionTargetSlot = actionTargetComponent
                .getSlotByIndex(actionConnection.toPortIndex);

            if (actionTargetSlot is ActionSlot) {
              actionTargetSlot.execute(parameter: result);
            } else if (actionTargetSlot is Topic) {
              (actionTargetSlot as Topic).fire(result);
              propagateTopicEvent(
                  actionTargetComponent, actionConnection.toPortIndex);
            }
          }
        }
      }
    }
  }

  // Propagate a topic event to connected components
  void propagateTopicEvent(Component sourceComponent, int sourceTopicIndex) {
    Topic? sourceTopic = sourceComponent.getTopicByIndex(sourceTopicIndex);
    if (sourceTopic == null) return;

    dynamic eventToPropagate = sourceTopic.lastEvent;
    if (eventToPropagate == null) return;

    // Find all connections from this topic
    List<Connection> outgoingConnections = connections
        .where((connection) =>
            connection.isFromComponent(sourceComponent.id, sourceTopicIndex))
        .toList();

    for (var connection in outgoingConnections) {
      Component? targetComponent = findComponentById(connection.toComponentId);
      if (targetComponent == null) continue;

      Slot? targetSlot = targetComponent.getSlotByIndex(connection.toPortIndex);
      if (targetSlot == null) continue;

      // Topic to Action
      if (targetSlot is ActionSlot) {
        dynamic result = targetSlot.execute(parameter: eventToPropagate);

        // Propagate the action result to any connected slots
        if (result != null) {
          // Find connections from this action
          for (var actionConnection in connections.where((conn) => conn
              .isFromComponent(targetComponent.id, connection.toPortIndex))) {
            Component? actionTargetComponent =
                findComponentById(actionConnection.toComponentId);
            if (actionTargetComponent == null) continue;

            Slot? actionTargetSlot = actionTargetComponent
                .getSlotByIndex(actionConnection.toPortIndex);

            if (actionTargetSlot is ActionSlot) {
              actionTargetSlot.execute(parameter: result);
            } else if (actionTargetSlot is Topic) {
              (actionTargetSlot as Topic).fire(result);
              propagateTopicEvent(
                  actionTargetComponent, actionConnection.toPortIndex);
            }
          }
        }
      }
      // Topic to Topic
      else if (targetSlot is Topic) {
        (targetSlot as Topic).fire(eventToPropagate);
        propagateTopicEvent(targetComponent, connection.toPortIndex);
      }
    }
  }

// manager.dart (continued)
  void recalculateAll() {
    // Reset all input properties that have connections
    for (var component in components) {
      for (var entry in component.inputConnections.entries) {
        int slotIndex = entry.key;
        Slot? slot = component.getSlotByIndex(slotIndex);

        if (slot is Property && slot.isInput) {
          // Reset to default value based on type
          if (slot.type.type == PortType.BOOLEAN) {
            slot.value = false;
          } else if (slot.type.type == PortType.NUMERIC) {
            slot.value = 0.0;
          } else if (slot.type.type == PortType.STRING) {
            slot.value = '';
          } else if (slot.type.type == PortType.ANY) {
            slot.value = null;
          }
        }
      }
    }

    // Calculate point components first
    for (var component in components) {
      if (component.type.isPoint) {
        component.calculate();
      }
    }

    // Propagate all output properties from point components
    for (var component in components) {
      if (component.type.isPoint) {
        for (var property in component.properties.where((p) => !p.isInput)) {
          propagatePropertyValue(component, property.index);
        }
      }
    }

    // Calculate remaining components and propagate values
    for (var component in components) {
      if (!component.type.isPoint) {
        component.calculate();

        // Propagate output properties
        for (var property in component.properties.where((p) => !p.isInput)) {
          propagatePropertyValue(component, property.index);
        }

        // Fire topics if any
        for (var topic in component.topics) {
          propagateTopicEvent(component, topic.index);
        }
      }
    }
  }

  // Factory method to create a component based on type
  Component createComponentByType(String id, String typeStr) {
    final type = ComponentType(typeStr);

    if (typeStr == RectangleComponent.RECTANGLE) {
      return RectangleComponent(id: id);
    } else if (type.isLogicGate) {
      return LogicComponent(id: id, type: type);
    } else if (type.isMathOperation) {
      return MathComponent(id: id, type: type);
    } else if (type.isPoint) {
      return PointComponent(id: id, type: type);
    }

    // Default fallback
    return PointComponent(
        id: id, type: ComponentType(ComponentType.BOOLEAN_WRITABLE));
  }
}
