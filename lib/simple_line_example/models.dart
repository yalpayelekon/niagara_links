class ItemConnection {
  final String fromItemId;
  final int fromItemRowIndex;
  final String toItemId;
  final int toItemRowIndex;

  ItemConnection({
    required this.fromItemId,
    required this.fromItemRowIndex,
    required this.toItemId,
    required this.toItemRowIndex,
  });
}

class PortDragInfo {
  final String itemId;
  final int rowIndex;

  PortDragInfo(this.itemId, this.rowIndex);
}
