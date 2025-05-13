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
    Component? fromComponent = findComponentById(fromComponentId);
    Component? toComponent = findComponentById(toComponentId);

    if (fromComponent == null || toComponent == null) return false;

    Slot? fromSlot = fromComponent.getSlotByIndex(fromPortIndex);
    Slot? toSlot = toComponent.getSlotByIndex(toPortIndex);

    if (fromSlot == null || toSlot == null) return false;

    if (fromSlot is Property && toSlot is Property) {
      if (fromSlot.isInput || !toSlot.isInput) return false;
      return fromSlot.canConnectTo(toSlot);
    } else if (fromSlot is Property && toSlot is ActionSlot) {
      if (fromSlot.isInput) return false;
      return toSlot.parameterType == null ||
          toSlot.parameterType!.type == PortType.ANY ||
          fromSlot.type.type == toSlot.parameterType!.type;
    } else if (fromSlot is ActionSlot && toSlot is ActionSlot) {
      return true;
    } else if (fromSlot is ActionSlot && toSlot is Topic) {
      return fromSlot.returnType == null ||
          fromSlot.returnType!.type == PortType.ANY ||
          toSlot.eventType.type == fromSlot.returnType!.type;
    } else if (fromSlot is Topic && toSlot is ActionSlot) {
      return toSlot.parameterType == null ||
          toSlot.parameterType!.type == PortType.ANY ||
          fromSlot.eventType.type == toSlot.parameterType!.type;
    } else if (fromSlot is Topic && toSlot is Topic) {
      return toSlot.eventType.type == PortType.ANY ||
          fromSlot.eventType.type == PortType.ANY ||
          toSlot.eventType.type == fromSlot.eventType.type;
    }

    return false;
  }

  void createConnection(String fromComponentId, int fromPortIndex,
      String toComponentId, int toPortIndex) {
    if (!canCreateConnection(
        fromComponentId, fromPortIndex, toComponentId, toPortIndex)) {
      return;
    }

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

        toComponent.addInputConnection(
            toPortIndex,
            ConnectionEndpoint(
              componentId: fromComponentId,
              portIndex: fromPortIndex,
            ));

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

    Component? toComponent = findComponentById(toComponentId);
    if (toComponent != null) {
      toComponent.removeInputConnection(toPortIndex);
    }

    recalculateAll();
  }

  void updatePortValue(String componentId, int portIndex, dynamic value) {
    Component? component = findComponentById(componentId);
    if (component == null) return;

    Slot? slot = component.getSlotByIndex(portIndex);
    if (slot == null) return;

    if (slot is Property) {
      slot.value = value;

      if (slot.isInput) {
        component.calculate();

        for (var property in component.properties.where((p) => !p.isInput)) {
          propagatePropertyValue(component, property.index);
        }

        for (var topic in component.topics) {
          propagateTopicEvent(component, topic.index);
        }
      } else {
        propagatePropertyValue(component, portIndex);
      }
    } else if (slot is ActionSlot) {
      slot.parameter = value;
      dynamic result = slot.execute(parameter: value);

      if (slot.returnType != null && result != null) {
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
              targetSlot.fire(result);
              propagateTopicEvent(targetComponent, connection.toPortIndex);
            }
          }
        }
      }
    }
  }

  void propagatePropertyValue(
      Component sourceComponent, int sourcePropertyIndex) {
    Property? sourceProperty =
        sourceComponent.getPropertyByIndex(sourcePropertyIndex);
    if (sourceProperty == null || sourceProperty.isInput) return;

    dynamic valueToPropagate = sourceProperty.value;

    List<Connection> outgoingConnections = connections
        .where((connection) =>
            connection.isFromComponent(sourceComponent.id, sourcePropertyIndex))
        .toList();

    for (var connection in outgoingConnections) {
      Component? targetComponent = findComponentById(connection.toComponentId);
      if (targetComponent == null) continue;

      Slot? targetSlot = targetComponent.getSlotByIndex(connection.toPortIndex);
      if (targetSlot == null) continue;

      if (targetSlot is Property) {
        targetSlot.value = valueToPropagate;
        targetComponent.calculate();

        for (var property
            in targetComponent.properties.where((p) => !p.isInput)) {
          propagatePropertyValue(targetComponent, property.index);
        }

        for (var topic in targetComponent.topics) {
          propagateTopicEvent(targetComponent, topic.index);
        }
      } else if (targetSlot is ActionSlot) {
        dynamic result = targetSlot.execute(parameter: valueToPropagate);

        if (result != null) {
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
              actionTargetSlot.fire(result);
              propagateTopicEvent(
                  actionTargetComponent, actionConnection.toPortIndex);
            }
          }
        }
      }
    }
  }

  void propagateTopicEvent(Component sourceComponent, int sourceTopicIndex) {
    Topic? sourceTopic = sourceComponent.getTopicByIndex(sourceTopicIndex);
    if (sourceTopic == null) return;

    dynamic eventToPropagate = sourceTopic.lastEvent;
    if (eventToPropagate == null) return;

    List<Connection> outgoingConnections = connections
        .where((connection) =>
            connection.isFromComponent(sourceComponent.id, sourceTopicIndex))
        .toList();

    for (var connection in outgoingConnections) {
      Component? targetComponent = findComponentById(connection.toComponentId);
      if (targetComponent == null) continue;

      Slot? targetSlot = targetComponent.getSlotByIndex(connection.toPortIndex);
      if (targetSlot == null) continue;

      if (targetSlot is ActionSlot) {
        dynamic result = targetSlot.execute(parameter: eventToPropagate);

        if (result != null) {
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
              actionTargetSlot.fire(result);
              propagateTopicEvent(
                  actionTargetComponent, actionConnection.toPortIndex);
            }
          }
        }
      } else if (targetSlot is Topic) {
        (targetSlot).fire(eventToPropagate);
        propagateTopicEvent(targetComponent, connection.toPortIndex);
      }
    }
  }

  void recalculateAll() {
    for (var component in components) {
      for (var entry in component.inputConnections.entries) {
        int slotIndex = entry.key;
        Slot? slot = component.getSlotByIndex(slotIndex);

        if (slot is Property && slot.isInput) {
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

    for (var component in components) {
      if (component.type.isPoint) {
        component.calculate();
      }
    }

    for (var component in components) {
      if (component.type.isPoint) {
        for (var property in component.properties.where((p) => !p.isInput)) {
          propagatePropertyValue(component, property.index);
        }
      }
    }

    for (var component in components) {
      if (!component.type.isPoint) {
        component.calculate();

        for (var property in component.properties.where((p) => !p.isInput)) {
          propagatePropertyValue(component, property.index);
        }

        for (var topic in component.topics) {
          propagateTopicEvent(component, topic.index);
        }
      }
    }
  }

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

    return PointComponent(
        id: id, type: ComponentType(ComponentType.BOOLEAN_WRITABLE));
  }
}
