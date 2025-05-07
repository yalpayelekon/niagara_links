import 'package:flutter/material.dart';

enum DataType { number, string, boolean }

class Block {
  final String id;
  final String name;
  final Offset position;
  final DataType dataType;

  Block({
    required this.id,
    required this.name,
    required this.position,
    required this.dataType,
  });

  Block copyWith({
    Offset? position,
  }) {
    return Block(
      id: id,
      name: name,
      position: position ?? this.position,
      dataType: dataType,
    );
  }
}
