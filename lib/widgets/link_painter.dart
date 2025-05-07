import 'package:flutter/material.dart';
import '../models/link.dart';
import '../models/block.dart';

class LinkPainter extends CustomPainter {
  final List<Block> blocks;
  final List<Link> links;
  final Offset? tempFrom;
  final Offset? tempTo;
  LinkPainter(
    this.tempFrom,
    this.tempTo, {
    required this.blocks,
    required this.links,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw permanent links
    for (final link in links) {
      final from = blocks.firstWhere((b) => b.id == link.fromBlockId);
      final to = blocks.firstWhere((b) => b.id == link.toBlockId);

      final fromOffset = from.position + const Offset(120, 40); // right middle
      final toOffset = to.position + const Offset(0, 40); // left middle

      final path = Path();
      path.moveTo(fromOffset.dx, fromOffset.dy);
      path.cubicTo(
        fromOffset.dx + 40,
        fromOffset.dy,
        toOffset.dx - 40,
        toOffset.dy,
        toOffset.dx,
        toOffset.dy,
      );
      canvas.drawPath(path, paint);
    }

    if (tempFrom != null && currentPointerPosition != null) {
      final tempPath = Path()
        ..moveTo(tempFrom!.dx, tempFrom!.dy)
        ..cubicTo(
          tempFrom!.dx + 40,
          tempFrom!.dy,
          currentPointerPosition!.dx - 40,
          currentPointerPosition!.dy,
          currentPointerPosition!.dx,
          currentPointerPosition!.dy,
        );
      canvas.drawPath(tempPath, paint..color = Colors.grey);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
