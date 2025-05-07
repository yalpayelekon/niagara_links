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
  final void Function(String blockId, Offset globalPosition)? onOutTap;
  final void Function(String blockId)? onInTap;

  const BlockWidget({
    super.key,
    required this.block,
    required this.onPositionChanged,
    this.onOutTap,
    this.onInTap,
    this.onStartDrag,
    this.onUpdateDrag,
    this.onEndDrag,
    this.onHoverIn,
    this.onAcceptLink,
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
                onPanEnd: (_) => onEndDrag?.call(),
                child: const PortCircle(),
              ),
            ),
            Positioned(
              left: -8,
              top: 32,
              child: DragTarget<String>(
                builder: (context, candidateData, rejectedData) {
                  return MouseRegion(
                    onEnter: (_) => onHoverIn?.call(block.id),
                    onExit: (_) => onHoverIn?.call(null),
                    child: const PortCircle(),
                  );
                },
                onWillAccept: (_) => true,
                onAccept: (_) => onAcceptLink?.call(block.id),
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
