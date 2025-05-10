import 'package:flutter/material.dart';
import 'package:niagara_links/models/component.dart';
import 'operations.dart';

class ContextMenus {
  static void showCanvasContextMenu(
    BuildContext context,
    Offset globalPosition,
    Offset canvasPosition,
    Function(Offset) onAddComponent,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(globalPosition, globalPosition),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(
          value: 'add-component',
          child: Row(
            children: [
              Icon(Icons.add_box, size: 18),
              SizedBox(width: 8),
              Text('Add Component'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'paste',
          child: Row(
            children: [
              Icon(Icons.paste, size: 18),
              SizedBox(width: 8),
              Text('Paste'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'select-all',
          child: Row(
            children: [
              Icon(Icons.select_all, size: 18),
              SizedBox(width: 8),
              Text('Select All'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'clear-canvas',
          child: Row(
            children: [
              Icon(Icons.clear, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Clear Canvas', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;

      switch (value) {
        case 'add-component':
          onAddComponent(canvasPosition);
          break;
        case 'paste':
          // Placeholder for paste functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paste functionality coming soon'),
              duration: Duration(seconds: 1),
            ),
          );
          break;
        case 'select-all':
          // Placeholder for select all functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Select all functionality coming soon'),
              duration: Duration(seconds: 1),
            ),
          );
          break;
        case 'clear-canvas':
          // Placeholder for clear canvas functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clear canvas functionality coming soon'),
              duration: Duration(seconds: 1),
            ),
          );
          break;
      }
    });
  }

  static void showComponentContextMenu(
    BuildContext context,
    Offset position,
    Component component,
    ComponentOperations operations,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy, size: 18),
              SizedBox(width: 8),
              Text('Copy'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;

      switch (value) {
        case 'copy':
          operations.handleCopyComponent(component);
          break;
        case 'edit':
          operations.handleEditComponent(context, component);
          break;
        case 'delete':
          operations.handleDeleteComponent(component);
          break;
      }
    });
  }
}
