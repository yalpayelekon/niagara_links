import 'package:flutter/material.dart';
import '../models/block.dart';

class BlockWidget extends StatelessWidget {
  final Block block;
  final void Function(String blockId, Offset position)? onStartDrag;
  final void Function(Offset position)? onUpdateDrag;
  final void Function()? onEndDrag;
  final void Function(String? blockId)? onHoverIn;
  final void Function(String blockId)? onAcceptLink;
  final void Function(Offset position) onPositionChanged;
  final String? hoveringTargetBlockId; // Add this
  final Offset? currentPointerPosition; // Add this

  const BlockWidget({
    super.key,
    required this.block,
    required this.onPositionChanged,
    this.onStartDrag,
    this.onUpdateDrag,
    this.onEndDrag,
    this.onHoverIn,
    this.onAcceptLink,
    this.hoveringTargetBlockId, // Add this
    this.currentPointerPosition, // Add this
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
            // Output port
            // In BlockWidget's build method, update the output port GestureDetector:
            Positioned(
              right: -8,
              top: 32,
              child: GestureDetector(
                onPanStart: (details) {
                  final box = context.findRenderObject() as RenderBox;
                  final global = box.localToGlobal(details.localPosition);
                  onStartDrag?.call(block.id, global);
                },
                onPanUpdate: (details) {
                  final box = context.findRenderObject() as RenderBox;
                  final global = box.localToGlobal(details.localPosition);
                  onUpdateDrag?.call(global);
                },
                onPanEnd: (_) {
                  if (hoveringTargetBlockId != null) {
                    onAcceptLink?.call(hoveringTargetBlockId!);
                  }
                  onEndDrag?.call();
                },
                child: const PortCircle(),
              ),
            ),
            // Input port
            Positioned(
              left: -8,
              top: 32,
              child: MouseRegion(
                onEnter: (_) => onHoverIn?.call(block.id),
                onExit: (_) => onHoverIn?.call(null),
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
