import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class CopyIntent extends Intent {
  const CopyIntent();
}

class PasteIntent extends Intent {
  const PasteIntent();
}

class DeleteIntent extends Intent {
  const DeleteIntent();
}

class MoveUpIntent extends Intent {
  const MoveUpIntent();
}

class MoveDownIntent extends Intent {
  const MoveDownIntent();
}

class MoveLeftIntent extends Intent {
  const MoveLeftIntent();
}

class MoveRightIntent extends Intent {
  const MoveRightIntent();
}

class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

Map<LogicalKeySet, Intent> getShortcuts() {
  // TODO: include MAC shortcuts
  return <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
        const UndoIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
        const RedoIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC):
        const CopyIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV):
        const PasteIntent(),
    LogicalKeySet(LogicalKeyboardKey.delete): const DeleteIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): const MoveDownIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): const MoveLeftIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): const MoveRightIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): const MoveUpIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA):
        const SelectAllIntent(),
  };
}
