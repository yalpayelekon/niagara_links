import '../models/command.dart';

class ResizeComponentCommand extends Command {
  final String componentId;
  final double newWidth;
  final double oldWidth;
  final Map<String, double> componentWidths;

  ResizeComponentCommand(
    this.componentId,
    this.newWidth,
    this.oldWidth,
    this.componentWidths,
  );

  @override
  void execute() {
    componentWidths[componentId] = newWidth;
  }

  @override
  void undo() {
    componentWidths[componentId] = oldWidth;
  }

  @override
  String get description => 'Resize $componentId';
}
