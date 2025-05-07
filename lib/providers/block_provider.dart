import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/block.dart';

final blockListProvider = StateNotifierProvider<BlockListNotifier, List<Block>>(
  (ref) => BlockListNotifier(),
);

class BlockListNotifier extends StateNotifier<List<Block>> {
  BlockListNotifier() : super([]);

  void addBlock(Block block) {
    state = [...state, block];
  }

  void updateBlockPosition(String id, Offset newPosition) {
    state = [
      for (final block in state)
        if (block.id == id) block.copyWith(position: newPosition) else block
    ];
  }
}
