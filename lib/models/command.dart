abstract class Command {
  void execute();

  void undo();

  void redo() {
    execute();
  }

  String get description;
}
