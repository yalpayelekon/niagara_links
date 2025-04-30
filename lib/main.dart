import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/block.dart';
import 'providers/block_provider.dart';
import 'providers/link_provider.dart';
import 'widgets/block_widget.dart';
import 'package:uuid/uuid.dart';
import 'models/link.dart';
import 'widgets/link_painter.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drag and Drop Editor',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const EditorPage(),
    );
  }
}

class EditorPage extends ConsumerStatefulWidget {
  const EditorPage({super.key});

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  String? draggingFromBlockId;
  Offset? draggingFromPosition;

  @override
  Widget build(BuildContext context) {
    final blocks = ref.watch(blockListProvider);
    final blockNotifier = ref.read(blockListProvider.notifier);
    final links = ref.watch(linkListProvider);
    final linkNotifier = ref.read(linkListProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Niagara Style Editor')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final id = const Uuid().v4();
          blockNotifier.addBlock(
            Block(
              id: id,
              name: 'NumericWritable',
              position: const Offset(100, 100),
              dataType: DataType.number,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          // Connections painter
          CustomPaint(
            size: Size.infinite,
            painter: LinkPainter(blocks: blocks, links: links),
          ),

          // Blocks
          for (final block in blocks)
            BlockWidget(
              block: block,
              onPositionChanged: (newPos) {
                blockNotifier.updateBlockPosition(block.id, newPos);
              },
              onOutTap: (blockId, globalPosition) {
                setState(() {
                  draggingFromBlockId = blockId;
                  draggingFromPosition = globalPosition;
                });
              },
              onInTap: (blockId) {
                if (draggingFromBlockId != null &&
                    draggingFromBlockId != blockId) {
                  linkNotifier.addLink(
                    Link(
                      id: const Uuid().v4(),
                      fromBlockId: draggingFromBlockId!,
                      fromPortId: 'out',
                      toBlockId: blockId,
                      toPortId: 'in',
                    ),
                  );
                  setState(() {
                    draggingFromBlockId = null;
                    draggingFromPosition = null;
                  });
                }
              },
            ),
        ],
      ),
    );
  }
}
