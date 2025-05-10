import '../models/component.dart';
import '../models/connection.dart';
import '../models/enums.dart';
import '../models/port.dart';

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

    // Check port indices
    if (fromPortIndex >= fromComponent.ports.length ||
        toPortIndex >= toComponent.ports.length) return false;

    Port fromPort = fromComponent.ports[fromPortIndex];
    Port toPort = toComponent.ports[toPortIndex];

    // Check if one is input and one is output
    if (fromPort.isInput == toPort.isInput) return false;

    // Ensure we're connecting from output to input
    if (fromPort.isInput) return false;

    // Check type compatibility
    return fromPort.canConnectTo(toPort);
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
        toComponent.inputConnections[toPortIndex] = ConnectionEndpoint(
          componentId: fromComponentId,
          portIndex: fromPortIndex,
        );

        propagateValue(fromComponent, fromPortIndex);
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
      toComponent.inputConnections.remove(toPortIndex);
    }

    recalculateAll();
  }

  void updatePortValue(String componentId, int portIndex, dynamic value) {
    Component? component = findComponentById(componentId);
    if (component != null && portIndex < component.ports.length) {
      component.ports[portIndex].value = value;

      if (!component.ports[portIndex].isInput) {
        propagateValue(component, portIndex);
      } else {
        component.calculate();
        for (var port in component.ports) {
          if (!port.isInput) {
            propagateValue(component, port.index);
          }
        }
      }
    }
  }

  void propagateValue(Component sourceComponent, int sourcePortIndex) {
    // Only output ports can propagate values
    if (sourcePortIndex >= sourceComponent.ports.length ||
        sourceComponent.ports[sourcePortIndex].isInput) {
      return;
    }

    dynamic valueToPropagate = sourceComponent.ports[sourcePortIndex].value;

    // Find all connections from this output port
    List<Connection> outgoingConnections = connections
        .where((connection) =>
            connection.isFromComponent(sourceComponent.id, sourcePortIndex))
        .toList();

    for (var connection in outgoingConnections) {
      Component? targetComponent = findComponentById(connection.toComponentId);
      if (targetComponent != null &&
          connection.toPortIndex < targetComponent.ports.length) {
        targetComponent.ports[connection.toPortIndex].value = valueToPropagate;

        targetComponent.calculate();

        // Recursively propagate from the target component's output ports
        for (var port in targetComponent.ports) {
          if (!port.isInput) {
            propagateValue(targetComponent, port.index);
          }
        }
      }
    }
  }

  void recalculateAll() {
    // Reset all input ports that have connections
    for (var component in components) {
      for (var entry in component.inputConnections.entries) {
        int portIndex = entry.key;
        if (portIndex < component.ports.length &&
            component.ports[portIndex].isInput) {
          // Reset to default value based on type
          Port port = component.ports[portIndex];
          switch (port.type) {
            case PortType.boolean:
              port.value = false;
              break;
            case PortType.number:
              port.value = 0.0;
              break;
            case PortType.string:
              port.value = '';
              break;
            case PortType.any:
              port.value = null;
              break;
          }
        }
      }
    }

    // Calculate components without input connections first
    for (var component in components) {
      bool isInputComponent = [
        ComponentType.booleanInput,
        ComponentType.numberInput,
        ComponentType.stringInput,
      ].contains(component.type);

      if (isInputComponent || component.inputConnections.isEmpty) {
        component.calculate();
      }
    }

    // Propagate values through the network
    for (var component in components) {
      for (var port in component.ports) {
        if (!port.isInput) {
          propagateValue(component, port.index);
        }
      }
    }
  }
}
