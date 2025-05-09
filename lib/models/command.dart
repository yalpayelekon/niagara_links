// lib/home/command.dart

/// Base class for commands that can be undone and redone
abstract class Command {
  /// Execute the command
  void execute();

  /// Undo the command
  void undo();

  /// Redo the command (typically just calls execute)
  void redo() {
    execute();
  }

  /// Description of the command for UI purposes
  String get description;
}
