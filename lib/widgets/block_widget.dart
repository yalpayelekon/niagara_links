import 'package:flutter/material.dart';
import '../models/block.dart';

class BlockWidget extends StatelessWidget {
  final Block block;
  final void Function(Offset position) onPositionChanged;
  final void Function(String blockId, Offset globalPosition)? onOutTap;
  final void Function(String blockId)? onInTap;

  const BlockWidget({
    super.key,
    required this.block,
    required this.onPositionChanged,
    this.onOutTap,
    this.onInTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: block.position.dx,
      top: block.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          onPositionChanged(block.position + details.delta);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 120,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  block.name,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            // Output (right)
            Positioned(
              right: -8,
              top: 32,
              child: GestureDetector(
                onTapDown: (details) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final global = box.localToGlobal(details.localPosition);
                  onOutTap?.call(block.id, global);
                },
                child: const PortCircle(),
              ),
            ),
            // Input (left)
            Positioned(
              left: -8,
              top: 32,
              child: GestureDetector(
                onTap: () => onInTap?.call(block.id),
                child: const PortCircle(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PortCircle extends StatelessWidget {
  const PortCircle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black),
      ),
    );
  }
}
