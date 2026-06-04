import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:uuid/uuid.dart';

enum BlockType { text, image, audio, file }

class FieldBlock {
  final String id;
  final BlockType type;
  late QuillController controller;
  String? assetPath; // For UI display/temp
  String? base64Data; // The actual metadata for .pepn
  String? fileName;

  FieldBlock({
    String? id,
    Document? document,
    this.type = BlockType.text,
    this.assetPath,
    this.base64Data,
    this.fileName,
  }) : id = id ?? const Uuid().v4() {
    controller = QuillController(
      document: document ?? Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  void dispose() {
    controller.dispose();
  }
}

class PageModel {
  final String id;
  final List<FieldBlock> blocks;

  PageModel({String? id, List<FieldBlock>? blocks})
      : id = id ?? const Uuid().v4(),
        blocks = blocks ?? [];

  void dispose() {
    for (var block in blocks) {
      block.dispose();
    }
  }
}
