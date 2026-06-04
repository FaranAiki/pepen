import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:provider/provider.dart';
import '../models/field_block.dart';
import '../providers/editor_provider.dart';
import '../../../core/app_localizations.dart';

// Custom Embed Builder to handle LaTeX/Formula rendering properly
class LaTeXEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'formula';

  @override
  Widget build(
    BuildContext context,
    EmbedContext usage,
  ) {
    final formula = usage.node.value.data as String;

    return InlineLaTeXWidget(
      // Use the node as key to ensure widget identity matches Quill's document model
      key: ValueKey(usage.node), 
      formula: formula,
      node: usage.node,
      controller: usage.controller,
      textStyle: usage.textStyle,
      readOnly: usage.readOnly,
    );
  }
}

class InlineLaTeXWidget extends StatefulWidget {
  final String formula;
  final Embed node;
  final QuillController controller;
  final TextStyle textStyle;
  final bool readOnly;

  const InlineLaTeXWidget({
    super.key,
    required this.formula,
    required this.node,
    required this.controller,
    required this.textStyle,
    required this.readOnly,
  });

  @override
  State<InlineLaTeXWidget> createState() => _InlineLaTeXWidgetState();
}

class _InlineLaTeXWidgetState extends State<InlineLaTeXWidget> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  bool _isEditing = false;
  late String _currentFormulaValue;

  @override
  void initState() {
    super.initState();
    _currentFormulaValue = widget.formula;
    _textController = TextEditingController(text: widget.formula);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    
    // Newly created embeds (empty) start in edit mode
    _isEditing = widget.formula.isEmpty;
    
    if (_isEditing && !widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _finishEditing();
    }
  }

  @override
  void didUpdateWidget(InlineLaTeXWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If external data changed and we are NOT editing, sync the UI
    if (widget.formula != _currentFormulaValue && !_isEditing) {
      _currentFormulaValue = widget.formula;
      _textController.text = widget.formula;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _finishEditing() {
    if (!mounted || !_isEditing) return;
    
    final newText = _textController.text.trim();
    
    // Only update document if value actually changed
    if (newText != _currentFormulaValue) {
      final offset = widget.node.offset;
      // Safety check: verify node still exists in document
      try {
        widget.controller.replaceText(
          offset, 
          1, 
          BlockEmbed.formula(newText), 
          null
        );
        _currentFormulaValue = newText;
      } catch (e) {
        // Node might have been deleted already (e.g. via backspace)
      }
    }

    setState(() => _isEditing = false);
    
    // Jumps past the embed to continue typing
    widget.controller.updateSelection(
      TextSelection.collapsed(offset: widget.node.offset + 1),
      ChangeSource.local,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // RENDER MODE
    if (widget.readOnly || (!_isEditing && _textController.text.isNotEmpty)) {
      return GestureDetector(
        onTap: widget.readOnly ? null : () {
          setState(() => _isEditing = true);
          _focusNode.requestFocus();
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            // PRO ALIGNMENT: Align using Baseline for inline math symbols
            child: Baseline(
              baseline: 0,
              baselineType: TextBaseline.alphabetic,
              child: Math.tex(
                _textController.text.isEmpty ? '?' : _textController.text,
                textStyle: widget.textStyle.copyWith(fontSize: 16),
                mathStyle: MathStyle.text,
                onErrorFallback: (err) => Text(
                  _textController.text,
                  style: widget.textStyle.copyWith(color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // EDIT MODE
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        border: Border(bottom: BorderSide(color: Colors.blue.withValues(alpha: 0.4), width: 1.0)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 30, maxWidth: 600),
        child: IntrinsicWidth(
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.keyL, control: true): _finishEditing,
              const SingleActivator(LogicalKeyboardKey.enter): _finishEditing,
            },
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              autofocus: true,
              style: widget.textStyle.copyWith(
                fontFamily: 'monospace',
                color: Colors.blue[900],
                fontSize: 14,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                border: InputBorder.none,
                hintText: l10n.translate('math_hint'),
                hintStyle: const TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
              onSubmitted: (_) => _finishEditing(),
              // Handle backspace when empty to delete the embed itself
              onChanged: (val) {
                // Potential logic for deletion handled by Quill if field is empty and backspace pressed?
                // For now, standard behavior.
              },
            ),
          ),
        ),
      ),
    );
  }
}

class BlockFieldWidget extends StatefulWidget {
  final FieldBlock block;
  final VoidCallback onRemove;
  final bool showRemove;
  final bool isFirst;

  const BlockFieldWidget({
    super.key,
    required this.block,
    required this.onRemove,
    this.showRemove = true,
    this.isFirst = false,
  });

  @override
  State<BlockFieldWidget> createState() => _BlockFieldWidgetState();
}

class _BlockFieldWidgetState extends State<BlockFieldWidget> {
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _scrollController = ScrollController();
    
    if (widget.isFirst) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focusNode.hasFocus) _focusNode.requestFocus();
      });
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      Provider.of<EditorProvider>(context, listen: false).setActiveBlock(widget.block.id);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleLatexShortcut() {
    final controller = widget.block.controller;
    final index = controller.selection.baseOffset;
    
    final segmentNode = controller.document.querySegmentLeafNode(index);
    final leaf = segmentNode.leaf;
    
    if (leaf != null && leaf is Embed && leaf.value.type == 'formula') {
      controller.updateSelection(
        TextSelection.collapsed(offset: index + 1),
        ChangeSource.local,
      );
      return;
    }

    controller.document.insert(index, BlockEmbed.formula(''));
    controller.updateSelection(
      TextSelection.collapsed(offset: index),
      ChangeSource.local,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyL, control: true): _handleLatexShortcut,
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.isFirst)
                AnimatedOpacity(
                  opacity: _isHovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(height: 1, width: 20, color: Colors.blue.withValues(alpha: 0.2)),
                        const SizedBox(width: 8),
                        Text(
                          _getTypeLabel(widget.block.type, l10n),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.withValues(alpha: 0.4),
                          ),
                        ),
                        const Spacer(),
                        if (widget.showRemove)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                            onPressed: widget.onRemove,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Remove Section',
                          ),
                      ],
                    ),
                  ),
                ),
              _buildBlockContent(),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(BlockType type, AppLocalizations l10n) {
    switch (type) {
      case BlockType.text: return l10n.translate('new_section');
      case BlockType.image: return 'Image Section';
      case BlockType.audio: return 'Audio Section';
      case BlockType.file: return 'File Section';
    }
  }

  Widget _buildBlockContent() {
    switch (widget.block.type) {
      case BlockType.text:
        return QuillEditor(
          controller: widget.block.controller,
          scrollController: _scrollController,
          focusNode: _focusNode,
          config: QuillEditorConfig(
            autoFocus: widget.isFirst,
            expands: false,
            padding: EdgeInsets.zero,
            placeholder: widget.isFirst ? 'Type here (Ctrl+L for LaTeX)...' : '',
            embedBuilders: [
              LaTeXEmbedBuilder(),
              ...FlutterQuillEmbeds.editorBuilders(),
            ],
            customStyles: DefaultStyles(
              paragraph: DefaultTextBlockStyle(
                const TextStyle(color: Colors.black, fontSize: 16, height: 1.5),
                const HorizontalSpacing(0, 0),
                const VerticalSpacing(0, 0),
                const VerticalSpacing(0, 0),
                null,
              ),
            ),
          ),
        );
      case BlockType.image:
        if (widget.block.base64Data != null) {
          return Image.memory(base64Decode(widget.block.base64Data!), fit: BoxFit.contain);
        } else if (widget.block.assetPath != null) {
          return Image.file(File(widget.block.assetPath!), fit: BoxFit.contain);
        }
        return const Placeholder(child: Text('No Image Selected'));
      case BlockType.audio:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.audiotrack, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.block.fileName ?? 'Unknown Audio')),
            ],
          ),
        );
      case BlockType.file:
        return ListTile(
          leading: const Icon(Icons.insert_drive_file, color: Colors.orange),
          title: Text(widget.block.fileName ?? 'Unknown File'),
          tileColor: Colors.orange.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
    }
  }
}
