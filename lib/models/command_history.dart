import 'command.dart';

class CommandHistory {
  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];
  final int _maxHistorySize;

  CommandHistory({int maxHistorySize = 100}) : _maxHistorySize = maxHistorySize;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void execute(Command command) {
    command.execute();
    _undoStack.add(command);

    _redoStack.clear();

    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeAt(0);
    }
  }

  void undo() {
    if (canUndo) {
      final command = _undoStack.removeLast();
      command.undo();
      _redoStack.add(command);
    }
  }

  void redo() {
    if (canRedo) {
      final command = _redoStack.removeLast();
      command.redo();
      _undoStack.add(command);
    }
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }

  String? get lastUndoDescription =>
      canUndo ? _undoStack.last.description : null;

  String? get lastRedoDescription =>
      canRedo ? _redoStack.last.description : null;
}
