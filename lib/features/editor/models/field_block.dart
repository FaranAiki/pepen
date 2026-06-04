import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:uuid/uuid.dart';

class FieldBlock {
  final String id;
  late QuillController controller;

  FieldBlock({String? id, Document? document})
      : id = id ?? const Uuid().v4() {
    controller = QuillController(
      document: document ?? Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  void dispose() {
    controller.dispose();
  }
}
