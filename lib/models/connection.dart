// connection.dart
class Connection {
  String fromComponentId;
  int fromPortIndex;
  String toComponentId;
  int toPortIndex;

  Connection({
    required this.fromComponentId,
    required this.fromPortIndex,
    required this.toComponentId,
    required this.toPortIndex,
  });

  bool isFromComponent(String componentId, int portIndex) {
    return fromComponentId == componentId && fromPortIndex == portIndex;
  }

  bool isToComponent(String componentId, int portIndex) {
    return toComponentId == componentId && toPortIndex == portIndex;
  }
}

class ConnectionEndpoint {
  String componentId;
  int portIndex;

  ConnectionEndpoint({
    required this.componentId,
    required this.portIndex,
  });
}
