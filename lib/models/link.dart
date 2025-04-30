class Link {
  final String id;
  final String fromBlockId;
  final String fromPortId; // use 'out' for now
  final String toBlockId;
  final String toPortId; // use 'in' for now

  Link({
    required this.id,
    required this.fromBlockId,
    required this.fromPortId,
    required this.toBlockId,
    required this.toPortId,
  });
}
