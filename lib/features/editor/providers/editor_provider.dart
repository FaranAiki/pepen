import 'package:flutter/material.dart';
import '../models/field_block.dart';
import 'package:flutter_quill/flutter_quill.dart';

class EditorProvider with ChangeNotifier {
  final List<FieldBlock> _blocks = [];
  String? _activeBlockId;

  List<FieldBlock> get blocks => List.unmodifiable(_blocks);
  String? get activeBlockId => _activeBlockId;

  FieldBlock? get activeBlock {
    if (_activeBlockId == null) return _blocks.firstOrNull;
    return _blocks.firstWhere((b) => b.id == _activeBlockId, orElse: () => _blocks.first);
  }

  void setActiveBlock(String id) {
    if (_activeBlockId != id) {
      _activeBlockId = id;
      // We only notify when the active block CHANGES, 
      // not when the content INSIDE a block changes.
      notifyListeners();
    }
  }

  void addBlock({Document? document}) {
    _blocks.add(FieldBlock(document: document));
    notifyListeners();
  }

  void removeBlock(String id) {
    if (_blocks.length > 1) {
      final index = _blocks.indexWhere((b) => b.id == id);
      if (index != -1) {
        if (_activeBlockId == id) {
          _activeBlockId = null; // Reset active block if removed
        }
        _blocks[index].dispose();
        _blocks.removeAt(index);
        notifyListeners();
      }
    }
  }

  void clearAll() {
    for (var block in _blocks) {
      block.dispose();
    }
    _blocks.clear();
    addBlock();
    notifyListeners();
  }

  @override
  void dispose() {
    for (var block in _blocks) {
      block.dispose();
    }
    super.dispose();
  }
}
