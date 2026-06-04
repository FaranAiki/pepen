import 'package:flutter/material.dart';
import '../models/field_block.dart';
import 'package:flutter_quill/flutter_quill.dart';

class EditorProvider with ChangeNotifier {
  final List<PageModel> _pages = [];
  String? _activeBlockId;

  EditorProvider() {
    _initializeDefaultState();
  }

  List<PageModel> get pages => List.unmodifiable(_pages);
  String? get activeBlockId => _activeBlockId;

  FieldBlock? get activeBlock {
    if (_activeBlockId == null) return _pages.firstOrNull?.blocks.firstOrNull;
    for (var page in _pages) {
      for (var block in page.blocks) {
        if (block.id == _activeBlockId) return block;
      }
    }
    return _pages.firstOrNull?.blocks.firstOrNull;
  }

  void _initializeDefaultState() {
    final firstPage = PageModel();
    final firstBlock = FieldBlock(type: BlockType.text);
    firstPage.blocks.add(firstBlock);
    _pages.add(firstPage);
    _activeBlockId = firstBlock.id;
  }

  void setActiveBlock(String id) {
    if (_activeBlockId != id) {
      _activeBlockId = id;
      Future.microtask(() => notifyListeners());
    }
  }

  void addPage() {
    _pages.add(PageModel());
    notifyListeners();
  }

  void removePage(int index) {
    if (_pages.length > 1) {
      _pages[index].dispose();
      _pages.removeAt(index);
      notifyListeners();
    }
  }

  void addBlockToPage(int pageIndex, {Document? document, BlockType type = BlockType.text, String? assetPath, String? base64Data, String? fileName}) {
    if (pageIndex >= 0 && pageIndex < _pages.length) {
      final block = FieldBlock(
        document: document,
        type: type,
        assetPath: assetPath,
        base64Data: base64Data,
        fileName: fileName,
      );
      _pages[pageIndex].blocks.add(block);
      _activeBlockId = block.id; // Focus the new block
      notifyListeners();
    }
  }

  void removeBlock(String id) {
    for (var page in _pages) {
      final index = page.blocks.indexWhere((b) => b.id == id);
      if (index != -1) {
        if (_activeBlockId == id) _activeBlockId = null;
        page.blocks[index].dispose();
        page.blocks.removeAt(index);
        notifyListeners();
        return;
      }
    }
  }

  void clearAll() {
    for (var page in _pages) {
      page.dispose();
    }
    _pages.clear();
    _initializeDefaultState();
    notifyListeners();
  }

  @override
  void dispose() {
    for (var page in _pages) {
      page.dispose();
    }
    super.dispose();
  }
}
